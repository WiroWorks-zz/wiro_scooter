local scootersInfo = {}
local blips = {}

local kiralandi = false
local kiralananplate = nil
local kEngineHealth, kBodyHealth

local para

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("wiro_scooter:setIsScootersLoaded")
AddEventHandler("wiro_scooter:setIsScootersLoaded", function(scooters)
    scootersInfo = scooters
    local scooterhash = GetHashKey(Config.vehicleModel)
    RequestModel(scooterhash)
    local isLoaded = HasModelLoaded(scooterhash)
    while isLoaded == false do
        Citizen.Wait(100)
        isLoaded = HasModelLoaded(scooterhash)
    end
    local vehicle
    for k,v in pairs(scooters) do 
        local cord = vector3(v.coords.x, v.coords.y, v.coords.z)
        vehicle = CreateVehicle(scooterhash, cord, v.coords.h, 1, 0)
        SetVehicleNumberPlateText(vehicle, v.plate)
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleBodyHealth(vehicle, v.bodyHealth)
        SetVehicleEngineHealth(vehicle, v.engineHealth)
    end
    TriggerServerEvent("wiro_scooter:allLoaded")
end)

RegisterNetEvent("wiro_scooter:catchInfo")
AddEventHandler("wiro_scooter:catchInfo", function(scooters)
    scootersInfo = scooters
end)

RegisterCommand(Config.command, function()
    -- MAIN WİRO
    SetDisplay(true)
    -- MAIN WİRO
end)

function SetDisplay(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
    })
end

function BlipOlustur()
    TriggerServerEvent("wiro_scooter:requestInfoFromServer")
    Citizen.Wait(1000)
    for k,v in pairs(scootersInfo) do
        xblip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite(xblip, Config.blipId)
        SetBlipAsShortRange(xblip, true)
        BeginTextCommandSetBlipName("STRING")
        SetBlipColour(xblip, 0)
        AddTextComponentString("wiro martı")
        EndTextCommandSetBlipName(xblip)
        table.insert(blips, xblip)
    end
end

function BlipSil()
    for k,v in pairs(blips) do
        RemoveBlip(v)
    end
end

-- Bu function utku#9999'dan alınmıştır / This function is taken from utku#9999
local DrawTextFormat = function(x, y, text, entry)
    AddTextEntry(entry, text)
    SetTextFont(0) SetTextProportional(0) SetTextScale(0.62, 0.62) SetTextDropShadow(2, 2, 0, 0, 255) SetTextEdge(1, 0, 0, 0, 255) SetTextColour(50, 255, 50, 255)
    BeginTextCommandDisplayText(entry)
    DrawText(x, y)
end
-- Bu function utku#9999'dan alınmıştır / This function is taken from utku#9999

function yazyegen()
    Citizen.CreateThread(function()
        while kiralandi do
            DrawTextFormat(0.71, 0.70, tostring(para) ..".0$", "rentAmount")
            Citizen.Wait(1)
        end
    end)
end

function KiraParaCek()
    TriggerServerEvent("wiro_scooter:takeMoneyFromBank", Config.startMoney)
    para = Config.startMoney
    yazyegen()
    Citizen.CreateThread(function()
        while kiralandi do
            Citizen.Wait(Config.moneyTime)
            if kiralandi then
                TriggerServerEvent("wiro_scooter:takeMoneyFromBank", Config.moneyRise)
                para = para + Config.moneyRise
            end
        end
    end)
end

RegisterNUICallback('exit', function()
    SetDisplay(false)
end)

RegisterNUICallback('kirala', function()
    if not kiralandi then
        local oyuncuCoord = GetEntityCoords(PlayerPedId(), false)
        local closestVehicle = ESX.Game.GetClosestVehicle(oyuncuCoord)
        local plate = tostring(GetVehicleNumberPlateText(closestVehicle))
        for k,v in pairs(Config.plates) do
            xplate = "  " .. v .. "  "
            if xplate == plate then
                TriggerServerEvent("wiro_scooter:requestInfoFromServer")
                Citizen.Wait(1000)
                for k2,v2 in pairs(scootersInfo) do
                    if v2.plate == v then
                        if v2.canRent then
                            kiralananplate = v
                            SetVehicleDoorsLocked(closestVehicle, 1)
                            TriggerServerEvent("wiro_scooter:giveInfoRent", v, false)
                            TriggerEvent('wiro_notify:show', "success", Config.rentedMsg, 1500)
                            kiralandi = true
                            kEngineHealth = tonumber(GetVehicleBodyHealth(closestVehicle))
                            kBodyHealth = tonumber(GetVehicleEngineHealth(closestVehicle))
                            KiraParaCek()
                        else
                            TriggerEvent('wiro_notify:show', "error", Config.alredyRentedMsg, 3000)
                        end
                    end
                end
            end
        end
    else
        TriggerEvent('wiro_notify:show', "error", Config.youHaveARentedScooter, 3000)
    end
end)

RegisterNUICallback('kirabitir', function(data)
    if kiralandi then
        local closestVehicle = ESX.Game.GetClosestVehicle(oyuncuCoord)
        local plate = tostring(GetVehicleNumberPlateText(closestVehicle))
        if plate == "  ".. kiralananplate.."  " then
            if 0 == GetPedInVehicleSeat(closestVehicle, -1) then
                kiralandi = false
                TriggerEvent('wiro_notify:show', "success", Config.rentStoped, 1500)
                SetVehicleDoorsLocked(closestVehicle, 2)
                x = GetEntityCoords(closestVehicle)
                y = {x = x.x, y= x.y, z = x.z, h = GetEntityHeading(closestVehicle)}
                para = 0
                if (kEngineHealth - tonumber(GetVehicleEngineHealth(closestVehicle)) ) > 20.0 then
                    TriggerServerEvent("wiro_scooter:takeMoneyFromBank", Config.crashMoney)
                    TriggerServerEvent("wiro_scooter:giveInfoRent", kiralananplate, true, y, GetVehicleBodyHealth(closestVehicle), GetVehicleEngineHealth(closestVehicle))
                else
                    TriggerServerEvent("wiro_scooter:giveInfoRent", kiralananplate, true, y, kBodyHealth, kEngineHealth)
                end
            else
                TriggerEvent('wiro_notify:show', "error", Config.stillUsing, 3000)
            end
        else
            TriggerEvent('wiro_notify:show', "inform", Config.getCloser, 3000)
        end
    else

    end
end)

RegisterNUICallback('blip', function(data)
    if data.status then
        BlipOlustur()
    else
        BlipSil()
    end
end)