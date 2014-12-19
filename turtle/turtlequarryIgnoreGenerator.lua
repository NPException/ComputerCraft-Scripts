local IGNOREFILE = "igno"

local ignore = {
  matches = "equals"
}

if fs.exists(IGNOREFILE) then
  local file = fs.open(IGNOREFILE, "r")
  local content = file.readAll()
  ignore = textutils.unserialize(content)
end

local file = fs.open(IGNOREFILE,"w")

local function inspect()
  while true do
    local ok, data = turtle.inspect()
    if ok then
      local exists = false
      for _,name in ipairs(ignore) do
        if name == data.name then
          exists = true
          break
        end
      end
      if not exists then
        print(data.name)
        table.insert(ignore, data.name)
      end
    end
    sleep(0.1)
  end
end

local function waitForKey()
  os.pullEvent("key")
end

local function storeToFile()
  file.write(textutils.serialize(ignore))
  file.close()
end


--- main part
print("Place Blocks that should be ignored by")
print("the turtle quarry in front of the turtle.")
print("Press any key to stop the program and")
print("store the ignore list.")

parallel.waitForAny(inspect, waitForKey)

storeToFile()

shell.run("edit "..IGNOREFILE)
