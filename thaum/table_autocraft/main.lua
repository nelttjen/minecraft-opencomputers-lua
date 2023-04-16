local component = require("component")
local sides = require("sides")
local os = require("os")
local string = require("string")
local term = require('term')

local altarSide = sides.right
local wandName = "Thaumcraft:WandCasting"
local DEBUG = false

local stageWand = 0
local stageBreakAltar = 1 
local stageWaitTable = 2
local stageBreakTable = 3
local stagePlaceAltar = 4
local stageStr = {'wand checking', 'breaking altar', 'table waiting', 'breaking table', 'altar placing'}

local currStage = stageWand

-- redstone
local altarBreakRsAddr = '677a8324'
local altarPlaceRsAddr = '9e64b397'
local tableBreakRsAddr = '4972d52e'
local tablePlaceRsAddr = '394e828b'
local wandMoveRSAddr   = '6c3e1870'

local addreses = {altarBreakRsAddr, altarPlaceRsAddr, tableBreakRsAddr, tablePlaceRsAddr, wandMoveRSAddr}

function getTransposers()
    local tab = {}
    local keys = {'altar_break', 'altar_place', 'table_break', 'table_place', 'wand_move'}
    for k, v in pairs(component.list()) do
        if v == "transposer" then
            local trans = component.proxy(k)
            local item = trans.getStackInSlot(sides.top, 1)
            if item ~= nil then
                if item.name == "minecraft:stone" then
                    tab['altar_check'] = trans
                end
            end
        elseif v == "redstone" then
            local subbed = string.sub(k, 1, 8)
            print(subbed)
            for k2, v2 in pairs(addreses) do
                if subbed == v2 then
                    print("sub string match")
                    tab[keys[k2]] = component.proxy(k)
                end
            end
        end
    end
    print(tab['table_break'])
    return tab
end

local transposers = getTransposers()

if DEBUG then
    print(transposers['altar_check'].getStackInSlot(altarSide, 1).name)
    os.exit()    
end

function emit(rsio, timeout)
    rsio.setOutput(sides.bottom, 15)
    os.sleep(timeout)
    rsio.setOutput(sides.bottom, 0)
end

while true do
    if currStage == stageWand then
        local item = transposers['altar_check'].getStackInSlot(altarSide, 1)
        if item == nil then
            local breakalt = transposers['altar_break']
            emit(breakalt, 2)
            currStage = stageBreakAltar
        end
    elseif currStage == stageBreakAltar then
        local placetab = transposers['table_place']
        emit(placetab, 2)
        currStage = stageWaitTable
    elseif currStage == stageWaitTable then
        for k, v in pairs(component.list()) do
            if v == 'container_arcaneworkbench' then
                local breaktab = transposers['table_break']
                emit(breaktab, 2)
                currStage = stageBreakTable
                break
            end
        end 
    elseif currStage == stageBreakTable then
        local placealt = transposers['altar_place']
        emit(placealt, 3)
        currStage = stagePlaceAltar
    elseif currStage == stagePlaceAltar then
        local wandMove = transposers['wand_move']
        emit(wandMove, 3)
        currStage = stageWand
    end
    term.clear()
    print('Curr stage: ', stageStr[currStage+1])
    os.sleep(0.5)
end