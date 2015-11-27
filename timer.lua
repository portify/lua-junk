local timer = {}
local uv = require("luv")

function timer.idle(f)
  local handle = uv.new_idle()

  uv.idle_start(handle, function()
    uv.idle_stop(handle)
    uv.close(handle)
    f()
  end)
end

local function new_timer(t1, t2, f)
  local handle = uv.new_timer()

  uv.timer_start(handle, t1, t2, function()
    if f() == false or t2 < 1 then
      uv.close(handle)
    end
  end)
end

function timer.timeout(timeout, f)
  return new_timer(timeout, 0, f)
end

function timer.interval(timeout, f)
  return new_timer(timeout, timeout, f)
end

return timer
