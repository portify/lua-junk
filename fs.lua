local uv = require("luv")
local promise = require("promise")

local fs = {}

fs.close = uv.fs_close
fs.fstat = uv.fs_fstat

function fs.open(fname, flags, mode)
  if type(mode) == "string" then
    mode = tonumber(mode, 8)
  elseif type(mode) == "nil" then
    mode = 0
  end

  return promise(function(resolve, reject)
    uv.fs_open(fname, flags, mode, function(err, fd)
      if err then
        reject(err)
      else
        resolve(fd)
      end
    end)
  end)
end

function fs.read(fd, size, offset)
  return promise(function(resolve, reject)
    uv.fs_read(fd, size, offset, function(err, buf)
      if err then
        reject(err)
      else
        resolve(buf)
      end
    end)
  end)
end

function fs.readfile(fname)
  return fs.open(fname, "r")
    :next(function(fd)
      local stat = fs.fstat(fd)
      return fs.read(fd, stat.size, 0)
    end)
end

return fs
