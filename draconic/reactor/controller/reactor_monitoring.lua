local colorlib = require("utils/colors_hex")
local termlib = require("utils/terminal")

local lib = {}

local current
local present

function lib.updateFields(dcReactor)
    present = current
    current = dcReactor.getReactorInfo()
end

function lib.getReactorColorByStatus(status)
    if status == "offline" then
        return colorlib.red
    elseif status == "charging" then
        return colorlib.yellow
    elseif status == "charged" then
        return colorlib.gold
    elseif status == "online" then
        return colorlib.lime
    elseif status == "stopping" then
        return colorlib.crimson
    elseif status == "invalid" then
        return colorlib.darkred
    end
    return colorlib.darkred
end

function lib.getDefaultByValues(val1, val2)
    if val2 == 0.0 then
        return colorlib.red
    end

    local percent = val1 / val2 * 100

    if percent < 15 then
        return colorlib.lime
    elseif percent < 30 then
        return colorlib.green
    elseif percent < 50 then
        return colorlib.yellow
    elseif percent < 60 then
        return colorlib.gold
    elseif percent < 75 then 
        return colorlib.orange
    elseif percent < 90 then
        return colorlib.crimson
    end
    return colorlib.red
end

function lib.getShieldColorByShieldEnergy(energy, maxEnergy)
    if maxEnergy == 0.0 then
        return colorlib.lime
    end

    local percent = energy / maxEnergy * 100

    if percent < 5 then
        return colorlib.red
    elseif percent < 10 then
        return colorlib.crimson
    elseif percent < 15 then
        return colorlib.orange
    elseif percent < 20 then
        return colorlib.yellow
    elseif percent < 25 then
        return colorlib.green
    end

    return colorlib.lime
end

function lib.getTemperature(val1, val2)
    if val2 == 0 then
        return colorlib.lime
    end

    local percent = val1 / val2 * 100

    if percent < 20 then
        return colorlib.crimson
    elseif percent < 30 then
        return colorlib.orange
    elseif percent < 50 then
        return colorlib.yellow
    elseif percent < 70 then
        return colorlib.gold
    elseif percent < 80 then
        return colorlib.lime
    elseif percent < 85 then
        return colorlib.crimson
    end
    return colorlib.red

end

function lib.writeStats(dcReactor, timer)
    lib.updateFields(dcReactor)
    if present == nil then
        return
    end

    local statusColor = lib.getReactorColorByStatus(current.status)
    local tempColor = lib.getTemperature(current.temperature, 10000.0)
    local shieldColor = lib.getShieldColorByShieldEnergy(current.fieldStrength, current.maxFieldStrength)
    local energyColor = lib.getDefaultByValues(current.energySaturation, current.maxEnergySaturation)
    local fuelColor = lib.getDefaultByValues(current.fuelConversion, current.maxFuelConversion)

    termlib.colorprintf(colorlib.magenta, "Reactor statistics:")
    
    -- status
    termlib.lcolorprintf(colorlib.cyan, "Current reactor status: ")
    termlib.colorprintf(statusColor, current.status)

    -- temperature
    termlib.lcolorprintf(colorlib.cyan, "Current reactor temperature: ")
    termlib.colorprintf(tempColor, "%.0f / %.0f", current.temperature, 10000.0)

    -- energy saturation
    termlib.lcolorprintf(colorlib.cyan, "Current reactor saturation: ")
    termlib.lcolorprintf(energyColor, "%.0f / %.0f - %.2f%% ", current.energySaturation, current.maxEnergySaturation, current.energySaturation / current.maxEnergySaturation * 100)
    termlib.colorprintf(colorlib.lime, "(+%.2fh RF/t)", current.generationRate)

    -- field strength
    termlib.lcolorprintf(colorlib.cyan, "Current reactor shiel strength: ")
    termlib.lcolorprintf(shieldColor, "%.0f / %.0f - %.2f%% ", current.fieldStrength, current.maxFieldStrength, current.fieldStrength / current.maxFieldStrength * 100)
    termlib.colorprintf(colorlib.crimson, "(-%.2f RF/t)", current.fieldDrainRate)

    -- fuel convertion
    termlib.lcolorprintf(colorlib.cyan, "Current fuel conversion: ")
    termlib.colorprintf(fuelColor, "%.0f / %.0f - %.2f%%", current.fuelConversion, current.maxFuelConversion, current.fuelConversion / current.maxFuelConversion * 100)

    -- profit
    termlib.printf("")
    termlib.lcolorprintf(colorlib.cyan, "Current profit: ")
    local genRate
    if current.status == "stopping" then
        genRate = 0.0
    else
        genRate = current.generationRate
    end

    local show = genRate - current.fieldDrainRate

    if show < 0 then
        show = show * -1
        termlib.colorprintf(colorlib.crimson, "-%.0f RF/t", show)
    else 
        termlib.colorprintf(colorlib.lime, "+%.0f RF/t", show)
    end
    
    -- uptime
    termlib.printf("")
    termlib.lcolorprintf(colorlib.cyan, "Uptime: ")
    termlib.colorprintf(colorlib.lime, "%.0f seconds", timer)

end

function lib.termThread(dcReactor)
    local timer = 1.0
    local delay = 0.5

    while true do
        termlib.clearTerm()
        termlib.printAuthor(true)
        lib.writeStats(dcReactor, timer)
        if current.status == "offline" then
            termlib.colorprintf(colorlib.crimson, "Reactor is offline, exiting program...")
            os.exit()
        end
        os.sleep(delay)
        timer = timer + delay
    end
end

return lib