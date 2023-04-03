-- Variables
local QBCore = exports['qb-core']:GetCoreObject()
local renttimer = {}

-- Handlers
-- Store game time for player when they load
RegisterNetEvent('qb-vehiclerental:server:addPlayer', function(citizenid)
    renttimer[citizenid] = os.time()
end)

-- Deduct stored game time from player on logout
RegisterNetEvent('qb-vehiclerental:server:removePlayer', function(citizenid)
    if renttimer[citizenid] then
        local playTime = renttimer[citizenid]
        local renttime = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {citizenid})
        for _, v in pairs(renttime) do
            if v.rentaltime >= 1 then
                local newTime = (v.rentaltime-((os.time()-playTime)/60))
                if newTime < 0 then newTime = 0 end
                MySQL.update('UPDATE player_vehicles SET rentaltime = ? WHERE plate = ?', {math.ceil(newTime), v.plate})
            end
        end
    end
    renttimer[citizenid] = nil
end)

-- Deduct stored game time from player on quit because we can't get citizenid
AddEventHandler('playerDropped', function()
    local src = source
    local license
    for _, v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
        end
    end
    if license then
        local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE license = ?', {license})
        if vehicles then
            for _, v in pairs(vehicles) do
                local playTime = renttimer[v.citizenid]
                if v.rentaltime >= 1 and playTime then
                    local newTime = (v.rentaltime-((os.time()-playTime)/60))
                    if newTime < 0 then newTime = 0 end
                    MySQL.update('UPDATE player_vehicles SET rentaltime = ? WHERE plate = ?', {math.ceil(newTime), v.plate})
                end
            end
            if vehicles[1] and renttimer[vehicles[1].citizenid] then renttimer[vehicles[1].citizenid] = nil end
        end
    end
end)

-- Functions
local function round(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

local function calculateRental(vehiclePrice, rentalTime)
    local rentalAmount = rentalTime / 24 * vehiclePrice * Config.RentalPrice
    return round(rentalAmount)
end

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

-- Sync vehicle for other players
RegisterNetEvent('qb-vehiclerental:server:swapVehicle', function(data)
    local src = source
    TriggerClientEvent('qb-vehiclerental:client:swapVehicle', -1, data)
    Wait(1500)-- let new car spawn
    TriggerClientEvent('qb-vehiclerental:client:homeMenu', src)-- reopen main menu
end)

-- Callbacks
QBCore.Functions.CreateCallback('qb-vehiclerental:server:getRentedVehicles', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?  AND rentaltime >= 1', {player.PlayerData.citizenid})
        if vehicles[1] then
            cb(vehicles)
        end
    end
end)

-- Events
RegisterNetEvent('qb-vehiclerental:server:checkRental', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local query = 'SELECT * FROM player_vehicles WHERE citizenid = ? AND rentaltime < 1'
    local result = MySQL.query.await(query, {player.PlayerData.citizenid})
    if result[1] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('general.rentaltimeleft', {time = Config.RentalWarning}))
        Wait(Config.RentalWarning * 60000)
        local vehicles = MySQL.query.await(query, {player.PlayerData.citizenid})
        for _, v in pairs(vehicles) do
            local plate = v.plate
            MySQL.query('DELETE FROM player_vehicles WHERE plate = @plate', {['@plate'] = plate})
            --MySQL.update('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', {'REPO-'..v.citizenid, plate}) -- Use this if you don't want them to be deleted
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.repossessed', {plate = plate}), 'error')
        end
    end
end)

-- rent public vehicle
RegisterNetEvent('qb-vehiclerental:server:rentVehicle', function(rentTime, vehicle)
    local src = source
    rentTime = tonumber(rentTime)
    local pData = QBCore.Functions.GetPlayer(src)
    local cid = pData.PlayerData.citizenid
    local cash = pData.PlayerData.money['cash']
    local bank = pData.PlayerData.money['bank']
    local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
    local timer = (rentTime * 60)
    local plate = GeneratePlate()
    local rentAmount = calculateRental(vehiclePrice, rentTime)
    if cash >= rentAmount then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, rentaltime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.rented'), 'success')
        TriggerClientEvent('qb-vehiclerental:client:rentVehicle', src, vehicle, plate)
        pData.Functions.RemoveMoney('cash', rentAmount, 'vehicle-rented')
    elseif bank >= rentAmount then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, rentaltime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            'pillboxgarage',
            0,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.rented'), 'success')
        TriggerClientEvent('qb-vehiclerental:client:rentVehicle', src, vehicle, plate)
        pData.Functions.RemoveMoney('bank', rentAmount, 'vehicle-rented')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    end
end)