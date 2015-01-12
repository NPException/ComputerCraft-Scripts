local version = 1.2
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("This program can only be")
  print("  executed by a turtle!")
  return
end

-- UPDATE HANDLING --
if _UD and _UD.su(version, "HqXCPzCg", {...}) then return end

local ARGS = {...}

-- INITIALIZING NECESSARY FUNCTIONS
local startswith = function(text, piece)
  return string.sub(text, 1, string.len(piece)) == piece
end

local equals = function(text1, text2)
  return text1 == text2
end

-- possible chests
local chests = {
  "minecraft:chest",
  "minecraft:trapped_chest",
  "minecraft:ender_chest",
  "IronChest:BlockIronChest",
  "Railcraft:tile.railcraft.machine.beta",
  "Thaumcraft:blockChestHungry",
  "ThaumicExploration:boundChest",
  "EnderStorage:enderChest",
  "appliedenergistics2:tile.BlockSkyChest",
  "appliedenergistics2:tile.BlockChest",
  "witchery:refillingchest",
  "witchery:leechchest"
}

-- directions in relation to initial placement direction (which is 0, or north)
local direction = {front=0, right=1, back=2, left=3}

-- INITIAL VARIABLE SETUP --
local quarry = {
  -- width and length of the quarry site
  width = 6,
  length = 6,
  
  -- offsets
  offsetH = 0,
  
  -- maximum depth the turtle will dig down, starting at offsetH
  maxDepth = 0,
  
  -- variable which defines if fuel items should be used up when returning home.
  burnFuel = false,
  skipHoles = 0,
  
  -- depth in the curren colum
  depth = 0,
  -- x and y position on the specified grid. turtle starts one block in front of the lower left corner of the area
  posx = 1,
  posy = 1,
  facing = direction.front,
  
  -- >TODO< quarry offsets for x,y and depth

  -- list of blocks/things to ignore and a function "matches" that is used to match the things against this list
  ignore = {
    matches = equals -- function(blockname, tablevalue)
  }
}



-- READ OUT COMMAND LINE PARAMETERS --

for _,par in pairs(ARGS) do
  if startswith(par, "w:") then
    quarry.width = tonumber(string.sub(par, string.len("w:")+1))
    print("Quarry width: "..tostring(quarry.width))
    
  elseif startswith(par, "l:") then
    quarry.length = tonumber(string.sub(par, string.len("l:")+1))
    print("Quarry length: "..tostring(quarry.length))
    
  elseif startswith(par, "offh:") then
    quarry.offsetH = tonumber(string.sub(par, string.len("offh:")+1))
    print("Quarry height offset: "..tostring(quarry.offsetH))
    
  elseif startswith(par, "maxd:") then
    quarry.maxDepth = tonumber(string.sub(par, string.len("maxd:")+1))
    print("Quarry maximum depth: "..tostring(quarry.maxDepth))
    
  elseif startswith(par, "skip:") then
    quarry.skipHoles = tonumber(string.sub(par, string.len("skip:")+1))
    print("Skipping the first "..tostring(quarry.skipHoles).." holes")
    
  elseif startswith(par, "ignore:") then
    local filepath = string.sub(par, string.len("ignore:")+1)
    if fs.exists(filepath) and not fs.isDir(filepath) then
      local file = fs.open(filepath, "r")
      local ok, tbl = pcall(textutils.unserialize, file.readAll())
      file.close()
      if ok then
        quarry.ignore = tbl
        if quarry.ignore.matches == "startswith" then
          quarry.ignore.matches = startswith
        else
          quarry.ignore.matches = equals
        end
        print("Use ignore file: \""..filepath.."\"")
      else
        print("Could not unserialize table from file content: "..filepath)
        return
      end
    else
      print("Ignore file \""..filepath.."\" does not exist or is not a file!")
      return
    end
  elseif par == "burnfuel" then
    quarry.burnFuel = true
    print("Fuel item usage activated")
  end
