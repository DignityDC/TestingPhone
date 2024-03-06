local weathers = {
  BLIZZARD = 669657108,
  CLEAR = 916995460,
  CLEARING = 1840358669,
  CLOUDS = 821931868,
  EXTRASUNNY = -1750463879,
  FOGGY = -1368164796,
  HALLOWEEN = -921030142,
  NEUTRAL = -1530260698,
  OVERCAST = -1148613331,
  RAIN = 1420204096,
  SMOG = 282916021,
  SNOW = -273223690,
  SNOWLIGHT = 603685163,
  THUNDER = -1233681761,
  XMAS = -1429616491,
}

function OpenPhone()
  if not Phone.Loaded then return end
  if Phone.Locked then return end

  if not Phone.Setup then
    BootPhone()
    return
  end

  if Phone.Open then
    return
  end

  if Phone.Timeout then
    return
  end

  if not Phone.Loaded then
    return
  end

  if IsPauseMenuActive() then
    return
  end

  if not Config.OpenPhoneWhilstDead then
    if IsEntityDead(PlayerPedId()) then
      return
    end
  end

  if Config.RequireItem then
    if Config.UsingESX or Config.UsingQB then
      local hasPhone = Phone.API.TriggerServerEvent('phone:hasPhone')
      if not hasPhone then
        return
      end
    end
  end


  if not onCall and not calling then
    PhoneAnimation(true)
  end

  local weather = nil
  local weatherType1, weatherType2, percentWeather2 = GetWeatherTypeTransition()
  for k, v in pairs(weathers) do
    if v == weatherType2 or v == weatherType1 then
      weather = tostring(k)
    end
  end


  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(Config.WalkWhenOpen)
  SendNUIMessage({
    type = "open",
    weather = weather,
    setup = Phone.SetupNeeded
  })
  Phone.Open = true

  local installedApps = Phone.API.TriggerServerEvent('phone:getInstalledApps')
  local formattedApps = {}

  -- add default apps
  for k, v in pairs(Config.Apps) do
    if v.default then
      table.insert(formattedApps, v)
    end
  end

  -- add installed apps
  for k, v in pairs(installedApps) do
    for k2, v2 in pairs(Config.Apps) do
      if v == v2.id then
        table.insert(formattedApps, v2)
      end
    end
  end

  Phone.Apps = formattedApps
  setAppData(Phone.Apps)
  TriggerEvent("phone:open")
  TriggerEvent('phone:checkWhitelistedApps')
end

function setAppData(apps)
  SendNUIMessage({
    type = "setApps",
    apps = Phone.Apps
  })
end

function ClosePhone(nui)
  if Config.WalkWhenOpen then
    SetNuiFocusKeepInput(false)
  end

  SetNuiFocus(false, false)

  if Phone.Open then
    if not onCall and not calling then
      PhoneAnimation(false)
    end
  end

  Phone.Timeout = true
  SetTimeout(1000, function()
    Phone.Timeout = false
  end)

  Phone.Open = false

  if nui then
    SendNUIMessage({
      type = "close"
    })
  end

  TriggerEvent("phone:closed")
end

function Notify(notification)
  if not Phone.Loaded then return end
  if not Phone.Setup then return end

  SendNUIMessage({
    type = "notify",
    notification = notification
  })
  TriggerEvent("phone:onNotify", notification)
end

function SetNotifications(app, amt)
  for k, v in pairs(Phone.Apps) do
    if v.id == app then
      v.notifications = amt
    end
  end
  setAppData(Phone.Apps)
end

function ResetSettings()
  DeleteResourceKvp("background")
  DeleteResourceKvp("brightness")
  DeleteResourceKvp("animations")
  DeleteResourceKvp("darkMode")
  DeleteResourceKvp("flightMode")
  DeleteResourceKvp("hideNumber")
  DeleteResourceKvp("notifications")
  DeleteResourceKvp("volume")
  DeleteResourceKvp("ringtone")
end

function BootPhone()
  local settings = GetSettings()

  SendNUIMessage({
    type = "boot",
    ringtones = Config.Ringtones,
    backgrounds = Config.DefaultBackgrounds,
    id = GetPlayerServerId(PlayerId()),
    settings = settings,
    locales = Locales
  })

  SendNUIMessage({
    type = 'setImageProvider',
    apiKey = Config.ImgBBProviderKey
  })

  Phone.API.TriggerServerEvent('phone:syncSettings', settings)
