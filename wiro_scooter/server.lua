local scooters = {}

local isScootersLoaded = false

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function TableRefresh()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "scooters.json")
    scooters = json.decode(loadFile) 
end

function TableLastSave() 
  for k,v in pairs(scooters) do 
    v.canRent = true
  end
  SaveResourceFile(GetCurrentResourceName(), "scooters.json", json.encode(scooters), -1)
end

function TableSave() 
  SaveResourceFile(GetCurrentResourceName(), "scooters.json", json.encode(scooters), -1)
end

AddEventHandler('onResourceStop', function(resourceName)
  TableLastSave() 
end)

AddEventHandler('onResourceStart', function(resourceName)
  TableRefresh()
  print("^4wiro_scooter ^2baslatildi^0, ^8Wiro iyi gunler diler.^0")
end)

AddEventHandler('es:playerLoaded',function(source)
  if isScootersLoaded == false then
    local waiting = true
    _source = source
    isScootersLoaded = true
    Citizen.Wait(15000)
    TriggerClientEvent("wiro_scooter:setIsScootersLoaded", _source, scooters)
    Citizen.Wait(30000)
    if waiting then
      isScootersLoaded = false
    end
  end
end)

RegisterServerEvent('wiro_scooter:allLoaded')
AddEventHandler('wiro_scooter:allLoaded', function()
  waiting = false
end)

RegisterServerEvent('wiro_scooter:requestInfoFromServer')
AddEventHandler('wiro_scooter:requestInfoFromServer', function()
  _source = source
  Citizen.Wait(500)
  TriggerClientEvent("wiro_scooter:catchInfo", _source, scooters)
end)

RegisterServerEvent('wiro_scooter:giveInfoRent')
AddEventHandler('wiro_scooter:giveInfoRent', function(plate, booll, cords, bHealth, eHealth)
  for k,v in pairs(scooters) do
    if v.plate == plate then
      v.canRent = booll
      if cords ~= nil then
        v.coords = cords
        v.bodyHealth = bHealth
        v.engineHealth = eHealth
      end
      TableSave()
    end
  end
end)

RegisterServerEvent('wiro_scooter:takeMoneyFromBank')
AddEventHandler('wiro_scooter:takeMoneyFromBank', function(amount)
	_source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
  amount = tonumber(Config.moneyRise)
	xPlayer.removeAccountMoney('bank', amount)
end)