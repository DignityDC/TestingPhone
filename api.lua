Phone = {}
Phone.API = {}

if IsDuplicityVersion() then
  Phone.API.RegisterServerEvent = function(eventName, cb)
    RegisterNetEvent(("phone-events-%s"):format(eventName), function(id, data)
      TriggerClientEvent(("phone-events-resolve-%s-%s"):format(eventName, source), source, msgpack.pack_args(cb(source, table.unpack(msgpack.unpack(data)))))
    end)
  end
else
  local id = GetPlayerServerId(PlayerId())

  Phone.API.TriggerServerEvent = function(eventName, ...)
    local p = promise.new();

    local handler = RegisterNetEvent(("phone-events-resolve-%s-%s"):format(eventName, id), function(data)
      p:resolve(table.unpack(msgpack.unpack(data)))
    end)

    TriggerServerEvent(("phone-events-%s"):format(eventName), id, msgpack.pack(table.pack(...)))

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    return result
  end
end

function toboolean(str)
  local bool = false
  if str == "true" then
    bool = true
  end
  return bool
end
