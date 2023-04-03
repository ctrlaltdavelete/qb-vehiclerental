Config = {}
Config.UsingTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
Config.MinimumRent = 24 -- minimum time in hours that player can rent a vehicle
Config.RentalWarning = 10 -- time in minutes that player has left on their rental
Config.RentalPrice = 0.10 -- 10% of Vehicle Price

Config.Shops = {
    ['airport'] = {
        ['Zone'] = {
            ['Shape'] = {--polygon that surrounds the shop
                vector2(-895.95141601562, -2341.1140136719),
                vector2(-910.15228271484, -2332.8894042969),
                vector2(-901.76440429688, -2317.8776855469),
                vector2(-886.45288085938, -2326.728515625)
            },
            ['minZ'] = 5.5, -- min height of the shop zone
            ['maxZ'] = 7, -- max height of the shop zone
            ['size'] = 2.75 -- size of the vehicles zones
        },
        ['ShopLabel'] = 'Airport Vehicle Rental', -- Blip name
        ['showBlip'] = true, -- true or false
        ['blipSprite'] = 326, -- Blip sprite
        ['blipColor'] = 47, -- Blip color
        ['Location'] = vector3(-896.53, -2326.48, 6.71), -- Blip Location
        ['VehicleSpawn'] = vector4(-891.66, -2317.01, 5.7, 321.97), -- Spawn location when vehicle is rented
        ['RentalVehicles'] = {
            [1] = {
                coords = vector4(-894.17, -2332.28, 5.7, 238.13), -- where the vehicle will spawn on display
                defaultVehicle = 'bison', -- Default display vehicle
                chosenVehicle = 'bison', -- Same as default but is dynamically changed when swapping vehicles
            },
            [2] = {
                coords = vector4(-892.2, -2329.21, 5.7, 239.9), -- where the vehicle will spawn on display
                defaultVehicle = 'speedo', -- Default display vehicle
                chosenVehicle = 'speedo', -- Same as default but is dynamically changed when swapping vehicles
            },
        },
    },
}