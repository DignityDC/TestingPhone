local saveUserLog = -1
MySQL.Async.store("UPDATE phones SET contacts=?, messages=?, accounts=?, gallery=?, mail=?, notes=?, apps=?, call_history=? WHERE identifier=?"
  , function(storeId) saveUserLog = storeId end)

function GetPlayerPhone(src)
  if not Phones[src] then
    return nil
  end

  return Phones[src]
end

function GenerateNumber()
  while true do
    Wait(1)
    local num1 = tostring(math.random(100, 900))
    local num2 = tostring(math.random(100, 900))
    local formattedNumber = Config.StartingDigits .. num1 .. num2
    if not DoesNumberExist(formattedNumber) then
      return formattedNumber
    end
  end
end

function DoesNumberExist(number)
  local p = promise.new()
  MySQL.Async.fetchScalar("SELECT COUNT(1) FROM phones WHERE phone_number=@number",
    {
      ["@number"] = formattedNumber
    }, function(count)
    if count > 0 then
      p:resolve(true)
    else
      p:resolve(false)
    end
  end)
  return Citizen.Await(p)
end

function GetPlayerFromPhone(number)
  for k, v in pairs(Phones) do
    if v.number == number then
      return k
    end
  end
end

function GetPhones()
  local phones = {}
  for k, v in pairs(Phones) do
    phones[#phones + 1] = v
  end
  return phones
end

function SavePhone(phone, cb)
  local parameters = {
    json.encode(phone.contacts),
    json.encode(phone.messages),
    json.encode(phone.accounts),
    json.encode(phone.gallery),
    json.encode(phone.mail),
    json.encode(phone.notes),
    json.encode(phone.apps),
    json.encode(phone.callHistory),
    phone.identifier
  }

  MySQL.Async.execute(saveUserLog, parameters, function()
    print(('[^4Phone^7] Saved phone ^5"%s^7"'):format(phone.number))
    if cb then
      cb()
    end
  end)
end

function SavePhones()
  local phones = GetPhones()
  if #phones > 0 then
    for i = 1, #phones do
      local done = promise.new()
      local phone = phones[i]
      parameters = {
        json.encode(phone.contacts),
        json.encode(phone.messages),
        json.encode(phone.accounts),
        json.encode(phone.gallery),
        json.encode(phone.mail),
        json.encode(phone.notes),
        json.encode(phone.apps),
        json.encode(phone.callHistory),
        phone.identifier
      }

      MySQL.Async.execute(saveUserLog, parameters, function()
        done:resolve()
      end)

      Citizen.Await(done)
    end

    print("[^4Phone^7] Saved All Phones")
  end
end

local function StartSync()
  CreateThread(function()
    while true do
      Wait(Config.SaveInterval * 60 * 1000)
      SavePhones()
    end
  end)
end

StartSync()