end

term.write("Starting program ")
textutils.slowWrite("......", 2)
print(" go")


-- hold cc stuff as locals for performance
local turtle = turtle
local term = term
local colors = colors
local textutils = textutils
local sleep = sleep

--  +-------------------+  --
--  |-->  FUNCTIONS  <--|  --
--  +-------------------+  --

local function status(text, color, slowrate)
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(" Turtle-Quarry "..tostring(version))
  print("--------------------")
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

local function forward()
  while not turtle.forward() do
    turtle.select(1)
    turtle.dig()
    turtle.attack()
  end
  if quarry.facing == direction.front then
    quarry.posy = quarry.posy + 1
  elseif quarry.facing == direction.back then
    quarry.posy = quarry.posy - 1
  elseif quarry.facing == direction.right then
    quarry.posx = quarry.posx + 1
  else
    quarry.posx = quarry.posx - 1
  end
end

local function up()
  while not turtle.up() do
    turtle.select(1)
    turtle.digUp()
    turtle.attackUp()
  end
end

local function down()
  while not turtle.down() do
    turtle.select(1)
    turtle.digDown()
    turtle.attackDown()
  end
end

local function turnRight()
  turtle.turnRight()
  quarry.facing = quarry.facing+1
  if (quarry.facing > 3) then
    quarry.facing = 0
  end
end

local function turnLeft()
  turtle.turnLeft()
  quarry.facing = quarry.facing-1
  if (quarry.facing < 0) then
    quarry.facing = 3
  end
end

--[[
  Checks if fuellevel is okay
  and refuels if needed.
  Returns TRUE if fuel level is good,
  or FALSE if fuel level is low and
  nothing could get refuelled.
  Fuel check is determined by how much is needed to reach
  the given destination from the starting point (+ safety measure), times the given factor.
]]--
local function checkFuel( posx, posy, depth, factor)
  -- if fuel is needed, check if we can consume something
  if turtle.getFuelLevel() <= ((depth + posx + posy + 100) * factor) then
    status("Need fuel, trying to fill up...", colors.lightBlue)
    sleep(0.5)
    local success = false
    for i=1,16 do
      if turtle.getItemCount(i)>0 then
        turtle.select(i)
        -- lua will evaluate until one of the statements is true. meaning that it would not
        -- execute "turtle.refuel()" if it stood after the "or" once success is true.
        success = turtle.refuel() or success
      end
    end
    
    local color = colors.orange
    local text = "Refuel success: "..tostring(success)
    if success then
      color = colors.lime
      text = text.." ("..tostring(turtle.getFuelLevel())..")"
    end
    status(text, color)
    sleep(1)
    return success
  end
  return true
end

local function isInventoryEmpty()
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      return false
    end
  end
  return true
end

local function dropItemsInChest()
  local ok, data = turtle.inspect()
  if ok then
    local success = false
    for _,chestname in ipairs(chests) do
      if chestname == data.name then
        success = true
        break
      end
    end
    if success then
      status("Dropping into \""..data.name.."\"", colors.lightBlue)
      repeat
        for i=1,16 do
          if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.drop()
          end
        end
        sleep(3)
      until isInventoryEmpty()
      return
    end
  end
  status("No inventory to drop items into...", colors.orange)
  sleep(2)
end

