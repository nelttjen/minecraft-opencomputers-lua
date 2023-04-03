local component = require("component")
local os = require("os")
local term = require("term")
local thread = require("thread")
local math = require("math")
local gpu = component.gpu


-- config.lua
local config = {}

config.PRINT_DEBUG = false  -- Prints debug without starting controller programm

config.lowReactorChargingRate = 160000.0 -- How fast reactor will charge with disabled fastCharge (RF/t), default: 160k RF/t (160000.0)
config.fastReactorChargingRate = 10000000.0  -- How fast reactor will charge with enabled fastCharge (RF/t), default: 10m RF/t (10000000.0)
config.fastChargeReactor = true

config.temperatureLimit = 8500 -- Temperature limit, if above - emergency shutdown reactor, default: 8500
config.shieldPercentEmergencyLimit = 2 -- Sheild percent limit, if above - emergency shutdown reactor, default: 2
config.enableEmergencyMode = true -- Emergency mode system, default: true

config.fastReactorHeatLimit = 7500 -- Reactor will be fast heating while temperature is under this value, default: 7500
config.temperature = 7975 -- Reactor will keep this temperature while running
config.shieldPercentDefaultLimit = 7  -- Reactor will handle shield in +- 1% of this value, default: 7

config.shieldPercentHelpLimit = 3 -- Limit to activate help energy flow to reactor's shield, default: 3
config.energyHelpFlow = 750000.0 -- Help mode shield input rate, default: 750k RF/t (750000.0)
config.enableHelpShield = true -- Should help gate provide energy to low shield

-- Detects flux gates to control reactor
config.gateInputShieldFlowDetect = 1000.0  --gate to reactor energy injector. Must contains this RF/t as Redstone Signal High Value. required
config.gateOutputReactorFlowDetect = 2000.0 --gate from reactor stablizer to output energy from reactor. required
config.gateOutputCoreFlowDetect = 3000.0 --gate after output reactor gate. It will contains reactor output - shield input value. optional
config.gateInputEmergencyShieldFlowDetect = 4000.0 --gate to help power shield to energy injector. optional

config.offlineReactorGateChange = true -- change gates to output when reactor is stopped after using program
config.offlineReactorGateChangeFlow = 500000.0 -- output gate flow when reactor is stopped





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






-- table.lua
local tablelib = {}

function tablelib.printTable(in_table)
    for k, v in pairs(in_table) do
        print(k, ' - ', v)
    end
end

function tablelib.tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end





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

function termlib.printAuthor(mlgMode)
    local color
    if mlgMode then
        local len = tablelib.tablelength(colorlib)
        local rand = math.floor(math.random(len))
        color = colorlib[rand - 1]
        local count = 0
        for k, v in pairs(colorlib) do
            if count == rand - 1 then
                color = colorlib[k]
                break
            end
            count = count + 1
        end
    else
        color = colorlib.white
    end
    
    termlib.colorprintf(color, "===================================================================================")
    termlib.colorprintf(color, "=                  Draconic reactor controller by NelttjeN                        =")
    termlib.colorprintf(color, "=                           Program version: 1.2                                  =")
    termlib.colorprintf(color, "= This project is open source, if you want to use it, you can find source code on =")
    termlib.colorprintf(color, "=            https://github.com/NelttjeN/minecraft-opencomputers-lua/             =")
    termlib.colorprintf(color, "=                 Was wrote during playing on Cristalix SkyVoid                   =")
    termlib.colorprintf(color, "===================================================================================")
    print("")
    print("")
    print("")
end

function termlib.clearTerm()
    term.clear()
end




-- debugger.lua
local debuglib = {}

function debuglib.printDebug(table)
    termlib.printf("")
    termlib.colorprintf(colorlib.crimson, "===========")
    tablelib.printTable(table)
end





-- component.lua
local componentlib = {}

function componentlib.checkComponentAvailable(name, quitProgram)
    if not component.isAvailable(name) then
        
        termlib.colorprintf(colorlib.gold, "Component %s not connected", name)

        if quitProgram then
            termlib.colorprintf(colorlib.red, "This component is required to program working, termintaing...")
            os.exit()
        else
            termlib.colorprintf(colorlib.orange, "WARNING!!! This component is not required, but some functions may not working")
        end
        return nil
    end
    return component[name]
