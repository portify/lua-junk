local faulty = require("faulty")
local timer = require("timer")

local call_later = timer.idle

local function is_indexable(value)
  -- TODO: userdata
  return type(value) == "table"
end

local function is_callable(value)
  if type(value) == "function" then
    return true
  end

  if type(value) == "table" then
    local metatable = getmetatable(value)

    if metatable and is_callable(metatable.__call) then
      return true
    end
  end

  -- TODO: userdata
  return false
end

local function promise(executor)
  local status, result
  local instance = {}

  local listeners = {[true] = {}, [false] = {}}

  local function add_listener(outcome, fn)
    if status ~= nil then
      if status == outcome then
        call_later(fn)
      end
    else
      table.insert(listeners[outcome], fn)
    end
  end

  local function settle(outcome, value)
    if status == nil then
      status = outcome
      result = value

      for _, fn in ipairs(listeners[outcome]) do
        call_later(fn)
      end

      if outcome == false and
          #listeners[outcome] == 0 then
        faulty:trigger("promise-reject", value,
          "Unhandled promise rejection")
      end
    end
  end

  function instance.next(_, fulfilled, rejected)
    return promise(function(resolve, reject)
      if fulfilled ~= nil then
        add_listener(true, function()
          local succeeded, value = pcall(function()
            return fulfilled(result)
          end)

          if succeeded then
            resolve(value)
          else
            reject(value)
          end
        end)
      else
        add_listener(true, function()
          resolve(result)
        end)
      end

      if rejected ~= nil then
        add_listener(false, function()
          local succeeded, value = pcall(function()
            return rejected(result)
          end)

          if succeeded then
            resolve(value)
          else
            reject(value)
          end
        end)
      else
        add_listener(false, function()
          reject(result)
        end)
      end
    end)
  end

  function instance.catch(_, rejected)
    instance.next(_, nil, rejected)
  end

  local function reject(value)
    settle(false, value)
  end

  local function resolve(value)
    if value == instance then
      error("cannot resolve promise with itself", 2)
    end

    if is_indexable(value) then
      local succeeded, next = pcall(function()
        return value.next
      end)

      if not succeeded then
        return settle(false, next)
      end

      if is_callable(next) then
        local succeeded2, value2 = pcall(function()
          next(value, resolve, reject)
        end)

        if not succeeded2 then
          return reject(value2)
        end

        return
      end
    end

    settle(true, value)
  end

  call_later(function()
    executor(resolve, reject)
  end)

  return instance
end

local lib = {
  resolve = function(self, value)
    return self(function(resolve)
      resolve(value)
    end)
  end,
  reject = function(self, value)
    return self(function(_, reject)
      reject(value)
    end)
  end,
  all = false,
  race = false
}

setmetatable(lib, {
  __call = function(_, executor)
    return promise(executor)
  end
})

return lib
