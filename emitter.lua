local emitter = {__index = {}}

function emitter.__call(self)
  local instance = setmetatable({}, self)
  self.__init(instance)
  return instance
end

function emitter.__init(instance)
  instance.listeners = {}
end

function emitter.__index:emit(channel, ...)
  local listeners = self.listeners[channel]

  if listeners ~= nil then
    for _, listener in ipairs(listeners) do
      listener(...)
    end

    return true
  end

  return false
end

function emitter.__index:on(channel, listener)
  if self.listeners[channel] == nil then
    self.listeners[channel] = {}
  end

  table.insert(self.listeners[channel], listener)
end

function emitter.__index:off(channel, listener)
  local listeners = self.listeners[channel]

  if listeners ~= nil then
    for i, other in ipairs(listeners) do
      if listener == other then
        table.remove(listeners, i)

        if #listeners == 0 then
          self.listeners[channel] = nil
        end
      end
    end
  end
end

return emitter