end



-- thread libs

-- reactor_monitoring.lua
local monitoringlib = {}

local current
local present

function monitoringlib.updateFields(dcReactor)
    present = current
    current = dcReactor.getReactorInfo()
end

function monitoringlib.getReactorColorByStatus(status)
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

function monitoringlib.getDefaultByValues(val1, val2)
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

function monitoringlib.getShieldColorByShieldEnergy(energy, maxEnergy)
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

function monitoringlib.getTemperature(val1, val2)
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

function monitoringlib.writeStats(dcReactor, timer)
    monitoringlib.updateFields(dcReactor)
    if present == nil then
        return
    end

    local statusColor = monitoringlib.getReactorColorByStatus(current.status)
    local tempColor = monitoringlib.getTemperature(current.temperature, 10000.0)
    local shieldColor = monitoringlib.getShieldColorByShieldEnergy(current.fieldStrength, current.maxFieldStrength)
    local energyColor = monitoringlib.getDefaultByValues(current.energySaturation, current.maxEnergySaturation)
    local fuelColor = monitoringlib.getDefaultByValues(current.fuelConversion, current.maxFuelConversion)

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

function monitoringlib.termThread(dcReactor)
    local timer = 1.0
    local delay = 0.5

    while true do
        termlib.clearTerm()
        termlib.printAuthor(true)
        monitoringlib.writeStats(dcReactor, timer)
        if current.status == "offline" then
            termlib.colorprintf(colorlib.crimson, "Reactor is offline, exiting program...")
            os.exit()
        end
        os.sleep(delay)
        timer = timer + delay
    end
end






-- reactor_controller.lua
local dracReactorCurrent = nil

local currGenRate = 0.0
local currShieldRate = 0.0
local currHelpRate = 0.0

local gateShieldInput
local gateReactorOutput
local gateCoreOutput
local gateEmergency

local WAS_EMERGENCY

local controllib = {}

function controllib.updateFields(reactor)
    dracReactorCurrent = reactor.getReactorInfo()
    return dracReactorCurrent
end

function controllib.setGateFlow(gate, flow)
    gate.setSignalLowFlow(flow)
end

function controllib.resetGateFlow()
    controllib.setGateFlow(gateShieldInput, 0.0)
    controllib.setGateFlow(gateReactorOutput, 0.0)
    
    if gateCoreOutput ~= nil then
        controllib.setGateFlow(gateCoreOutput, 0.0)
    end

    if gateEmergency ~= nil then
        controllib.setGateFlow(gateEmergency, 0.0)
    end
end

function controllib.chargeReactor(dc_reactor)
    dc_reactor.chargeReactor()
end

function controllib.changeGateFlow(overrideHelp)
    local percent = dracReactorCurrent.fieldStrength / dracReactorCurrent.maxFieldStrength * 100
    
    controllib.setGateFlow(gateShieldInput, currShieldRate)
    controllib.setGateFlow(gateReactorOutput, currGenRate)
    
    if gateCoreOutput ~= nil then
        controllib.setGateFlow(gateCoreOutput, currGenRate - currShieldRate)
    end

    if gateEmergency ~= nil then
        if overrideHelp then
            if gateCoreOutput ~= nil then
                controllib.setGateFlow(gateCoreOutput, currGenRate)
            end
            
            controllib.setGateFlow(gateShieldInput, 0.0)
            controllib.setGateFlow(gateEmergency, currHelpRate)
        elseif config.enableHelpShield then

            if percent < config.shieldPercentHelpLimit then
                controllib.setGateFlow(gateEmergency, config.energyHelpFlow)
            else
                controllib.setGateFlow(gateEmergency, 0.0)
            end
        end
    end
        
end

