RegisterNUICallback("close", function(data, cb)
  ClosePhone()
  cb("OK")
end)

RegisterNUICallback('setSetting', function(data, cb)
  SetResourceKvp(tostring(data.key), tostring(data.value))
  Wait(150)
  Phone.API.TriggerServerEvent('phone:syncSettings', GetSettings())
  cb("OK")
end)

RegisterNUICallback("setupFinished", function(data, cb)
  Phone.Setup = true
  cb("OK")
end)

RegisterNUICallback("setup:createAccount", function(data, cb)
  local status = Phone.API.TriggerServerEvent("phone:createAccount", data)

  if not status then
    Phone.SetupNeeded = false
  end

  cb({ status = status })
end)

RegisterNUICallback("setup:login", function(data, cb)
  local status = Phone.API.TriggerServerEvent("phone:login", data)

  if status then
    Phone.SetupNeeded = false
  end

  cb({ status = status })
end)

RegisterNUICallback('focus', function(data, cb)
  if Config.WalkWhenOpen then
    SetNuiFocusKeepInput(false)
  end
  cb('OK')
end)

RegisterNUICallback('unfocus', function(data, cb)
  if Config.WalkWhenOpen then
    SetNuiFocusKeepInput(true)
  end
  cb('OK')
end)
