local version = 0.5
--  +------------------------+  --
--  |-->  INITIALIZATION  <--|  --
--  +------------------------+  --
if not turtle then
  print("This program can only be")
  print("  executed by a turtle!")
  return
end

local ARGS = {...}

-- INITIALIZING NECESSARY FUNCTIONS
local startswith = function(self, piece)
  return string.sub(self, 1, string.len(piece)) == piece
end

-- UPDATE HANDLING --
if _UD and _UD.su(version, "tqGfwDmH", {...}) then return end

-- directions in relation to initial placement (which is 0, or front)
local direction = {front=0, right=1, back=2, left=3, top=4, bottom=5 }

-- INITIAL VARIABLE SETUP --
local vars = {
  -- width and height of the quarry site
  goodside = direction.top,
  badside = direction.bottom,
  fetchside = direction.front,
  facing = direction.front,
  compareslots = {},
  freeslots = {}
}

-- READ OUT COMMAND LINE PARAMETERS --
for _,par in pairs(ARGS) do
  if startswith(par, "g:") then
    vars.goodside = direction[string.sub(par, string.len("g:")+1)]
  elseif startswith(par, "b:") then
    vars.badside = direction[string.sub(par, string.len("b:")+1)]
  elseif startswith(par, "f:") then
    vars.fetchside = direction[string.sub(par, string.len("f:")+1)]
  elseif par == "help" then
    print("The Turtle will suck items from the specified side (default: front) and drop everything that was not present in its inventory at start to the \"good\" side (default: top).")
    print("Everything else will be dropped to the \"bad\" side (default: bottom).")
    print("Usage: "..shell.getRunningProgram().." [f:{fetch side}] [g:{goodstuff side}] [b:{badstuff side}]")
    print("   For example: "..shell.getRunningProgram().." g:top b:back")
    return
  end
end

local function turnLeft()
  turtle.turnLeft()
  vars.facing = vars.facing-1
  if (vars.facing < 0) then
    vars.facing = 3
  end
end

-- drops to the designated side and returns whatever the turtle.drop returns.
local function drop( side )
  if side == direction.top then
    return turtle.dropUp()
  elseif side == direction.bottom then
    return turtle.dropDown()
  else
    while vars.facing ~= side do
      turnLeft()
    end
    return turtle.drop()
  end
end

-- sucks from the designated side and returns whatever the turtle.suck returns.
local function suck( side )
  if side == direction.top then
    return turtle.suckUp()
  elseif side == direction.bottom then
    return turtle.suckDown()
  else
    while vars.facing ~= side do
      turnLeft()
    end
    return turtle.suck()
  end
end

local function main()
  -- determine which slots will be used for comparison and which slot will be dropped from and sucked into.
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      vars.compareslots[#vars.compareslots+1] = i
    else
      vars.freeslots[#vars.freeslots+1] = i
    end
  end

  -- main loop
  while true do
    -- fetch items
    turtle.select(vars.freeslots[1])
    local sucked = suck(vars.fetchside)
    if not sucked then
      print("Waiting for items...")
    end
    while not sucked do
      sleep(3)
      sucked = suck(vars.fetchside)
      if sucked then
        print("Got some! Continuing work...")
      end
    end
    -- suck into all other free slots
    if #vars.freeslots > 1 then
      for i=2, #vars.freeslots do
        turtle.select(vars.freeslots[i])
        suck(vars.fetchside)
      end
    end
    
    -- compare and drop for each
    
    for fs=1, #vars.freeslots do
      local slot = vars.freeslots[fs]
      if turtle.getItemCount(slot) > 0 then
        turtle.select(slot)
        -- compare
        local isGood = true
        for cs=1,#vars.compareslots do
          if turtle.compareTo(vars.compareslots[cs]) then
            isGood = false
            break
          end
        end
        
        -- drop
        local side = vars.goodside
        if not isGood then
          side = vars.badside
        end
        
        drop(side)
        local dropped = (turtle.getItemCount(slot) == 0)
        if not dropped then
          print("Drop chest is full...")
        end
        while not dropped do
          sleep(3)
          drop(side)
          dropped = (turtle.getItemCount(slot) == 0)
          if dropped then
            print("Dropped items! Continuing...")
          end
        end
      end
    end
  end

end

print("Starting program")
main()