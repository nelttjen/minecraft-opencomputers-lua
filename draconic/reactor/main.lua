local component = require("component")
local io = require("io")
local os = require("os")
local term = require("term")
local thread = require("thread")
local event = require("event")
local filesystem = require("filesystem")
local keyboard = require("keyboard")
local colors = require("colors")
local mathlib = require("math")

local gpu = component.gpu
local DEBUG = false

-- initial variables
-- settings
local startEnergyRate = 508000.0
local fuel_max = 10368.0
local fuel_miss_range = 100
local lowReactorChargingRate = 160000.0
local fastReactorChargingRate = 10000000.0
updateDelay = 20
updateLimitDelay = 8

local fastChargeReactor = true
local checkRFStorage = true

-- limits
local temp_limit = 8500
local shieldPercentDefaultLimit = 7
local shield_percent_down_limit = 4.5

-- auto
local startShieldRate = startEnergyRate / 5
countDelay = 0
countLimitDelay = 0
sleepDelay = 0.5
DOWN = false
WAS_EMERGENCY = false

-- drac reactor variables
drac_reactor_current = nil
drac_reactor_last = nil

-- utils
function print_table(in_table)
    for k, v in pairs(in_table) do
        print(k, ' - ', v)
    end
end

function check_component_available(name, quit_program)
    if not component.isAvailable(name) then
        print(string.format("Component %s not connected", name))

        if quit_program then
            print("This component is required to program working, termintaing...")
            os.exit()
        else
            print("WARNING!!! This component is not required, but some functions may not working")
        end
        return nil
    end
    return component[name]
end

function update_fields(reactor)
    drac_reactor_last = drac_reactor_current
    drac_reactor_current = reactor.getReactorInfo()
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function ask(what)
    io.write(what)
    io.write(" [Y/n]:")
    local result = io.read()
    if not result then
        os.exit()
    end
    return result == 'Y' or result == 'y'
end

function printAuthor()
    print("===================================================================================")
    print("=                  Draconic reactor controller by NelttjeN                        =")
    print("=                           Program version: 1.1                                  =")
    print("= This project is open source, if you want to use it, you can find source code on =")
    print("=            https://github.com/NelttjeN/minecraft-opencomputers-lua/             =")
    print("=                 Was wrote during playing on Cristalix SkyVoid                   =")
    print("===================================================================================")
    print("")
    print("")
    print("")
end


-- main code
printAuthor()
print("Initializing...")
local dc_reactor = check_component_available("draconic_reactor", true)
local flux_gate = check_component_available("flux_gate", true)
local rfStorage = check_component_available("draconic_rf_storage", false)
flux_gate_input = nil
flux_gate_output = nil

print("drac reactor found")
print()
print()
print()
update_fields(dc_reactor)

if DEBUG then
    print_table(dc_reactor)
    print("")
    print("Drac reactor stats")
    print_table(dc_reactor.getReactorInfo())

    print("")
    print("flux gate methods")
    print_table(flux_gate)
    
    if rfStorage ~= nil then
        print("")
        print("rf_storage methods")
        print_table(rfStorage)
    end

    os.exit()
end

print("Enter 1000 rf/t (RS Hight) in input gate (shield) and 2000 rf/t (RS Hight) in output gate (energy)")
while true do
    local result = ask("Done?")

    if result then
        local gates = component.list("flux_gate")

        if tablelength(gates) ~= 2 then
            -- check only 2 gate connected
            print("Geates must be only 2")
        else
            for addr in gates do
                local gate = component.proxy(addr)
                local rate = gate.getSignalHighFlow()

                if rate == 1000 then
                    -- setting input gate 
                    flux_gate_input = gate

                elseif rate == 2000 then
                    -- setting output gate
                    flux_gate_output = gate

                end

            end
            if not flux_gate_input or not flux_gate_output then
                -- if gates not provided
                if not flux_gate_input then
                    print("Input gate not found")
                end
                if not flux_gate_output then
                    print("Output gate not found")
                end

                -- clear variables to avoid linking to one addr
                flux_gate_input = nil
                flux_gate_output = nil
            else
                -- all is ok, gates found, exiting loop
                break
            end
        end

    end

    if not result then
        os.exit()
    end
end

term.clear()
printAuthor()
print("initialization done, Starting controller thread")

-- reactor controll functions
function checkEnergy()
    if rfStorage == nil then
        return true
    end
    return component.draconic_rf_storage.getEnergyStored() / component.draconic_rf_storage.getMaxEnergyStored() < 0.02
end


function setGateFlow(gate, flow)
    gate.setSignalLowFlow(flow)
end