function controllib.detectGates()
    while true do
        local result = termlib.ask("Done?", colorlib.yellow)

        if result then
            local gates = component.list("flux_gate")

            for addr in gates do
                local gate = component.proxy(addr)
                local rate = gate.getSignalHighFlow()

                if rate == config.gateInputShieldFlowDetect then
                    -- setting input gate 
                    gateShieldInput = gate

                elseif rate == config.gateOutputReactorFlowDetect then
                    -- setting output gate
                    gateReactorOutput = gate
                elseif rate == config.gateOutputCoreFlowDetect then
                    gateCoreOutput = gate
                elseif rate == config.gateInputEmergencyShieldFlowDetect then
                    gateEmergency = gate
                end
            end

            if not gateShieldInput or not gateReactorOutput then
                -- if gates not provided
                if not gateShieldInput then
                    termlib.colorprintf(colorlib.red, "Input shield gate not found, it's required.")
                end
                if not gateReactorOutput then
                    termlib.colorprintf(colorlib.red, "Input shield gate not found, it's required.")
                end

                -- clear variables to avoid linking to one addr
                gateShieldInput = nil
                gateReactorOutput = nil
                gateCoreOutput = nil
                gateEmergency = nil
            else
                -- all is ok, gates found, exiting loop
                if not gateCoreOutput then
                    termlib.colorprintf(colorlib.orange, "Warning! Output to core gate not found, it'll be ignored")
                end
                if not gateEmergency and config.enableEmergencyMode then
                    termlib.colorprintf(colorlib.orange, "Warning! Emergency gate not found, it'll be ignored")
                    os.sleep(1)
                end
                break
            end

        elseif result == nil then
            termlib.colorprintf(colorlib.orange, "No such option")
        end
    end
end

function controllib.checkTemp(dcReacor)
    if dracReactorCurrent.temperature < config.fastReactorHeatLimit then
        currGenRate = dracReactorCurrent.generationRate * 2
    elseif dracReactorCurrent.temperature > config.fastReactorHeatLimit and dracReactorCurrent.temperature < config.temperature then
        currGenRate = dracReactorCurrent.generationRate + 1000.0
    elseif dracReactorCurrent.temperature > config.temperature then
        currGenRate = dracReactorCurrent.generationRate - 1000.0
    end

    if dracReactorCurrent.temperature > config.temperatureLimit and config.enableEmergencyMode then
        dcReacor.stopReactor()
        WAS_EMERGENCY = true
    end
end

function controllib.checkShield(dcReacor)
    local percent = dracReactorCurrent.fieldStrength / dracReactorCurrent.maxFieldStrength * 100

    if config.shieldPercentDefaultLimit + 1.0 >= percent and percent >= config.shieldPercentDefaultLimit - 1.0 then
        -- pass
    else
        if config.shieldPercentDefaultLimit + 1 >= percent then
            currShieldRate = dracReactorCurrent.fieldDrainRate * (1 + config.shieldPercentDefaultLimit / 100) - 1000.0
        else
            currShieldRate = dracReactorCurrent.fieldDrainRate * (1 + config.shieldPercentDefaultLimit / 100) + 1000.0
        end
    end

    if percent < config.shieldPercentEmergencyLimit and config.enableEmergencyMode then
        dcReacor.stopReactor()
        WAS_EMERGENCY = true
    end
end

