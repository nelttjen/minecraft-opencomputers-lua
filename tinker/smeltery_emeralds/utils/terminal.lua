local gpu = require("component").gpu
local math = require("math")
local term = require("term")
local colors = require("utils/colors_hex")

local lib = {}

function lib.printf(s,...)
    local err = io.write(s:format(...))
    print("")
    return err
end

function lib.colorprintf(c,s,...)
    local oldcolor = gpu.getForeground()
    gpu.setForeground(c)
    lib.printf(s,...)
    gpu.setForeground(oldcolor)
end

function lib.lprintf(s,...)
    local err = io.write(s:format(...))
    return err
end

function lib.lcolorprintf(c,s,...)
    local oldcolor = gpu.getForeground()
    gpu.setForeground(c)
    lib.lprintf(s,...)
    gpu.setForeground(oldcolor)
end

function lib.ask(what, color)
    lib.lcolorprintf(color, string.format("%s [Y/n]:", what))
    local result = io.read()

    if not result then
        os.exit()
    end

    if result == 'Y' or result == 'y' then
        return true
    elseif result == "N" or result == "n" then
        return false
    end

    return nil
end

function lib.clearTerm()
    term.clear()
end

return lib