function perform_start_checks()
    if drac_reactor_current.maxFuelConversion < fuel_max - fuel_miss_range then
        print(string.format("Startup error: Please insert %s - %s amount of fuel, current is %s", fuel_max - fuel_miss_range, fuel_max, drac_reactor_current.maxFuelConversion))
        return false
    end
    return true
end

function reactor_offline()
    if not perform_start_checks() then
        os.exit(-1)
    end
    dc_reactor.chargeReactor()
end

function checkTemp()
    if drac_reactor_current.temperature < 7500.0 then
        setGateFlow(flux_gate_output, drac_reactor_current.generationRate * 2)
    elseif drac_reactor_current.temperature > 7500 and drac_reactor_current.temperature < 7950 then
        setGateFlow(flux_gate_output, drac_reactor_current.generationRate + 1000.0)
    elseif drac_reactor_current.temperature > 7950.0 then
        setGateFlow(flux_gate_output, drac_reactor_current.generationRate - 1000.0)
    end

    if drac_reactor_current.temperature > temp_limit then
        emergencyShutdownReactor()
        WAS_EMERGENCY = true
    end
end

function checkShield()
    local percent = drac_reactor_current.fieldStrength / drac_reactor_current.maxFieldStrength * 100

    if percent < shield_percent_down_limit then
        setGateFlow(flux_gate_input, 750000.0)
    else
        if shieldPercentDefaultLimit + 1.0 >= percent and percent >= shieldPercentDefaultLimit - 1.0 then

        else
            if shieldPercentDefaultLimit + 1 >= percent then
                setGateFlow(flux_gate_input, drac_reactor_current.fieldDrainRate * (1 + shieldPercentDefaultLimit / 100) - 1000.0)
            else
                setGateFlow(flux_gate_input, drac_reactor_current.fieldDrainRate * (1 + shieldPercentDefaultLimit / 100)  + 1000.0)
            end
        end
    end

    if percent < 1.0 then
        emergencyShutdownReactor()
        WAS_EMERGENCY = true
    end
end

function reactor_controller()
    while not DOWN do
        -- delayer
        os.sleep(sleepDelay)
        update_fields(dc_reactor)

        if drac_reactor_current.status == "charging" then
            if fastChargeReactor then
                flux_gate_input.setSignalLowFlow(fastReactorChargingRate)
            else
                flux_gate_input.setSignalLowFlow(lowReactorChargingRate)
            end
        elseif drac_reactor_current.status == "charged" then
            flux_gate_input.setSignalLowFlow(startShieldRate)
            flux_gate_output.setSignalLowFlow(startEnergyRate)
            dc_reactor.activateReactor()
        elseif drac_reactor_current.status == "online" then
            checkShield()
            checkTemp()
            if checkRFStorage then
                if not checkEnergy then
                    shutdown_reactor()
                end
            end
        elseif drac_reactor_current.status == "stopping" then
            local coef = 1.5
            if WAS_EMERGENCY then
                coef = 5
            end
            setGateFlow(flux_gate_output, drac_reactor_current.generationRate / coef)
            setGateFlow(flux_gate_input, drac_reactor_current.fieldDrainRate * coef)
        end
    end
end

function terminalController()
    while not DOWN do
        os.sleep(sleepDelay)
        term.clear()
        printAuthor()
        print("Observing not implemented yet")
    end
end

-- function shutdown_handler()
--     while true do
--     local down = io.read()
--     if not down then
--         DOWN = true
--         term.clear()
--         local result = ask("Exiting program, Shutdown reactor?")
--         if result then
--             shutdown_reactor()
--         end
--         os.exit()
--     end
--     end
-- end

function handleReactorShutdown()
    print("Stopping reactor, press ctrl + alt + c to forcequit")
    while true do
        update_fields(dc_reactor)
        if drac_reactor_current.status == "offline" then
            os.exit()
        end
        os.sleep(0.2)
    end
end

function shutdown_reactor()
    dc_reactor.stopReactor()
    handleReactorShutdown()
end

function emergencyShutdownReactor()
    dc_reactor.stopReactor()
    flux_gate_input.setSignalLowFlow(750000.0)
    flux_gate_output.setSignalLowFlow(startEnergyRate / 10)
    handleReactorShutdown()
end

-- create thread of reactor
update_fields(dc_reactor)

if drac_reactor_current.status == "offline" then
    setGateFlow(flux_gate_input, 0.0)
    setGateFlow(flux_gate_output, 0.0)

    while true do
        local result = ask("Reactor offline, activate?")
        if result then
            print("Starting reactor")
            reactor_offline()
            os.sleep(0.5)
            break
        end
    end
end

local rc_thread = thread.create(reactor_controller)
local term_thread = thread.create(terminalController)

thread.waitForAll({rc_thread, term_thread})