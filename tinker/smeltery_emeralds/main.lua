local teblalib = require("utils/table")
local termlib = require("utils/terminal")
local colorlib = require("utils/colors_hex")
local component = require("component")
local sides = require("sides")
local os = require("os")

local transposer = component.transposer

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
    -- termlib.printAuthor(true)
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