function CreatePhone(src, identifier, number, avatar, contacts, messages, accounts, mail, notes, apps, gallery, call_history)
  local self = {}

  self.source = src
  self.identifier = identifier
  self.number = number
  self.contacts = contacts and json.decode(contacts) or {}
  self.messages = messages and json.decode(messages) or {}
  self.callHistory = call_history and json.decode(call_history) or {}
  self.accounts = accounts and json.decode(accounts) or {}
  self.mail = mail and json.decode(mail) or {}
  self.gallery = gallery and json.decode(gallery) or {}
  self.notes = notes and json.decode(notes) or {}
  self.apps = apps and json.decode(apps) or {}
  self.settings = {}

  self.setSettings = function(settings)
    self.settings = settings
  end

  self.getNumber = function()
    return self.number
  end

  self.getContacts = function()
    return self.contacts
  end

  self.getMessages = function(number)
    if number then
      if not self.messages[number] then
        self.messages[number] = { chat = {} }
      end

      self.messages[number].hide = false;
      return self.messages[number]
    end

    return self.messages
  end

  self.addMessage = function(number, from, id, msg, gps, images, sent, timestamp)
    if not self.messages[number] then
      self.messages[number] = { chat = {} }
    end

    self.messages[number].hide = false;
    table.insert(self.messages[number].chat, { from = from, id = id, msg = msg, gps = gps, images = images, read = sent, timestamp = timestamp })
  end

  self.removeMessage = function(number, id)
    for k, v in pairs(self.messages[number].chat) do
      if v.id == id then
        table.remove(self.messages[number].chat, k)
      end
    end
  end

  self.markRead = function(to)
    if not self.messages[to] then return end
    for k, v in pairs(self.messages[to].chat) do
      self.messages[to].chat[k].read = true
    end
  end

  self.closeChat = function(number)
    self.messages[number].hide = true;
  end

  self.addContact = function(id, name, number, profile)
    self.contacts[#self.contacts + 1] = { id = id, name = name, number = number, profile = profile }
  end

  self.removeContact = function(id)
    for k, v in pairs(self.contacts) do
      if v.id == id then
        table.remove(self.contacts, k)
      end
    end
  end

  self.editContact = function(id, name, number, profile)
    for k, v in pairs(self.contacts) do
      if v.id == id then
        self.contacts[k] = { id = id, name = name, number = number, profile = profile }
      end
    end
  end

  self.findContact = function(number)
    local val = { name = number, number = number, avatar = nil, exists = false }
    local isDefault = false

    for k, v in pairs(Config.DefaultContacts) do
      if v.number == number then
        isDefault = v
      end
    end

    if isDefault then
      val = { name = isDefault.name, number = number, exists = true }
    end

    for k, v in pairs(self.contacts) do
      if number == v.number then
        val = { id = v.id, name = v.name, number = number, avatar = v.profile, exists = true }
      end
    end

    return val
  end

  self.getCallHistory = function()
    return self.callHistory
  end

  self.addToCallhistory = function(number, time, missed, hidden, read)
    self.callHistory[#self.callHistory + 1] = { id = #self.callHistory + 1, number = number, hidden = hidden, time = time, missed = missed, read = read }
  end

  self.deleteCallLog = function(id)
    for k, v in pairs(self.callHistory) do
      if v.id == id then
        table.remove(self.callHistory, k)
      end
    end
  end

  self.markCallsRead = function()
    for k, v in pairs(self.callHistory) do
      v.read = true
    end
  end

  self.setAccount = function(name, data)
    self.accounts[name] = data
  end

  self.removeAccount = function(name)
    self.accounts[name] = nil
  end

  self.getAccount = function(name)
    return self.accounts[name]
  end

  self.getGallery = function()
    return self.gallery
  end

  self.addImageToGallery = function(id, img, date)
    self.gallery[#self.gallery + 1] = { id = id, img = img, date = date }
  end

  self.deleteImage = function(id)
    for k, v in pairs(self.gallery) do
      if v.id == id then
        table.remove(self.gallery, k)
      end
    end
  end

  self.getMail = function()
    return self.mail
  end

  self.deleteEmail = function(id)
    for k, v in pairs(self.mail) do
      if v.id == id then
        table.remove(self.mail, k)
      end
    end
  end

  self.addMail = function(email)
    self.mail[#self.mail + 1] = email
  end

  self.getNotes = function()
    return self.notes
  end

  self.addNote = function(id, content)
    self.notes[#self.notes + 1] = { id = id, content = content }
  end

  self.deleteNote = function(id)
    for k, v in pairs(self.notes) do
      if v.id == id then
        table.remove(self.notes, k)
      end
    end
  end

  self.updateNote = function(id, content)
    for k, v in pairs(self.notes) do
      if v.id == id then
        v.content = content
      end
    end
  end

  self.getApps = function()
    return self.apps
  end

  self.addApp = function(app)
    table.insert(self.apps, app)
  end

  self.removeApp = function(app)
    for k, v in pairs(self.apps) do
      if v == app then
        table.remove(self.apps, k)
      end
    end
  end

  self.reset = function()
    self.contacts = {}
    self.messages = {}
    self.callHistory = {}
    self.accounts = {}
    self.mail = {}
    self.gallery = {}
    self.settings = {}
    self.notes = {}
  end

  return self
end
