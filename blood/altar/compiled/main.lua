local os = require("os")
local io = require("io")
local component = require("component")
local sides = require("sides")
local math = require("math")
local term = require("term")

local transpose = component.transposer
local gpu = component.gpu


-- config.lua
local config = {}

config.slates = {
    {
        name = "Blank Slate",
        blood = 1000,
        tier = 1,
        precraft = 200
    },
    {
        name = "Reinforced Slate",
        blood = 3000,
        tier = 2,
        precraft = 200
    },
    {
        name = "Imbued Slate",
        blood = 8000,
        tier = 3,
        precraft = 200
    },
    {
        name = "Demonic Slate",
        blood = 23000,
        tier = 4,
        precraft = 200
    },
    {
        name = "Ethereal Slate",
        blood = 53000,
        tier = 5,
        precraft = 200
    }
}

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




-- term.lua
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
    termlib.colorprintf(color, "=                      Blood slate crafter by NelttjeN                            =")
    termlib.colorprintf(color, "=                           Program version: 1.0                                  =")
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



-- main.lua
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