-- Variables
local QBCore = exports["qb-core"]:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local Initialized = false
local vehicleMenu = {}
local ClosestVehicle = 1
local zones = {}
local insideShop, tempShop = nil, nil

-- Handlers
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    local citizenid = PlayerData.citizenid
    TriggerServerEvent('qb-vehiclerental:server:addPlayer', citizenid)
    TriggerServerEvent('qb-vehiclerental:server:checkRental')
    if not Initialized then Init() end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    local citizenid = PlayerData.citizenid
    TriggerServerEvent('qb-vehiclerental:server:removePlayer', citizenid)
    PlayerData = {}
end)

-- Static Headers
local vehHeaderMenu = {
    {
        header = Lang:t('menus.vehHeader_header'),
        txt = Lang:t('menus.vehHeader_txt'),
        icon = "fa-solid fa-car",
        params = {
            event = 'qb-vehiclerental:client:showVehOptions'
        }
    }
}

-- Functions
local function comma_value(amount)
    local formatted = amount
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

local function getVehName()
    return QBCore.Shared.Vehicles[Config.Shops[insideShop]["RentalVehicles"][ClosestVehicle].chosenVehicle]["name"]
end

local function getVehBrand()
    return QBCore.Shared.Vehicles[Config.Shops[insideShop]["RentalVehicles"][ClosestVehicle].chosenVehicle]['brand']
end

local function getVehPrice()
    return comma_value(QBCore.Shared.Vehicles[Config.Shops[insideShop]["RentalVehicles"][ClosestVehicle].chosenVehicle]["price"])
end

local function setClosestRentalVehicle()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
    local closestShop = insideShop
    for id in pairs(Config.Shops[closestShop]["RentalVehicles"]) do
        local dist2 = #(pos - vector3(Config.Shops[closestShop]["RentalVehicles"][id].coords.x, Config.Shops[closestShop]["RentalVehicles"][id].coords.y, Config.Shops[closestShop]["RentalVehicles"][id].coords.z))
        if current then
            if dist2 < dist then
                current = id
                dist = dist2
            end
        else
            dist = dist2
            current = id
        end
    end
    if current ~= ClosestVehicle then
        ClosestVehicle = current
    end
end

local function createVehZones(shopName, entity)
    if not Config.UsingTarget then
        for i = 1, #Config.Shops[shopName]['RentalVehicles'] do
            zones[#zones + 1] = BoxZone:Create(
                vector3(Config.Shops[shopName]['RentalVehicles'][i]['coords'].x,
                    Config.Shops[shopName]['RentalVehicles'][i]['coords'].y,
                    Config.Shops[shopName]['RentalVehicles'][i]['coords'].z),
                Config.Shops[shopName]['Zone']['size'],
                Config.Shops[shopName]['Zone']['size'],
                {
                    name = "box_zone_" .. shopName .. "_" .. i,
                    minZ = Config.Shops[shopName]['Zone']['minZ'],
                    maxZ = Config.Shops[shopName]['Zone']['maxZ'],
                    debugPoly = true,
                })
        end
        local combo = ComboZone:Create(zones, {name = "vehCombo", debugPoly = true})
        combo:onPlayerInOut(function(isPointInside)
            if isPointInside then
                exports['qb-menu']:showHeader(vehHeaderMenu)
            else
                exports['qb-menu']:closeMenu()
            end
        end)
    else
        exports['qb-target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    event = "qb-vehiclerental:client:showVehOptions",
                    icon = "fas fa-car",
                    label = Lang:t('general.vehinteraction'),
                    canInteract = function()
                        local closestShop = insideShop
                        return closestShop
                    end
                },
            },
            distance = 3.0
        })
    end
end

-- Zones
function createRentalShop(shopShape, name)
    local zone = PolyZone:Create(shopShape, {
        name = name,
        minZ = shopShape.minZ,
        maxZ = shopShape.maxZ,
        debugGrid = false
    })

    zone:onPlayerInOut(function(isPointInside)
        if isPointInside then
            insideShop = name
            CreateThread(function()
                while insideShop do
                    setClosestRentalVehicle()
                    vehicleMenu = {
                        {
                            isMenuHeader = true,
                            icon = "fa-solid fa-circle-info",
                            header = getVehBrand():upper() .. ' ' .. getVehName():upper(),
                        },
                        {
                            header = Lang:t('menus.rent_header'),
                            txt = Lang:t('menus.rent_txt'),
                            icon = "fa-solid fa-hand-holding-dollar",
                            params = {
                                event = 'qb-vehiclerental:client:openRent',
                                args = {
                                    price = getVehPrice(),
                                    rentVehicle = Config.Shops[insideShop]["RentalVehicles"][ClosestVehicle].chosenVehicle
                                }
                            },
                        },
                        {
                            header = Lang:t('menus.rented_header'),
                            txt = Lang:t('menus.rented_txt'),
                            icon = "fa-solid fa-user-ninja",
                            params = {
                                event = 'qb-vehiclerental:client:getRentedVehicles'
                            }
                        },
                        {
                            header = Lang:t('menus.swap_header'),
                            txt = Lang:t('menus.swap_txt'),
                            icon = "fa-solid fa-arrow-rotate-left",
                            params = {
                                event = 'qb-vehiclerental:client:vehCategories',
                            }
                        },
                    }
                    Wait(1000)
                end
            end)
        else
            insideShop = nil
            ClosestVehicle = 1
        end
    end)
