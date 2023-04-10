local component = require("component")
local sides = require("sides")
local transposers = component.list("transposer")
local term = require("term")
local os = require("os")

local names = {}
names["Реакторная обшивка"] = 1
names["Компонентный теплоотвод"] = 2
names["Разогнанный теплоотвод"] = 3
names["Компонентный теплообменник"] = 4
names["Счетверённый топливный стержень (Уран)"] = 5

local configuratuion = {
    "Счетверённый топливный стержень (Уран)", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплообменник", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Реакторная обшивка",
    "Реакторная обшивка", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод",
    "Реакторная обшивка", "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплоотвод",
    "Компонентный теплоотвод", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Разогнанный теплоотвод", "Реакторная обшивка",
    "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод", "Разогнанный теплоотвод", "Счетверённый топливный стержень (Уран)", "Разогнанный теплоотвод",
    "Реакторная обшивка", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Реакторная обшивка", "Разогнанный теплоотвод", "Компонентный теплоотвод", "Реакторная обшивка", "Разогнанный теплоотвод", "Компонентный теплоотвод",
}

term.clear()
local done = {}

local ok = false
local count = 1
local DEBUG = false

if DEBUG then
    local transposer = component.transposer
    for k = 1, 9 do
        local item = transposer.getStackInSlot(sides.top, k)
        if item then
            print(item.label)
        end
    end
    os.exit()
end


local function contains(table, val)
    for i=1,#table do
       if table[i] == val then 
          return true
       end
    end
    return false
 end

while not ok do
    ok = true
    count = 1
    for k, v in pairs(transposers) do
        local transposer = component.proxy(k)
        local isokthis = true
        local continue = false
        if contains(done, k) then
            continue = true
        end
        if not continue then
            print(string.format("processing %d transposer (%s)", count, k))    
        end
        
        local top = transposer.getInventorySize(sides.top)
        local bottom = transposer.getInventorySize(sides.bottom)
        if top ~= 9 or bottom ~= 58 then
            print("Me interface or reactor not found. Interface must be on top, reactor on bottom")
            continue = true
        end
        
        if not continue then
            for j = 1, 54 do
                local item = transposer.getStackInSlot(sides.bottom, j)
                if not item then
                    isokthis = false
                    local label = configuratuion[j]
                    local interfaceSlot = names[label]
                    local itemInterface = transposer.getStackInSlot(sides.top, interfaceSlot)
                    if itemInterface and itemInterface.label == label then
                        transposer.transferItem(sides.top, sides.bottom, 1, interfaceSlot, j)
                    else
                        ok = false
                    end
                end
            end
        
            if isokthis then
                print("ok")
                table.insert(done, k)
            else
                print("not enought")
            end
        end
        count = count + 1
    end
end
