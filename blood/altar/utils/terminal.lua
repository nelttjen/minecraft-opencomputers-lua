local gpu = require("component").gpu
local math = require("math")
local term = require("term")
local colors = require("utils/colors_hex")
local ut_table = require("utils/table")

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

function lib.printAuthor(mlgMode)
    local color
    if mlgMode then
        local len = ut_table.tablelength(colors)
        local rand = math.floor(math.random(len))
        color = colors[rand - 1]
        local count = 0
        for k, v in pairs(colors) do
            if count == rand - 1 then
                color = colors[k]
                break
            end
            count = count + 1
        end
    else
        color = colors.white
    end
    
    lib.colorprintf(color, "===================================================================================")
    lib.colorprintf(color, "=                      Blood slate crafter by NelttjeN                            =")
    lib.colorprintf(color, "=                           Program version: 1.0                                  =")
    lib.colorprintf(color, "= This project is open source, if you want to use it, you can find source code on =")
    lib.colorprintf(color, "=            https://github.com/NelttjeN/minecraft-opencomputers-lua/             =")
    lib.colorprintf(color, "=                 Was wrote during playing on Cristalix SkyVoid                   =")
    lib.colorprintf(color, "===================================================================================")
    print("")
    print("")
    print("")
end

function lib.clearTerm()
    term.clear()
end

return lib