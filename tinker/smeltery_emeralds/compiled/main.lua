local component = require("component")
local sides = require("sides")
local os = require("os")
local term = require("term")

local gpu = component.gpu
local transposer = component.transposer

-- colors_hex.lua
local colorlib = {}

colorlib.red =            0xFF0000
colorlib.green =          0x00FF00
colorlib.yellow =         0xFFFF00
colorlib.orange =         0xFFA500
colorlib.white =          0xFFFFFF
colorlib.gold =           0xFFD700
colorlib.blue =           0x0000FF
colorlib.brown =          0xA52A2A
colorlib.cyan =           0x00FFFF
colorlib.gray =           0x808080
colorlib.lightblue =      0x87CEFA
colorlib.lime =           0x00FF00
colorlib.magenta =        0xFF00FF
colorlib.pink =           0xFF69B4
colorlib.purple =         0x800080
colorlib.silver =         0xC0C0C0
colorlib.darkred =        0x8B0000
colorlib.crimson =        0xDC143C

-- terminal.lua
local termlib = {}

function termlib.printf(s,...)
    local err = io.write(s:format(...))
    print("")
    return err
end

function termlib.colorprintf(c,s,...)
    local oldcolor = gpu.getForeground()
    gpu.setForeground(c)
    termlib.printf(s,...)
    gpu.setForeground(oldcolor)
end

function termlib.lprintf(s,...)
    local err = io.write(s:format(...))
    return err
end

function termlib.lcolorprintf(c,s,...)
    local oldcolor = gpu.getForeground()
    gpu.setForeground(c)
    termlib.lprintf(s,...)
    gpu.setForeground(oldcolor)
end

function termlib.ask(what, color)
    termlib.lcolorprintf(color, string.format("%s [Y/n]:", what))
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

function termlib.clearTerm()
    term.clear()
end

-- main.lua
termlib.clearTerm()

if transposer.getTankCount(sides.top) == 0 then
    termlib.colorprintf(colorlib.crimson, "Top side tank  not found")
    os.exit()
end

if transposer.getTankCount(sides.bottom) == 0 then
    termlib.colorprintf(colorlib.crimson, "Bottom side tank  not found")
    os.exit()
end


while true do
    termlib.clearTerm()
    local countTanks = transposer.getTankCount(sides.top)
    local found = false
    termlib.colorprintf(colorlib.lime, "Fluids in outputsource:")
    local fluidOut = transposer.getFluidInTank(sides.bottom, 1)
    termlib.colorprintf(colorlib.cyan, "%s %.0fmb", fluidOut.label, fluidOut.amount)
    termlib.printf("")

    termlib.colorprintf(colorlib.lime, "Fluids in smeltery:")
    for i = 1, countTanks do
        local fluid = transposer.getFluidInTank(sides.top, i)
        if fluid.name ~= nil then
            termlib.colorprintf(colorlib.cyan, "%s fluid in smeltery: %.0fmb", fluid.label, fluid.amount)
            if fluid.name == "emerald.liquid" then
                found = true
                if fluid.amount > 1 then
                    transposer.transferFluid(sides.top, sides.bottom, fluid.amount - 1)
                end
            end
        end
    end

    if not found then
        termlib.colorprintf(colorlib.red, "Emerald in smeltery not found")
    else
        
    end

    os.sleep(0.5)
end
