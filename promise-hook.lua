return function(promise, hooks)
  local function hook(executor)
    local prom, wrap

    prom = promise(function(resolve, reject)
      return executor(
        function(result)
          if hooks.resolve then
            hooks.resolve(wrap, result)
          end
          return resolve(result)
        end,
        function(reason)
          if hooks.reject then
            hooks.reject(wrap, reason)
          end
          return reject(reason)
        end
      )
    end)

    wrap = setmetatable({
      next = function(self, fulfilled, rejected)
        local next = prom.next(self, fulfilled, rejected)
        if hooks.next then
          hooks.next(wrap, fulfilled, rejected, next)
        end
        return next
      end
    }, {
      __index = prom
    })

    if hooks.create then
      hooks.create(wrap, executor)
    end

    return wrap
  end

  return setmetatable({}, {
    __index = promise,
    __call = function(_, executor)
      return hook(executor)
    end
  })
end
