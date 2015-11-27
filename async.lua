local promise = require("promise")

local create, resume, status =
  coroutine.create, coroutine.resume, coroutine.status

local function async(fn)
  return function(...)
    local args = {..., n = select("#", ...)}
    local co = create(fn)

    return promise(function(resolve, reject)
      local function continue(...)
        local success, value = resume(co, ...)

        if success == false then
          reject(value)
        elseif status(co) == "dead" then
          resolve(value)
        else
          value:next(continue, reject)
        end
      end

      continue(unpack(args, 1, args.n))
    end)
  end
end

return async
