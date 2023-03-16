local lib = {}

lib.PRINT_DEBUG = false  -- Prints debug without starting controller programm

lib.lowReactorChargingRate = 160000.0 -- How fast reactor will charge with disabled fastCharge (RF/t), default: 160k RF/t (160000.0)
lib.fastReactorChargingRate = 10000000.0  -- How fast reactor will charge with enabled fastCharge (RF/t), default: 10m RF/t (10000000.0)
lib.fastChargeReactor = true

lib.temperatureLimit = 8500 -- Temperature limit, if above - emergency shutdown reactor, default: 8500
lib.shieldPercentEmergencyLimit = 0.5 -- Sheild percent limit, if above - emergency shutdown reactor, default: 2
lib.enableEmergencyMode = true -- Emergency mode system, default: true

lib.fastReactorHeatLimit = 7500 -- Reactor will be fast heating while temperature is under this value, default: 7500
lib.temperature = 7975 -- Reactor will keep this temperature while running
lib.shieldPercentDefaultLimit = 2  -- Reactor will handle shield in +- 1% of this value, default: 7

lib.shieldPercentHelpLimit = 1 -- Limit to activate help energy flow to reactor's shield
lib.energyHelpFlow = 750000.0 -- Help mode shield input rate, default: 750k RF/t (750000.0)
lib.enableHelpShield = true -- Should help gate provide energy to low shield

-- Detects flux gates to control reactor
lib.gateInputShieldFlowDetect = 1000.0  --gate to reactor energy injector. Must contains this RF/t as Redstone Signal High Value. required
lib.gateOutputReactorFlowDetect = 2000.0 --gate from reactor stablizer to output energy from reactor. required
lib.gateOutputCoreFlowDetect = 3000.0 --gate after output reactor gate. It will contains reactor output - shield input value. optional
lib.gateInputEmergencyShieldFlowDetect = 4000.0 --gate to help power shield to energy injector. optional

lib.offlineReactorGateChange = true -- change gates to output when reactor is stopped after using program
lib.offlineReactorGateChangeFlow = 500000.0 -- output gate flow when reactor is stopped

return lib