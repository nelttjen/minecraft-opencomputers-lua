local component = require("component")
local os = require("os")
local term = require("term")
local thread = require("thread")
local sides = require("sides")
local math = require("math")
local gpu = component.gpu


-- config.lua
local config = {}

config.sideInput = sides.top
config.sideCharge = sides.front
config.sideOutput = sides.bottom
config.waitTimeout = 0.1
config.chargeTimeout = 1
config.rsBlockSide = sides.right

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
        local len = #colorlib
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
    termlib.colorprintf(color, "=                          Wand Charger by NelttjeN                               =")
    termlib.colorprintf(color, "=                           Program version: 1.0                                  =")
--  termlib.colorprintf(color, "= This project is open source, if you want to use it, you can find source code on =")
--  termlib.colorprintf(color, "=            https://github.com/NelttjeN/minecraft-opencomputers-lua/             =")
    termlib.colorprintf(color, "=                 Was wrote during playing on Cristalix SkyVoid                   =")
    termlib.colorprintf(color, "===================================================================================")
    print("")
    print("")
    print("")
end

function termlib.clearTerm()
    term.clear()
end

local duplicateTimes = 0
local lastNBT = ""

local stageWaiting = 1
local stageCharging = 2
local stageCharged = 3

local transposer = component.transposer
local stage = stageWaiting
local redstone = component.redstone
redstone.setOutput(config.rsBlockSide, 0)

local stagestr = {"Wand waiting", "Wand charging", "Wand dropping"}
local stageColor = {colorlib.orange, colorlib.lime, colorlib.gold}

local currTimeount = config.waitTimeout
local arcanewb = component.container_arcaneworkbench

function checkWbWand()
    if arcanewb.getStackInSlot(11) then
        stage = stageCharging
        redstone.setOutput(config.rsBlockSide, 15)
        return true
    end

    return false
end

while true do
    local err = ""
    if stage == stageWaiting then
        if not checkWbWand() then
            currTimeount = config.waitTimeout
            local size = transposer.getInventorySize(config.sideInput)
            for k = 1, size do
                local item = transposer.getStackInSlot(config.sideInput, k)
                if item then
                    tablelib.printTable(item)
                    if item.name == "Thaumcraft:WandCasting" then
                        transposer.transferItem(config.sideInput, config.sideCharge, 1, k, 11)
                        redstone.setOutput(config.rsBlockSide, 15)
                        stage = stageCharging
                        currTimeount = config.chargeTimeout
                        break
                    end
                end
            end
        end
    elseif stage == stageCharging then
        currTimeount = config.chargeTimeout
        local item = arcanewb.getStackInSlot(11)
        if item then
            local nbthash = item.nbt_hash
            if nbthash == lastNBT then
                duplicateTimes = duplicateTimes + 1
            end
            lastNBT = nbthash
            if duplicateTimes >= 3 then
                stage = stageCharged
                currTimeount = config.waitTimeout
                stage = stageCharged
                duplicateTimes = 0
            end 
        else
            currTimeount = config.waitTimeout
            stage = stageCharged
        end
    elseif stage == stageCharged then
        local size = transposer.getInventorySize(config.sideOutput)
        for k = 1, size do
            if not transposer.getStackInSlot(config.sideOutput, k) then
                transposer.transferItem(config.sideCharge, config.sideOutput, 1, 11, k)
                redstone.setOutput(config.rsBlockSide, 0)
                stage = stageWaiting
                currTimeount = config.waitTimeout
                break
            end
        end
        if stage ~= stageWaiting then
            err = "Output inventory is full. Cannot transfer wand from charging"
        end
    end

    termlib.clearTerm()
    termlib.printAuthor(false)
    termlib.lcolorprintf(colorlib.cyan, "Current stage: ")
    termlib.colorprintf(stageColor[stage], stagestr[stage])
    if err ~= "" then
        termlib.colorprintf(colorlib.red, err)
    end

    os.sleep(currTimeount)

end