end

function PhoneAnimation(pullingOut)
  if pullingOut then
    if IsPedInAnyVehicle(PlayerPedId(), true) then
      LoadAnimDict('anim@cellphone@in_car@ps', function()
        TaskPlayAnim(PlayerPedId(), 'anim@cellphone@in_car@ps', 'cellphone_text_in', 3.0, -1, -1, 50, 0, false, false, false)
        Wait(400)
        AddPhone()
      end)
    else
      LoadAnimDict('cellphone@', function()
        TaskPlayAnim(PlayerPedId(), 'cellphone@', 'cellphone_text_in', 3.0, -1, -1, 50, 0, false, false, false)
        Wait(400)
        AddPhone()
      end)
    end
  else
    if IsPedInAnyVehicle(PlayerPedId(), true) then
      StopAnimTask(PlayerPedId(), 'anim@cellphone@in_car@ps', 'cellphone_text_in', 3.0)
      LoadAnimDict('anim@cellphone@in_car@ps', function()
        TaskPlayAnim(PlayerPedId(), 'anim@cellphone@in_car@ps', 'cellphone_text_out', 3.0, 3.0, 750, 50, 0, false, false, false)
        Wait(800)
        RemovePhone()
      end)
    else
      StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_text_in', 3.0)
      LoadAnimDict('cellphone@', function()
        TaskPlayAnim(PlayerPedId(), 'cellphone@', 'cellphone_text_out', 3.0, 3.0, 750, 50, 0, false, false, false)
        Wait(400)
        RemovePhone()
      end)
    end
  end
end

function AddPhone()
  RemovePhone()

  local ped = PlayerPedId()

  RequestModel(Config.PhoneModel)
  while not HasModelLoaded(Config.PhoneModel) do
    Citizen.Wait(1)
  end

  Phone.Model = CreateObject(Config.PhoneModel, 1.0, 1.0, 1.0, 1, 1, 0)

  local bone = GetPedBoneIndex(ped, 28422)
  local isUnarmed = GetCurrentPedWeapon(ped, "WEAPON_UNARMED")

  if not isUnarmed then
    AttachEntityToEntity(Phone.Model, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
  else
    SetCurrentPedWeapon(ped, "WEAPON_UNARMED", true)
    AttachEntityToEntity(Phone.Model, ped, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
  end
end

function RemovePhone()
  local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
  local closeObj = GetClosestObjectOfType(x, y, z, 1.0, GetHashKey(Config.PhoneModel), false)
  SetEntityAsMissionEntity(closeObj)
  DeleteObject(closeObj)

  if Phone.Model ~= nil then
    DeleteObject(Phone.Model)
    Phone.Model = nil
  end
end

function LoadAnimDict(dict, cb)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
    Wait(1)
  end
  cb()
end

function GetSettings()
  local settings = {
    background = GetResourceKvpString('background'),
    hideNumber = toboolean(GetResourceKvpString('hideNumber') or "false"),
    flightMode = toboolean(GetResourceKvpString('flightMode') or "false"),
    darkMode = toboolean(GetResourceKvpString('darkMode') or "true"),
    animations = toboolean(GetResourceKvpString('animations') or "true"),
    brightness = tonumber(GetResourceKvpString('brightness') or 100),
    notifications = toboolean(GetResourceKvpString('notifications') or "true"),
    volume = tonumber(GetResourceKvpString('volume') or 15),
    ringtone = GetResourceKvpString('ringtone') or "default",
    twitterMentions = toboolean(GetResourceKvpString('twitterMentions') or "true")
  }

  return settings
end

function Reset()
  Phone.Open = false
  Phone.Loaded = false
  Phone.Setup = false
  Phone.SetupNeeded = true
  Phone.Model = nil
  Phone.Timeout = false
  Phone.Apps = {}
  Phone.Data = {}

  SendNUIMessage({
    type = 'lock'
  })
end

function SpamLock()
  Phone.SpamLock = true
  SetTimeout(1000, function()
    Phone.SpamLock = false
  end)
end

function LockPhone(toggle)
  Phone.Locked = toggle
  ClosePhone(true)
end

exports("lockPhone", LockPhone);
