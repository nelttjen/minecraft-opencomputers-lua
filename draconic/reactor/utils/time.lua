local math = require("math")
local lib = {}

function lib.prettyTime(time)
  local days = math.floor(time/86400)
  local remaining = time % 86400
  local hours = math.floor(remaining/3600)
  remaining = remaining % 3600
  local minutes = math.floor(remaining/60)
  remaining = remaining % 60
  local seconds = remaining
  local newhours
  local newminutes
  local newseconds
  if (hours < 10) then
    newhours = string.format("0%d", hours)
  else
    newhours = string.format("%d", hours)
  end
  if (minutes < 10) then
    newminutes = string.format("0%d", minutes)
  else
    newminutes = string.format("%d", minutes)
  end
  if (seconds < 10) then
    newseconds = string.format("0%d", seconds)
  else
    newseconds = string.format("%d", seconds)
  end
  return string.format("%d:%s:%s:%s",days,newhours,newminutes,newseconds)
end

return lib