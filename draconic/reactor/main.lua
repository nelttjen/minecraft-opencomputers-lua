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
updateShieldDelay = 7
updateShieldUpDelay = 5

local fastChargeReactor = true

-- limits
local temp_limit = 8000
local shield_percent_limit = 4.5
local energy_limit = 1000000.0

-- auto
local startShieldRate = startEnergyRate / 10
local currentGenerationRate = startEnergyRate * 1.0
local currentShieldRate = startShieldRate * 1.0
countDelay = 0
countShieldDelay = 0
countLimitDelay = 0
countShieldUpDelay = 0
sleepDelay = 0.5
DOWN = false

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
        end
        return nil
    end
    return component[name]
end

function check_component_count(name, quit_program)
    print_table(component)
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


-- main code
print("Draconic reactor controller by NelttjeN")
print("v 1.0")
print("Initializing...")
local dc_reactor = check_component_available("draconic_reactor", true)
local flux_gate = check_component_available("flux_gate", true)
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
    print_table(flux_gate)

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
print("Draconic reactor controller by NelttjeN")
print("v 1.0")
print("initialization done, Starting controller thread")
flux_gate_input.setSignalLowFlow(0.0)
flux_gate_output.setSignalLowFlow(0.0)

-- reactor controll functions
function gateUpdate()
    flux_gate_input.setSignalLowFlow(currentShieldRate)
    flux_gate_output.setSignalLowFlow(currentGenerationRate)
end

function perform_start_checks()
    if drac_reactor_current.maxFuelConversion < fuel_max - fuel_miss_range then
        print(string.format("Startup error: Please insert %s - %s amount of fuel", fuel_max - fuel_miss_range, fuel_max))
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
    if drac_reactor_current.temperature < 7500 then
        sleepDelay = 0.75
        countDelay = countDelay + 1
        if countDelay >= updateDelay then
            currentGenerationRate = currentGenerationRate * 1.01
            countDelay = 0
        end
    else
        sleepDelay = 0.5
    end
    if drac_reactor_current.temperature > 7800 then
        countLimitDelay = countLimitDelay + 1
        if countLimitDelay >= updateLimitDelay then
            currentGenerationRate = currentGenerationRate / 1.05
            countLimitDelay = 0
        end
    end
    if drac_reactor_current.temperature > temp_limit then
        emergencyShutdownReactor()
    end
end

function checkShield(min, max, skipDelay)
    local percent = drac_reactor_current.fieldStrength / drac_reactor_current.maxFieldStrength * 100
    if percent < shield_percent_limit then
        currentShieldRate = currentShieldRate * 1.5
    end
    if percent < min then
        countShieldDelay = countShieldDelay + 1
        if countShieldDelay >= updateShieldDelay or skipDelay then
            currentShieldRate = currentShieldRate + currentShieldRate / 5
            countShieldDelay = 0
        end
    elseif percent > max then
        countShieldUpDelay = countShieldUpDelay + 1
        if countShieldUpDelay >= updateShieldUpDelay or skipDelay then
            currentShieldRate = currentShieldRate - currentShieldRate / 5
            countShieldUpDelay = 0
        end
    end
end

function reactor_controller()
    print("reactor controller ready")
    while true do
        -- delayer
        os.sleep(sleepDelay)
        update_fields(dc_reactor)

        if DOWN then
            break
        end

        if drac_reactor_current.status == "charging" then
            sleepDelay = 0.5
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
            checkShield(7, 15, false)
            checkTemp()
            gateUpdate()
        elseif drac_reactor_current.status == "stopping" then
            sleepDelay = 0.1
            checkShield(10, 50, true)
            gateUpdate()
        end
    end
end

function shutdown_handler()
    while true do
    local down = io.read()
    if not down then
        DOWN = true
        term.clear()
        local result = ask("Exiting program, Shutdown reactor?")
        if result then
            shutdown_reactor()
        end
        print("Exit")
        os.exit()
    end
end

    
end

function shutdown_reactor()
    dc_reactor.stopReactor()
end

function emergencyShutdownReactor()
    dc_reactor.stopReactor()
    flux_gate_input.setSignalLowFlow(750000.0)
    flux_gate_output.setSignalLowFlow(startEnergyRate / 10)
end

-- create thread of reactor
update_fields(dc_reactor)
if drac_reactor_current.status == "offline" then
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
local sd_thread = thread.create(shutdown_handler)

thread.waitForAll({rc_thread, sd_thread})