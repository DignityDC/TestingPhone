Phones = {}

CreateThread(function()
  if GetCurrentResourceName() ~= 'phone' then
    print(('[^4Phone^7] ^1Please rename resource ^7%s^1 to ^7phone^7'):format(GetCurrentResourceName()))
  end
end)

if Config.MultiCharacterSupport then
  if Config.UsingESX then
    AddEventHandler(Events.onLogout, function(src)
      local phone = GetPlayerPhone(src)

      if phone then
        SavePhone(phone, function()
          Phones[src] = nil
        end)
      end
    end)
  elseif Config.UsingQB then
    Phone.API.RegisterServerEvent('phone:unload', function(src)
      local phone = GetPlayerPhone(src)

      if phone then
        SavePhone(phone, function()
          Phones[src] = nil
        end)
      end
    end)
  end
end

Phone.API.RegisterServerEvent("loadPhone", function(source)
  if not Phones[source] then
    local identifier = GetUserLicense(source)

    if Config.MultiCharacterSupport then
      if Config.UsingESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        identifier = xPlayer.getIdentifier()
      elseif Config.UsingQB then
        local player = QBCore.Functions.GetPlayer(source)
        identifier = player.PlayerData.citizenid
      end
    end

    local p = promise.new()
    MySQL.Async.fetchAll("SELECT * FROM phones WHERE identifier=@identifier", {
      ["@identifier"] = identifier
    }, function(result)
      if #result > 0 then
        p:resolve(result[1])
      else
        p:resolve(nil)
      end
    end)

    local phoneData = Citizen.Await(p)

    if phoneData then
      Phones[source] = CreatePhone(
        source,
        identifier,
        phoneData.phone_number,
        phoneData.avatar,
        phoneData.contacts,
        phoneData.messages,
        phoneData.accounts,
        phoneData.mail,
        phoneData.notes,
        phoneData.apps,
        phoneData.gallery,
        phoneData.call_history
      )
    else
      local number = GenerateNumber()
      local createdInDb = promise.new()
      MySQL.Async.execute("INSERT INTO phones (identifier, phone_number) VALUES (@identifier, @number)",
        {
          ["@identifier"] = identifier,
          ["@number"] = number
        }, function()
        createdInDb:resolve()
      end)
      Citizen.Await(createdInDb)
      Phones[source] = CreatePhone(source, identifier, number)
    end

    print(('[^4Phone^7] Phone Loaded ^5"%s^7"'):format(Phones[source].number))
    TriggerClientEvent("phone:loaded", source, Phones[source])
  end
end)

Phone.API.RegisterServerEvent('phone:syncSettings', function(source, settings)
  local phone = GetPlayerPhone(source)
  if phone then
    phone.setSettings(settings)
  end
end)

Phone.API.RegisterServerEvent('phone:createAccount', function(source, account)
  local phone = GetPlayerPhone(source)

  -- Check to see if email is being used
  local p = promise.new()
  MySQL.Async.fetchAll("SELECT email FROM phone_accounts WHERE email=@email", { ["@email"] = account.email },
    function(result)
      if result[1] then
        p:resolve(true)
        return
      end
      p:resolve(false)
    end)

  local found = Citizen.Await(p)

  if found then
    return Locales.emailInUse
  end


  local p = promise.new()
  MySQL.Async.execute("INSERT INTO phone_accounts (email, name, password) VALUES (@email, @name, @password)", {
    ["@email"] = account.email,
    ["@name"] = account.name,
    ["@password"] = account.password
  }, function()
    p:resolve(true)
  end)

  Citizen.Await(p)

  phone.setAccount('main', { name = account.name, email = account.email })

  return false
end)

Phone.API.RegisterServerEvent('phone:login', function(source, account)
  local phone = GetPlayerPhone(source)

  local status = promise.new()
  MySQL.Async.fetchAll("SELECT * FROM phone_accounts WHERE email=@email", {
    ["@email"] = account.email,
  }, function(result)
    if result[1] then
      if result[1].password == account.password then
        status:resolve(result[1])
        return
      end
    end
    status:resolve(false)
  end)

  local account = Citizen.Await(status)

  if account then
    phone.setAccount('main', account)
  end

  return account
end)

Phone.API.RegisterServerEvent('phone:reset', function(source)
  local phone = GetPlayerPhone(source)
  phone.reset()
end)

AddEventHandler('playerDropped', function()
  local src = source
  local phone = GetPlayerPhone(src)

  if phone then
    SavePhone(phone, function()
      Phones[src] = nil
    end)
  end
end)

Phone.API.RegisterServerEvent('phone:sync', function(src, settings)
  local phone = GetPlayerPhone(src)
  local saving = promise.new()
  SavePhone(phone, function()
    SetTimeout(1000, function()
      saving:resolve()
    end)
  end)
  return Citizen.Await(saving)
end)

Phone.API.RegisterServerEvent('phone:hasPhone', function(src)
  local player = nil
  local phoneItem = nil

  if Config.UsingESX then
    player = ESX.GetPlayerFromId(src)
    if player.getInventoryItem('phone') then
      if player.getInventoryItem('phone').count > 0 then
        phoneItem = true
      end
    end
  elseif Config.UsingQB then
    player = QBCore.Functions.GetPlayer(src)
    phoneItem = player.Functions.GetItemByName("phone")
  end

  if not phoneItem then
    return false
  end

  return true
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
  if eventData.secondsRemaining == 60 then
    CreateThread(function()
      Wait(50000)
      SavePhones()
    end)
  end
end)