--[[
  Makes the turtle return to the
  starting position and empty
  it's inventory in a chest if
  one is available.                   >TODO<
]]--
local function backHome( continueAfterwards )
  -- move up to depth 0
  local lastDepth = quarry.depth
  local lastFacing = quarry.facing
  while quarry.depth > 0 do
    up()
    quarry.depth = quarry.depth - 1
  end

  -- go home in x-direction
  local lastX = quarry.posx
  if lastX > 1 then
    while quarry.facing ~= direction.left do
      turnLeft()
    end
    while quarry.posx > 1 do
      forward()
    end
  end

  -- go home in y-direction
  local lastY = quarry.posy
  while quarry.facing ~= direction.back do
    turnLeft()
  end
  while quarry.posy > 1 do
    forward()
  end
  
  -- go up the offset
  if quarry.offsetH > 0 then
    for i=1,quarry.offsetH do
      up()
    end
  end

  -- refuel / drop items
  if (quarry.burnFuel) then
    status("Trying to use fuel items...", colors.lightBlue)
    for i=1,16 do
      if turtle.getItemCount(i) > 0 then
        turtle.select(i)
        turtle.refuel()
      end
    end
  end
  
  local isEmpty = isInventoryEmpty()
  if (not isEmpty) then
    local text = "Inventory full..."
    status(text,colors.lightBlue)
    sleep(1)
    dropItemsInChest() -- empty inventory guaranteed after return
    isEmpty = true
  end
  
  if continueAfterwards then
    while (not checkFuel(lastX, lastY, lastDepth, 2)) or (not isEmpty) do
      sleep(3)
      isEmpty = isInventoryEmpty()
    end
    status("Continuing work...", colors.lime)
    
    -- go down the offset
    if quarry.offsetH > 0 then
      for i=1,quarry.offsetH do
        down()
      end
    end

    -- back to hole in y-direction
    while quarry.facing ~= direction.front do
      turnLeft()
    end
    while quarry.posy < lastY do
      forward()
    end

    -- back to hole in x-direction
    if lastX > 1 then
      while quarry.facing ~= direction.right do
        turnRight()
      end
      while quarry.posx < lastX do
        forward()
      end
    end

    -- back down the hole
    while quarry.depth < lastDepth do
      down()
      quarry.depth = quarry.depth+1
    end

    while quarry.facing ~= lastFacing do
      turnLeft()
    end
  end
end



