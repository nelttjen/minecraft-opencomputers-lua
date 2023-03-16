local lib = {}
local component = require("component")
local terminal = require("utils/terminal")
local colors = require("utils/colors_hex")

function lib.checkComponentAvailable(name, quitProgram)
    if not component.isAvailable(name) then
        
        terminal.colorprintf(colors.gold, "Component %s not connected", name)

        if quitProgram then
            terminal.colorprintf(colors.red, "This component is required to program working, termintaing...")
            os.exit()
        else
            terminal.colorprintf(colors.orange, "WARNING!!! This component is not required, but some functions may not working")
        end
        return nil
    end
    return component[name]
end

return lib