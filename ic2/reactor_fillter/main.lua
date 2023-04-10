local component = require("component")
local sides = require("sides")
local transposers = component.list("transposer")
local term = require("term")


local names = {}
names["Reactor Plating"] = 1
names["Component Heat Vent"] = 2
names["Overclocked Heat Vent"] = 3
names["Component Heat Exchanger"] = 4
names["Quad Fuel Rod (Uranium)"] = 5

local configuratuion = {
    "Quad Fuel Rod (Uranium)", "Component Heat Vent", "Overclocked Heat Vent", "Component Heat Exchanger", "Overclocked Heat Vent", "Overclocked Heat Vent", "Component Heat Vent", "Overclocked Heat Vent", "Reactor Plating",
    "Reactor Plating", "Component Heat Vent", "Overclocked Heat Vent", "Overclocked Heat Vent", "Component Heat Vent", "Overclocked Heat Vent", "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent",
    "Reactor Plating", "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent", "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent", "Overclocked Heat Vent", "Component Heat Vent",
    "Component Heat Vent", "Overclocked Heat Vent", "Overclocked Heat Vent", "Component Heat Vent", "Overclocked Heat Vent", "Overclocked Heat Vent", "Component Heat Vent", "Overclocked Heat Vent", "Reactor Plating",
    "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent", "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent", "Overclocked Heat Vent", "Quad Fuel Rod (Uranium)", "Overclocked Heat Vent",
    "Reactor Plating", "Overclocked Heat Vent", "Component Heat Vent", "Reactor Plating", "Overclocked Heat Vent", "Component Heat Vent", "Reactor Plating", "Overclocked Heat Vent", "Component Heat Vent",
}

term.clear()
local done = {}

local ok = false
local count = 1

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
