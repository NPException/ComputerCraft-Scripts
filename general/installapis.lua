-- folder where to put the APIs
local apiFolder = "customAPIs"

-- list of APIs
local apis= {
  {
    name="updater",
    pbcode="HF7vwabd",
    startupParams="nocheck",
    needsTurtle=false
  },
  {
    name="betterturtle",
    pbcode="6XL8EYXe",
    needsTurtle=true
  }
}

local function status(text, color, slowrate)
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(" API Installation Tool ")
  print("-----------------------")
  print()
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  term.write("--> ")
  if term.isColor() then
    if color == nil then
      color = colors.white
    end
    term.setTextColor(color)
  end
  if slowrate and (slowrate>0) then
    textutils.slowPrint(text, slowrate)
  else
    print(text)
  end
  if term.isColor() then
    term.setTextColor(colors.white)
  end
end


local function getFileContent( path )
  local result
  if fs.exists(path) then
    local file = fs.open(path, "r")
    result = file.readAll()
    file.close()
  end
  return result
end

-- main program part
local startupLines = nil
local rate = 50
local wait = 0.5



for _,api in ipairs(apis) do
  local apiFileNew = fs.combine(apiFolder, api.name)
  
  if api.needsTurtle and (not turtle) then
    status("Skipping \""..api.name.."\" (Turtle)", colors.orange, rate)
    sleep(wait)
  else
    -- ignore if the api file is allready existing
    if fs.exists(apiFileNew) then
      status("Skip: \""..api.name.."\" already exists", colors.orange, rate)
      sleep(wait)
    else
      status("Installing file: \""..api.name.."\"", colors.lightBlue, rate)
      sleep(wait)
      -- try copying api file
      if not fs.exists(apiFolder) then
        fs.makeDir(apiFolder)
      end
      
      shell.run("pastebin", "get", api.pbcode, apiFileNew)
      
      if (startupLines == nil) then
        startupLines = { "--- LOAD APIs ---" }
      end
      
      local startupline = "shell.run(\""..apiFileNew
      if api.startupParams then
        startupline = startupline.." "..api.startupParams
      end
      startupline = startupline.."\")"
      startupLines[#startupLines+1] = startupline
      
      status("File installed!", colors.lime, rate)
      sleep(wait)
    end
  end
end

local oldStartup = getFileContent("startup")
if oldStartup then
  status("Modifying startup file...", colors.lightBlue, rate)
else
  status("Creating startup file...", colors.lightBlue, rate)
end
sleep(wait)

-- merge the new startup lines in at the front of old startup file (or create a new one)
if startupLines then
  local file = fs.open("startup", "w")
  for i=1,#startupLines do
    file.writeLine(startupLines[i])
  end
  if oldStartup then
    file.writeLine()
    file.writeLine("--- BEGIN OF STARTUP ---")
    file.writeLine(oldStartup)
  end
  file.close()
end

-- print success message
status("Installation complete!", colors.lime, rate)

sleep(wait)
shell.run("reboot")