function controllib.controlReactor(dcReactor)
    while true do
        local overrideHelp = false
        -- delayer
        os.sleep(0.5)
        controllib.updateFields(dcReactor)

        if dracReactorCurrent.status == "charging" then
            if config.fastChargeReactor then
                if gateEmergency ~= nil then
                    currHelpRate = config.fastReactorChargingRate
                    overrideHelp = true
                else
                    currShieldRate = config.fastReactorChargingRate
                end
            else
                if gateEmergency ~= nil then
                    currHelpRate = config.lowReactorChargingRate
                    overrideHelp = true
                else
                    currShieldRate = config.lowReactorChargingRate
                end
            end
        elseif dracReactorCurrent.status == "charged" then
            currGenRate = 200000.0
            currShieldRate = currGenRate / 5
            dcReactor.activateReactor()
        elseif dracReactorCurrent.status == "online" then
            controllib.checkShield()
            controllib.checkTemp()

            if dracReactorCurrent.energySaturation / dracReactorCurrent.maxEnergySaturation * 100 > 60 then
                currGenRate = dracReactorCurrent.generationRate * 10
            end
        elseif dracReactorCurrent.status == "stopping" then
            local coef = 1.5
            if WAS_EMERGENCY then
                coef = 5
            end
            local percent = dracReactorCurrent.fieldStrength / dracReactorCurrent.maxFieldStrength * 100

            currGenRate = dracReactorCurrent.fieldDrainRate * (1 + percent / 100) * coef
            if percent > 40 then
                currShieldRate = 0.0
                currHelpRate = 0.0
                overrideHelp = true
            else
                if gateEmergency ~= nil then
                    currShieldRate = 0.0
                    currHelpRate = dracReactorCurrent.generationRate / coef
                    overrideHelp = true
                else
                    currShieldRate = dracReactorCurrent.fieldDrainRate * coef
                end
            end
        elseif dracReactorCurrent.status == "offline" then
            if config.offlineReactorGateChange then
                controllib.resetGateFlow()
                controllib.setGateFlow(gateReactorOutput, config.offlineReactorGateChangeFlow)
                if gateCoreOutput ~= nil then
                    controllib.setGateFlow(gateCoreOutput, config.offlineReactorGateChangeFlow)
                end
            end

            os.exit()
        end
        controllib.changeGateFlow(overrideHelp)
    end
end

function controllib.reactorOffline(dcReactor)
    local result = termlib.ask("Reactor offline, activate?", colorlib.yellow)
    if result then
        print("Starting reactor")
        controllib.chargeReactor(dcReactor)
        os.sleep(0.5)
    else
        os.exit()
    end
end








-- main.lua
termlib.clearTerm()
termlib.printAuthor(true)
termlib.colorprintf(colorlib.green, "Initializing...")

-- initialization
local dcReactor = componentlib.checkComponentAvailable("draconic_reactor", true)
local fluxGate = componentlib.checkComponentAvailable("flux_gate", true)
local rfStorage = componentlib.checkComponentAvailable("draconic_rf_storage", false)

if config.PRINT_DEBUG then
    debuglib.printDebug(dcReactor)
    debuglib.printDebug(dcReactor.getReactorInfo())
    debuglib.printDebug(fluxGate)
    os.exit()
end

termlib.lcolorprintf(colorlib.green, "Reactor found, current status: ")
termlib.colorprintf(monitoringlib.getReactorColorByStatus(dcReactor.getReactorInfo().status),  dcReactor.getReactorInfo().status)

termlib.colorprintf(colorlib.green, "Flux gate setup")
termlib.colorprintf(colorlib.lightblue, "Enter following inputs as Redstone Signal High in connected gates:")

termlib.lcolorprintf(colorlib.blue, "Shield gate (Reactor energy injector): ")
termlib.colorprintf(colorlib.cyan, "%d RF/t", config.gateInputShieldFlowDetect)

termlib.lcolorprintf(colorlib.blue, "Reactor gate (Energy from reactor): ")
termlib.colorprintf(colorlib.cyan, "%d RF/t", config.gateOutputReactorFlowDetect)

termlib.lcolorprintf(colorlib.blue, "Output gate (Energy controller to core): ")
termlib.colorprintf(colorlib.cyan, "%d RF/t", config.gateOutputCoreFlowDetect)

termlib.lcolorprintf(colorlib.blue, "Shield emergency gate (Reactor energy injector): ")
termlib.colorprintf(colorlib.cyan, "%d RF/t", config.gateInputEmergencyShieldFlowDetect)

controllib.detectGates()

-- create thread of reactor
term.clear()
termlib.printAuthor(true)
termlib.printf("initialization done, Starting controller thread")
local fields = controllib.updateFields(dcReactor)

if fields.status == "offline" then
    controllib.resetGateFlow()
    controllib.reactorOffline(dcReactor)
elseif fields.status == "invalid" then
    termlib.clearTerm()
    termlib.printAuthor(true)
    termlib.colorprintf(colorlib.red, "Invalid reactor configuration. Reinstall reactor and restart program")
    os.exit()
end

local rc_thread = thread.create(controllib.controlReactor, dcReactor)
local term_thread = thread.create(monitoringlib.termThread, dcReactor)

thread.waitForAll({rc_thread, term_thread})