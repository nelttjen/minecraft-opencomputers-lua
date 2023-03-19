local os = require("os")
local io = require("io")
local component = require("component")
local sides = require("sides")
local math = require("math")
local transpose = component.transposer

-- mylibs
local tablelib = require("utils/table")
local termlib = require("utils/terminal")
local componentlib = require("utils/component")
local colorlib = require("utils/colors_hex")
local config = require("config")

local altarSide = sides.back
local outputSide = sides.top
local inputSide = sides.right
local me = componentlib.checkComponentAvailable("me_controller", true)
local altar = componentlib.checkComponentAvailable("blood_altar", true)

local crafting = false
local countToCraft = 0
local countCrafted = 0

function startCraft(slate, count)
    crafting = true
    countCrafted = 0
    countToCraft = count
    while crafting do
        local item = transpose.getStackInSlot(altarSide, 1)
        if item then
            if item.label == slate.name then
                transpose.transferItem(altarSide, outputSide, 1, 1, 9)
                countCrafted = countCrafted + 1
            end
        else
            local item = transpose.getStackInSlot(inputSide, 1)
            if item.label == "Stone" then
                transpose.transferItem(inputSide, altarSide, 1, 1, 1)
            end
            os.sleep(2)
        end

        if countCrafted == count then
            crafting = false
            countCrafted = 0
            countToCraft = 0
        end
        os.sleep(2)
        printInfo()
    end
end

function printInfo()
    termlib.clearTerm()
    termlib.printAuthor(false)
    termlib.printf("Crafting: %s", crafting)
    termlib.printf("Crafted: %0.f/%0.f", countCrafted, countToCraft)

    -- in me
    local meItems = me.getItemsInNetwork()
    for i = 1, #config.slates do
        local printed = false
        for j = 1, #meItems do
            local item = meItems[j]
            local slate = config.slates[i]

            if item.label == slate.name then
                termlib.printf("%s in me: %0.f", slate.name, item.size)
                printed = true
            end
        end
        if not printed then
            termlib.printf("%s not found in me", config.slates[i].name)
        end
    end
end

while true do
    local meItems = me.getItemsInNetwork()
    local currentLp = altar.getCurrentBlood()
    local currentTier = altar.getTier()
    printInfo()

    for i = 1, #config.slates do
        for j = 1, #meItems do
            local item = meItems[j]
            local slate = config.slates[i]
            
            if item.label == slate.name and item.size < slate.precraft then
                local toCraft = slate.precraft - item.size
                local bloodToCraft = slate.blood * toCraft

                if bloodToCraft > currentLp then
                    toCraft = math.floor(currentLp / slate.blood)
                end
                
                if currentTier >= slate.tier and toCraft > 0 then
                    startCraft(slate, toCraft)
                end
            end
        end
    end
    os.sleep(0.5)
end