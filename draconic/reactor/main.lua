local component = require("component")
local os = require("os")
local term = require("term")
local thread = require("thread")

-- libs
local config = require("config")
local componentlib = require("utils/component")
local termlib = require("utils/terminal")
local colorlib = require("utils/colors_hex")
local debuglib = require("utils/debugger")
local monitoringlib = require("controller/reactor_monitoring")
local controllib = require("controller/reactor_controller")

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