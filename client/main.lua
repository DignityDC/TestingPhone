Phone.Open = false
Phone.Loaded = false
Phone.Setup = false
Phone.SetupNeeded = true
Phone.Model = nil
Phone.Timeout = false
Phone.Apps = {}
Phone.Data = {}
Phone.SpamLock = false
Phone.Locked = false

if Config.MultiCharacterSupport then
  if Config.UsingESX then
    RegisterNetEvent(Events.onLoaded, function()
      Phone.API.TriggerServerEvent("loadPhone")
    end)

    RegisterNetEvent(Events.onUnload, function()
      ClosePhone()
      Reset()
    end)
  elseif Config.UsingQB then
    RegisterNetEvent(Events.onLoaded, function()
      Phone.API.TriggerServerEvent("loadPhone")
    end)

    RegisterNetEvent(Events.onUnload, function()
      ClosePhone()
      Reset()
      Phone.API.TriggerServerEvent('phone:unload')
    end)
  end
else
  CreateThread(function()
    while true do
      Wait(1)
      if NetworkIsPlayerActive(PlayerId()) then
        Phone.API.TriggerServerEvent("loadPhone")
        if Config.DebugMode then
          OpenPhone()
        end
        break
      end
    end
  end)
end

RegisterCommand("phone", function()
  OpenPhone()
end)

RegisterCommand("resetPhoneHud", function()
  ClosePhone(true)
end)

RegisterNetEvent("phone:notify", function(notification)
  Notify(notification)
end)

RegisterNetEvent("phone:loaded", function(data)
  if data.accounts['main'] then
    Phone.SetupNeeded = false
  else
    ResetSettings()
  end

  Phone.Data = data
  Phone.Loaded = true
  Wait(250)
  BootPhone()
end)

CreateThread(function()
  local playerDead = false

  while true do
    local sleep = 1000
    local player = PlayerId()

    if NetworkIsPlayerActive(player) then
      local playerPed = PlayerPedId()

      if IsPedFatallyInjured(playerPed) and not playerDead then
        sleep = 0
        playerDead = true
        TriggerEvent('phone:playerDied')
      elseif not IsPedFatallyInjured(playerPed) and playerDead then
        sleep = 0
        playerDead = false
      end
    end

    Wait(sleep)
  end
end)

if not Config.OpenPhoneWhilstDead then
  AddEventHandler('phone:playerDied', function()
    ClosePhone(true)
  end)
end

-- enable certain controls
if Config.WalkWhenOpen then
  CreateThread(function()
    while true do
      Wait(0)
      if Phone.Open then
        if not cameraFocus then
          DisableAllControlActions(0)
          DisableAllControlActions(2)
        end


        EnableControlAction(0, 32, true)
        EnableControlAction(0, 34, true)
        EnableControlAction(0, 31, true)
        EnableControlAction(0, 30, true)
        EnableControlAction(0, 22, true)
        EnableControlAction(0, 21, true)

        -- car
        EnableControlAction(0, 71, true)
        EnableControlAction(0, 72, true)
        EnableControlAction(0, 59, true)

        -- push to talk
        EnableControlAction(0, 249, true)
      end
    end
  end)
end

RegisterKeyMapping("phone", "Phone", "keyboard", Config.OpenKey)