end

function Init()
    Initialized = true
    CreateThread(function()
        for name, shop in pairs(Config.Shops) do
            createRentalShop(shop['Zone']['Shape'], name)
        end
    end)

    CreateThread(function()
        for k in pairs(Config.Shops) do
            for i = 1, #Config.Shops[k]['RentalVehicles'] do
                local model = GetHashKey(Config.Shops[k]["RentalVehicles"][i].defaultVehicle)
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
                local veh = CreateVehicle(model, Config.Shops[k]["RentalVehicles"][i].coords.x, Config.Shops[k]["RentalVehicles"][i].coords.y, Config.Shops[k]["RentalVehicles"][i].coords.z, false, false)
                SetModelAsNoLongerNeeded(model)
                SetVehicleOnGroundProperly(veh)
                SetEntityInvincible(veh, true)
                SetVehicleDirtLevel(veh, 0.0)
                SetVehicleDoorsLocked(veh, 3)
                SetEntityHeading(veh, Config.Shops[k]["RentalVehicles"][i].coords.w)
                FreezeEntityPosition(veh, true)
                SetVehicleNumberPlateText(veh, 'RENT ME')
                if Config.UsingTarget then createVehZones(k, veh) end
            end
            if not Config.UsingTarget then createVehZones(k) end
        end
    end)
end

-- Events
RegisterNetEvent('qb-vehiclerental:client:homeMenu', function()
    exports['qb-menu']:openMenu(vehicleMenu)
end)

RegisterNetEvent('qb-vehiclerental:client:showVehOptions', function()
    exports['qb-menu']:openMenu(vehicleMenu)
end)

RegisterNetEvent('qb-vehiclerental:client:vehCategories', function()
	local catmenu = {}
    local categoryMenu = {
        {
            header = Lang:t('menus.goback_header'),
            icon = "fa-solid fa-angle-left",
            params = {
                event = 'qb-vehiclerental:client:homeMenu'
            }
        }
    }
	for k, v in pairs(QBCore.Shared.Vehicles) do
        if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
            for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                if shop == insideShop then
                    catmenu[v.category] = v.category
                end
            end
        elseif QBCore.Shared.Vehicles[k]["shop"] == insideShop then
                catmenu[v.category] = v.category
        end
    end
    for k, v in pairs(catmenu) do
        categoryMenu[#categoryMenu + 1] = {
            header = v,
            icon = "fa-solid fa-circle",
            params = {
                event = 'qb-vehiclerental:client:openVehCats',
                args = {
                    catName = k
                }
            }
        }
    end
    exports['qb-menu']:openMenu(categoryMenu)
end)

RegisterNetEvent('qb-vehiclerental:client:openVehCats', function(data)
    local vehMenu = {
        {
            header = Lang:t('menus.goback_header'),
            icon = "fa-solid fa-angle-left",
            params = {
                event = 'qb-vehiclerental:client:vehCategories'
            }
        }
    }
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]["category"] == data.catName then
            if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
                for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                    if shop == insideShop then
                        vehMenu[#vehMenu + 1] = {
                            header = v.name,
                            txt = Lang:t('menus.veh_price') .. v.price,
                            icon = "fa-solid fa-car-side",
                            params = {
                                isServer = true,
                                event = 'qb-vehiclerental:server:swapVehicle',
                                args = {
                                    toVehicle = v.model,
                                    ClosestVehicle = ClosestVehicle,
                                    ClosestShop = insideShop
                                }
                            }
                        }
                    end
                end
            elseif QBCore.Shared.Vehicles[k]["shop"] == insideShop then
                vehMenu[#vehMenu + 1] = {
                    header = v.name,
                    txt = Lang:t('menus.veh_price') .. v.price,
                    icon = "fa-solid fa-car-side",
                    params = {
                        isServer = true,
                        event = 'qb-vehiclerental:server:swapVehicle',
                        args = {
                            toVehicle = v.model,
                            ClosestVehicle = ClosestVehicle,
                            ClosestShop = insideShop
                        }
                    }
                }
            end
        end
    end
    exports['qb-menu']:openMenu(vehMenu)
end)

