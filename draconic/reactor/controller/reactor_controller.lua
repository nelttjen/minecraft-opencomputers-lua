local config = require("config")
local colorlib = require("utils/colors_hex")
local termlib = require("utils/terminal")
local component = require("component")
local os = require("os")

local dracReactorCurrent = nil

local currGenRate = 0.0
local currShieldRate = 0.0
local currHelpRate = 0.0

local gateShieldInput
local gateReactorOutput
local gateCoreOutput
local gateEmergency

local WAS_EMERGENCY

local lib = {}

function lib.updateFields(reactor)
    dracReactorCurrent = reactor.getReactorInfo()
    return dracReactorCurrent
end

function lib.setGateFlow(gate, flow)
    gate.setSignalLowFlow(flow)
end

function lib.resetGateFlow()
    lib.setGateFlow(gateShieldInput, 0.0)
    lib.setGateFlow(gateReactorOutput, 0.0)
    
    if gateCoreOutput ~= nil then
        lib.setGateFlow(gateCoreOutput, 0.0)
    end

    if gateEmergency ~= nil then
        lib.setGateFlow(gateEmergency, 0.0)
    end
end

function lib.chargeReactor(dc_reactor)
    dc_reactor.chargeReactor()
end

function lib.changeGateFlow(overrideHelp)
    local percent = dracReactorCurrent.fieldStrength / dracReactorCurrent.maxFieldStrength * 100
    
    lib.setGateFlow(gateShieldInput, currShieldRate)
    lib.setGateFlow(gateReactorOutput, currGenRate)
    
    if gateCoreOutput ~= nil then
        lib.setGateFlow(gateCoreOutput, currGenRate - currShieldRate)
    end

    if gateEmergency ~= nil then
        if overrideHelp then
            if gateCoreOutput ~= nil then
                lib.setGateFlow(gateCoreOutput, currGenRate)
            end
            
            lib.setGateFlow(gateShieldInput, 0.0)
            lib.setGateFlow(gateEmergency, currHelpRate)
        elseif config.enableHelpShield then

            if percent < config.shieldPercentHelpLimit then
                lib.setGateFlow(gateEmergency, config.energyHelpFlow)
            else
                lib.setGateFlow(gateEmergency, 0.0)
            end
        end
    end
        
end

function lib.detectGates()
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

function lib.checkTemp(dcReacor)
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

function lib.checkShield(dcReacor)
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

function lib.controlReactor(dcReactor)
    while true do
        local overrideHelp = false
        -- delayer
        os.sleep(0.5)
        lib.updateFields(dcReactor)

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
            lib.checkShield()
            lib.checkTemp()

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
                lib.resetGateFlow()
                lib.setGateFlow(gateReactorOutput, config.offlineReactorGateChangeFlow)
                if gateCoreOutput ~= nil then
                    lib.setGateFlow(gateCoreOutput, config.offlineReactorGateChangeFlow)
                end
            end

            os.exit()
        end
        lib.changeGateFlow(overrideHelp)
    end
end

function lib.reactorOffline(dcReactor)
    local result = termlib.ask("Reactor offline, activate?", colorlib.yellow)
    if result then
        print("Starting reactor")
        lib.chargeReactor(dcReactor)
        os.sleep(0.5)
    else
        os.exit()
    end
end

return lib


