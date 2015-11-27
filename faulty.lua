local emitter = require("emitter")

local faulty = {
  mode = "print"
}

setmetatable(faulty, emitter)
emitter.__init(faulty)

function faulty:trigger(event, value, message)
  if not self:emit(event, value) then
    local text = message .. ": " .. tostring(value)

    if self.mode == "error" then
      error(text, 2)
    elseif self.mode == "print" then
      print(text)
    elseif self.mode ~= "ignore" then
      error("unknown faulty.mode " .. self.mode)
    end
  end
end

return faulty
