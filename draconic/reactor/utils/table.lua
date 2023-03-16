local lib = {}

function lib.printTable(in_table)
    for k, v in pairs(in_table) do
        print(k, ' - ', v)
    end
end

function lib.tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

return lib