RegisterNetEvent('qb-vehiclerental:client:openRent', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = getVehBrand():upper() .. ' ' .. data.rentVehicle:upper() .. ' - $' .. data.price,
        submitText = Lang:t('menus.submit_text'),
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'rentalTime',
                text = Lang:t('menus.rentalsubmit_rentalTime') .. Config.MinimumRent
            },
        }
    })
    if dialog then
        if not dialog.rentalTime then return end
        TriggerServerEvent('qb-vehiclerental:server:rentVehicle', dialog.rentalTime, data.rentVehicle)
    end
end)

RegisterNetEvent('qb-vehiclerental:client:swapVehicle', function(data)
    local shopName = data.ClosestShop
    if Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].chosenVehicle ~= data.toVehicle then
        local closestVehicle, closestDistance = QBCore.Functions.GetClosestVehicle(vector3(Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.x, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.y, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.z))
        if closestVehicle == 0 then return end
        if closestDistance < 5 then DeleteEntity(closestVehicle) end
        while DoesEntityExist(closestVehicle) do
            Wait(50)
        end
        Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].chosenVehicle = data.toVehicle
        local model = GetHashKey(data.toVehicle)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(50)
        end
        local veh = CreateVehicle(model, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.x, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.y, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.z, false, false)
        while not DoesEntityExist(veh) do
            Wait(50)
        end
        SetModelAsNoLongerNeeded(model)
        SetVehicleOnGroundProperly(veh)
        SetEntityInvincible(veh, true)
        SetEntityHeading(veh, Config.Shops[shopName]["RentalVehicles"][data.ClosestVehicle].coords.w)
        SetVehicleDoorsLocked(veh, 3)
        FreezeEntityPosition(veh, true)
        SetVehicleNumberPlateText(veh, 'RENT ME')
        if Config.UsingTarget then createVehZones(shopName, veh) end
    end
end)

RegisterNetEvent('qb-vehiclerental:client:getRentedVehicles', function()
    QBCore.Functions.TriggerCallback('qb-vehiclerental:server:getRentedVehicles', function(vehicles)
        local rentedVehicles = {
            {
                header = Lang:t('menus.goback_header'),
                icon = "fa-solid fa-angle-left",
                params = {
                    event = 'qb-vehiclerental:client:homeMenu'
                }
            },
        }
        for _, v in pairs(vehicles) do
                local name = QBCore.Shared.Vehicles[v.vehicle]["name"]
                local plate = v.plate:upper()
                rentedVehicles[#rentedVehicles + 1] = {
                    header = name,
                    txt = Lang:t('menus.veh_platetxt') .. plate,
                    icon = "fa-solid fa-car-side",
                    params = {
                        event = 'qb-vehiclerental:client:getVehicleRentalTime',
                        args = {
                            vehiclePlate = plate,
                            rentalTime = v.rentaltime
                        }
                    }
                }
        end
        if #rentedVehicles > 0 then
            exports['qb-menu']:openMenu(rentedVehicles)
        else
            QBCore.Functions.Notify(Lang:t('error.norented'), 'error', 7500)
        end
    end)
end)

RegisterNetEvent('qb-vehiclerental:client:getVehicleRentalTime', function(data)
    local rentTime = math.floor(tonumber(data.rentalTime / 60) * 100)/100
    local vehRental = {
        {
            header = Lang:t('menus.goback_header'),
            params = {
                event = 'qb-vehiclerental:client:getRentedVehicles'
            }
        },
        {
            isMenuHeader = true,
            icon = "fas fa-clock",
            header = Lang:t('menus.veh_rental_time'),
            txt = Lang:t('menus.rentedTime_txt') .. rentTime
        },
    }
    exports['qb-menu']:openMenu(vehRental)
end)

RegisterNetEvent('qb-vehiclerental:client:rentVehicle', function(vehicle, plate)
    tempShop = insideShop -- temp hacky way of setting the shop because it changes after the callback has returned since you are outside the zone
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        exports['LegacyFuel']:SetFuel(veh, 100)
        SetVehicleNumberPlateText(veh, plate)
        SetEntityHeading(veh, Config.Shops[tempShop]["VehicleSpawn"].w)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        TriggerServerEvent("qb-vehicletuning:server:SaveVehicleProps", QBCore.Functions.GetVehicleProperties(veh))
    end, vehicle, Config.Shops[tempShop]["VehicleSpawn"], true)
end)

-- Threads
CreateThread(function()
    for k, v in pairs(Config.Shops) do
        if v.showBlip then
            local Dealer = AddBlipForCoord(Config.Shops[k]["Location"])
            SetBlipSprite(Dealer, Config.Shops[k]["blipSprite"])
            SetBlipDisplay(Dealer, 4)
            SetBlipScale(Dealer, 0.70)
            SetBlipAsShortRange(Dealer, true)
            SetBlipColour(Dealer, Config.Shops[k]["blipColor"])
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Shops[k]["ShopLabel"])
            EndTextCommandSetBlipName(Dealer)
        end
    end
end)