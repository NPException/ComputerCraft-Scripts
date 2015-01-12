local version = 0.7
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
 
local ARGS = {...}
 
-- UPDATE HANDLING --
if _UD and _UD.su(version, "URiX6dc3", {...}) then return end

local startswith = function(text, piece)
  return string.sub(text, 1, string.len(piece)) == piece
end


local smooth = true

local minEnergy = 100000
local maxEnergy = 1000000


--[[
  This function takes the text to put out as the first argument,
  the color to write the text in as the second argument,
  third argument is the number of characters printed per second
  and the fourth argument can hide the adjustment mode info.
  
  The text parameter may be a single string or a list of strings
    (one for each line to print)
]]--
local function status(text, color, slowrate, hideAdjustmentMode)
  local lines
  if type(text) == "table" then
    lines = text
  else
    lines = { text }
  end
  
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(" Reactor Control "..tostring(version))
  print("-----------------------")
  print()
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  term.write("--> ")
  
  for i=1,#lines do
    if i>1 then
      term.write("    ")
    end
    if term.isColor() then
      if color == nil then
        color = colors.white
      end
      term.setTextColor(color)
    end
    if slowrate and (slowrate>0) then
      textutils.slowPrint(lines[i], slowrate)
    else
      print(lines[i])
    end
  end
  
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  
  if not hideAdjustmentMode then
    print()
    print()
    term.write("Adjustment mode: ")
    if term.isColor() then
      term.setTextColor(colors.yellow)
    end
    if smooth then
      print("SMOOTH")
    else
      print("ON / OFF")
    end
    
    if term.isColor() then
      term.setTextColor(colors.lightGray)
    end
    print("Press 'a' to switch adjustment mode")
    if term.isColor() then
      term.setTextColor(colors.white)
    end
  end
end


-- READ OUT COMMAND LINE PARAMETERS --
local paramMsgs = {}
 
for _,par in pairs(ARGS) do
  if par == "static" then
    smooth = false
    table.insert(paramMsgs, "Disabled smooth adjustment")
  elseif startswith(par, "min:") then
    minEnergy = tonumber(string.sub(par, string.len("min:")+1))
    table.insert(paramMsgs, "Set minimum energy: "..minEnergy)
  elseif startswith(par, "max:") then
    maxEnergy = tonumber(string.sub(par, string.len("max:")+1))
    table.insert(paramMsgs, "Set maximum energy: "..maxEnergy)
  end
end

if #paramMsgs > 0 then
  status(paramMsgs, colors.lightBlue, 20, true)
  sleep(1)
end

local reactor = peripheral.find("BigReactors-Reactor")

if not reactor then
  print("No reactor found!")
  return
end


local function toggleSmooth()
  smooth = not smooth
  if reactor.getConnected() then
    reactor.setActive(true)
    if not smooth then
      reactor.setAllControlRodLevels(0)
    end
  end
end


status("Activating reactor for startup", colors.lightBlue)

reactor.setActive(true)
sleep(2)


-- MAIN PROGRAM --

while true do
  if not reactor.getConnected() then
    status("No valid reactor connected!", colors.red)
    sleep(5)
  else
    local energy = reactor.getEnergyStored()
    local level = (energy/10000000)*100
    
    if smooth then
      reactor.setAllControlRodLevels(level)
      
      local temperature = reactor.getFuelTemperature()
      
      local color
      if temperature >= 2000 then
        color = colors.red
      elseif temperature >=1000 then
        color = colors.orange
      elseif temperature >=500 then
        color = colors.yellow
      elseif temperature >=200 then
        color = colors.green
      else
        color = colors.lightBlue
      end
      
      status("Control Rod Level: "..tostring(math.floor(level*100)/100), color)
    else
      if energy > maxEnergy then
        reactor.setActive(false)
        status("Deactivating: Excess energy detected", colors.orange)
      elseif energy < minEnergy then
        reactor.setActive(true)
        status("Activating: Energy level below threshold", colors.green)
      else
        local lines = {
          "Status: "..(reactor.getActive() and "ACTIVE" or "INACTIVE"),
          "Energy level: "..tostring(math.floor(level)).."%"
        }
        status(lines, colors.lightBlue)
      end
    end
    
    -- check time or keypress
    local timerID = os.startTimer(5)
    local event, var
    repeat
      event, var = os.pullEventRaw()
      local isMyTimer = event == "timer" and var == timerID
      local isTerminate = event == "terminate"
      local isAPressed = event == "key" and var == keys.a
    until isMyTimer or isTerminate or isAPressed
    
    if event == "terminate" then
      if reactor.getConnected() then
        reactor.setActive(false)
      end
      status("TERMINATE: Shutting down reactor", colors.red)
      sleep(1)
      shell.run("clear")
      return -- end program
    elseif event == "key" and var == keys.a then
      toggleSmooth()
    end
  end
end