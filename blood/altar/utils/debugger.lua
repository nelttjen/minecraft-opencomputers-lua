local termlib = require("utils/terminal")
local tablelib = require("utils/table")
local colorlib = require("utils/colors_hex")

local lib = {}

function lib.printDebug(table)
    termlib.printf("")
    termlib.colorprintf(colorlib.crimson, "===========")
    tablelib.printTable(table)
end

return lib