--[[
  Checks the blocks on the four adjacent 
  sides against the slots with ignored items.
  A block is mined if it does not match
  any item in the compare slots.
]]--
local function digSides()
  for i=1,4 do
    local digIt = turtle.detect()
    if digIt and (#quarry.ignore>0) then
      local success, data = turtle.inspect()
      if success then
        for _,ignoreName in ipairs(quarry.ignore) do
          if quarry.ignore.matches(data.name, ignoreName) then
            digIt = false
            break
          end
        end
      end
    end
    if digIt then
      turtle.select(1)
      turtle.dig()
      if turtle.getItemCount(16) > 0 then
        backHome(true)
      end
    end
    turnLeft()
  end  
end

--[[
  Convenience function to check for a block below before digging down
]]--
local function drill()
  if turtle.detectDown() then
    turtle.select(1)
    turtle.digDown()
    if turtle.getItemCount(16) > 0 then
      backHome(true)
    end
  end
end

--[[
  Digs down a colum, only taking the blocks
  which are not in the compare slots.
]]--
local function digColumn()
  drill()
  while true do
    if not checkFuel(quarry.posx, quarry.posy, quarry.depth, 1) then
      backHome(true)
    end
    
    if not turtle.down() then
      drill()
      if not turtle.down() then
        break
      end
    end
    quarry.depth = quarry.depth + 1
    if turtle.getItemCount(16) > 0 then
      backHome(true)
    end
    digSides()
    
    -- check if maxDepth is reached
    if (quarry.maxDepth > 0) and (quarry.depth >= quarry.maxDepth) then
      break;
    end
    
    drill()
  end

  while quarry.depth > 0 do
    up()
    quarry.depth = quarry.depth - 1
  end
  
  status("Hole at x:"..tostring(quarry.posx).." y:"..tostring(quarry.posy).." is done.", colors.lightBlue)
end

-- go forward for a number of steps, and check fuel level and inventory filling on the way
local function stepsForward(count)
  if (count > 0) then
    for i=1,count do
      if (not checkFuel(quarry.posx, quarry.posy, quarry.depth, 1)) or (turtle.getItemCount(16) > 0) then
          backHome(true)
      end
      forward()
    end
  end
end


local function calculateSkipOffset()
  local running = true
  
  local facing = direction.front
  local x = 1
  local y = 1
  
  while running do
    quarry.skipHoles = quarry.skipHoles - 1
    
    -- check for finish condition 
    if (x == quarry.width) then
      if ((facing == direction.front) and ((y + 5) > quarry.length))
          or ((facing == direction.back) and ((y-5) < 1)) then
        running = false
      end
    end
    
    if running then
      -- find path and go to next hole
      if facing == direction.front then
        if y+5 <= quarry.length then
          -- next hole in same line
          y = y+5
        elseif y+3 <= quarry.length then
          -- next hole in next column, above the current positon
          y = y+3
          x = x+1
          facing = direction.back
        else
          -- next hole in next column, below the current positon
          x = x+1
          facing = direction.back
          y = y-2
        end
      elseif facing == direction.back then
        if y-5 >= 1 then
          -- next hole in same line
          y = y-5
        elseif y-2 >= 1 then
          -- next hole in next column, below the current positon
          y = y-2
          x = x+1
          facing = direction.front
        else
          -- next hole in next column, above the current positon
          x = x+1
          facing = direction.front
          y = y+3
        end
      end
    end
    
    if (quarry.skipHoles <= 0) then
      break
    end
  end
  
  return x,y,facing,running
end


local function main()
  status("Working...", colors.lightBlue)

  local running = true
  
  -- go down the offset
  if quarry.offsetH > 0 then
    for i=1,quarry.offsetH do
      down()
    end
  end
  
  -- are there holes to skip?
  if (quarry.skipHoles > 0) then
    local x,y,facing
    x,y,facing, running = calculateSkipOffset()
    status("Skip offset: x="..tostring(x).." y="..tostring(y), colors.lightBlue)
    if running then
      stepsForward(y-1)
      turnRight()
      stepsForward(x-1)
      while (quarry.facing ~= facing) do
        turnLeft()
      end
    end
  end
  
  while running do
    
    -- remember facing
    local lastFacing = quarry.facing
    digColumn()
    -- restore facing if necessary
    while quarry.facing ~= lastFacing do
      turnLeft()
    end
    
    -- check for finish condition 
    if (quarry.posx == quarry.width) then
      if ((quarry.facing == direction.front) and ((quarry.posy + 5) > quarry.length))
          or ((quarry.facing == direction.back) and ((quarry.posy-5) < 1)) then
        running = false
      end
    end
    
    if running then
      -- find path and go to next hole
      if quarry.facing == direction.front then
        if quarry.posy+5 <= quarry.length then
          -- next hole in same line
          stepsForward(5)
        elseif quarry.posy+3 <= quarry.length then
          -- next hole in next column, above the current positon
          stepsForward(3)
          turnRight()
          stepsForward(1)
          turnRight()
        else
          -- next hole in next column, below the current positon
          turnRight()
          stepsForward(1)
          turnRight()
          stepsForward(2)
        end
        
      elseif quarry.facing == direction.back then
        if quarry.posy-5 >= 1 then
          -- next hole in same line
          stepsForward(5)
        elseif quarry.posy-2 >= 1 then
          -- next hole in next column, above the current positon
          stepsForward(2)
          turnLeft()
          stepsForward(1)
          turnLeft()
        else
          -- next hole in next column, below the current positon
          turnLeft()
          stepsForward(1)
          turnLeft()
          stepsForward(3)
        end
      else
        -- this should not happen, but in case it does, we just send the turtle home.
        running = false
      end
    end    
  end
  status("Finished quarry. Returning home...", colors.lime)
  
  backHome(false)
  status("Done.", colors.lightBlue)
end

--  +-----------------------+  --
--  |-->  program start  <--| --
--  +-----------------------+  --

main()