local version = 1.21
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("Error: This can only be used by a turtle!")
  return
end

local ARGS = {...}

-- UPDATE HANDLING --
if _UD and _UD.su(version, "6XL8EYXe", {...}) then return end

-- add checkvariable to turtle
-- use the variable to check if the turtle can execute the additional functions
turtle.isBetterAPI= true



---- FORCE MOVEMENTS ----

function turtle.forceForward()
  while not turtle.forward() do
    turtle.dig()
    turtle.attack()
  end
end

function turtle.forceBack()
  while not turtle.back() do
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    turtle.attack()
    turtle.turnRight()
    turtle.turnRight()
  end
end

function turtle.forceUp()
  while not turtle.up() do
    turtle.digUp()
    turtle.attackUp()
  end
end

function turtle.forceDown()
  while not turtle.down() do
    turtle.digDown()
    turtle.attackDown()
  end
end

---- ADDITIONAL MOVES ----

function turtle.left()
  turtle.turnLeft()
  local result = turtle.forward()
  turtle.turnRight()
  return result
end

function turtle.right()
  turtle.turnRight()
  local result = turtle.forward()
  turtle.turnLeft()
  return result
end

---- ADDITIONAL DIGS ----

function turtle.digLeft()
  turtle.turnLeft()
  local result = turtle.dig()
  turtle.turnRight()
  return result
end

function turtle.digRight()
  turtle.turnRight()
  local result = turtle.dig()
  turtle.turnLeft()
  return result
end

function turtle.digBack()
  turtle.turnLeft()
  turtle.turnLeft()
  local result = turtle.dig()
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.digDirection(face)
  if face == "top" then
    return turtle.digUp()
  elseif face == "bottom" then
    return turtle.digDown()
  elseif face == "left" then
    return turtle.digLeft()
  elseif face == "right" then
    return turtle.digRight()
  elseif face == "back" then
    return turtle.digBack()
  elseif face == "front" then
    return turtle.dig()
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end

---- ADDITIONAL DETECTS ----

function turtle.detectLeft()
  turtle.turnLeft()
  local result = turtle.detect()
  turtle.turnRight()
  return result
end

function turtle.detectRight()
  turtle.turnRight()
  local result = turtle.detect()
  turtle.turnLeft()
  return result
end

function turtle.detectBack()
  turtle.turnLeft()
  turtle.turnLeft()
  local result = turtle.detect()
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.detectDirection(face)
  if face == "top" then
    return turtle.detectUp()
  elseif face == "bottom" then
    return turtle.detectDown()
  elseif face == "left" then
    return turtle.detectLeft()
  elseif face == "right" then
    return turtle.detectRight()
  elseif face == "back" then
    return turtle.detectBack()
  elseif face == "front" then
    return turtle.detect()
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end

---- ADDITIONAL COMPARES ----

function turtle.compareLeft()
  turtle.turnLeft()
  local result = turtle.compare()
  turtle.turnRight()
  return result
end

function turtle.compareRight()
  turtle.turnRight()
  local result = turtle.compare()
  turtle.turnLeft()
  return result
end

function turtle.compareBack()
  turtle.turnLeft()
  turtle.turnLeft()
  local result = turtle.compare()
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.compareDirection(face)
  if face == "top" then
    return turtle.compareUp()
  elseif face == "bottom" then
    return turtle.compareDown()
  elseif face == "left" then
    return turtle.compareLeft()
  elseif face == "right" then
    return turtle.compareRight()
  elseif face == "back" then
    return turtle.compareBack()
  elseif face == "front" then
    return turtle.compare()
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end


---- ADDITIONAL PLACE----

function turtle.placeLeft(signtext)
  turtle.turnLeft()
  local result = turtle.place(signtext)
  turtle.turnRight()
  return result
end

function turtle.placeRight(signtext)
  turtle.turnRight()
  local result = turtle.place(signtext)
  turtle.turnLeft()
  return result
end

function turtle.placeBack(signtext)
  turtle.turnLeft()
  turtle.turnLeft()
  local result = turtle.place(signtext)
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.compareDirection(face, signtext)
  if face == "top" then
    return turtle.placeUp(signtext)
  elseif face == "bottom" then
    return turtle.placeDown(signtext)
  elseif face == "left" then
    return turtle.placeLeft(signtext)
  elseif face == "right" then
    return turtle.placeRight(signtext)
  elseif face == "back" then
    return turtle.placeBack(signtext)
  elseif face == "front" then
    return turtle.place(signtext)
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end


---- ADDITIONAL DROPS----

-- safety measure for turtle.drop(nil)
local function safeDrop(amount)
  if amount ~= nil then
    return turtle.drop(amount)
  else
    return turtle.drop()
  end
end

local function safeDropUp(amount)
  if amount ~= nil then
    return turtle.dropUp(amount)
  else
    return turtle.dropUp()
  end
end

local function safeDropDown(amount)
  if amount ~= nil then
    return turtle.dropDown(amount)
  else
    return turtle.dropDown()
  end
end

function turtle.dropLeft(amount)
  turtle.turnLeft()
  local result = safeDrop(amount)
  turtle.turnRight()
  return result
end

function turtle.dropRight(amount)
  turtle.turnRight()
  local result = safeDrop(amount)
  turtle.turnLeft()
  return result
end

function turtle.dropBack(amount)
  turtle.turnLeft()
  turtle.turnLeft()
  local result = safeDrop(amount)
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.dropDirection(face, amount)
  if face == "top" then
    return safeDropUp(amount)
  elseif face == "bottom" then
    return safeDropDown(amount)
  elseif face == "left" then
    return turtle.dropLeft(amount)
  elseif face == "right" then
    return turtle.dropRight(amount)
  elseif face == "back" then
    return turtle.dropBack(amount)
  elseif face == "front" then
    return turtle.safeDrop(amount)
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end


---- ADDITIONAL SUCKS----

function turtle.suckLeft()
  turtle.turnLeft()
  local result = turtle.suck()
  turtle.turnRight()
  return result
end

function turtle.suckRight()
  turtle.turnRight()
  local result = turtle.suck()
  turtle.turnLeft()
  return result
end

function turtle.suckBack()
  turtle.turnLeft()
  turtle.turnLeft()
  local result = turtle.suck()
  turtle.turnRight()
  turtle.turnRight()
  return result
end

function turtle.suckDirection(face)
  if face == "top" then
    return turtle.suckUp()
  elseif face == "bottom" then
    return turtle.suckDown()
  elseif face == "left" then
    return turtle.suckLeft()
  elseif face == "right" then
    return turtle.suckRight()
  elseif face == "back" then
    return turtle.suckBack()
  elseif face == "front" then
    return turtle.suck()
  else
    print("UNKNOWN DIRECTION: "..tostring(face).." !")
  end
end