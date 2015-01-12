local version=2.7
-- version must be first line and must be a number
-- the name of this variable does not matter, the updater just checks
-- for the equals sign in the first line.

--[[
  If you want to be able to use the
  "doAutoUpdate" function for your programs,
  just run this script before you
  run a program in which you want
  to use the method.
  
  If you run this script with the
  command line parameter "nocheck",
  it will not check for updates for
  itself
  
  The command line parameter "nocolor" will
  turn the coloring of terminal outputs off.
  You can also change this during runtime by
  setting "updater.useColoredOutput" to true or false
]]--

if not http then
    printError( "The updater requires http API" )
    printError( "Set http_enable to true in ComputerCraft.cfg" )
    return
end

local _args = {...}

updater = {
  useColoredOutput = true
}
_UD = updater

for k,v in pairs(_args) do
  if v == "nocolor" then
    updater.useColoredOutput = false
  end
end


local function startswith(text, piece)
  return string.sub(text, 1, string.len(piece)) == piece
end

local function isParamListValid(params, paramTypes)
  for i,types in ipairs(paramTypes) do
    if type(types) ~= "table" then
      types = {types}
    end
    local okay = false
    for _,typ in ipairs(types) do
      if type(params[i]) == typ then
        okay = true
      end
    end
    if not okay then
      return false
    end
  end
  return true
end


local function update( usedVersion, pastebinkeyOrURL, cArgs, silent )
  local noUpdateParam = "--noupdatecheck"
  -- first check if the update check should be skipped
  if cArgs then
    for _,v in ipairs(cArgs) do
      if v == noUpdateParam then
        return false
      end
    end
    -- insert the noupdate parameter into the command line argument table
    table.insert(cArgs, noUpdateParam)
  end
  
  local extractVersionFromLine = function(line)
    local equalsIndex = string.find(line,"=")
    if not equalsIndex then
      equalsIndex = 0
    end
    return tonumber( string.sub( line, equalsIndex+1) )
  end
  
  local useColoredOutput = updater.useColoredOutput
  
  -- do update check --
  local currentprogram = shell.getRunningProgram()
  
  if not usedVersion then
    local file = fs.open(currentprogram, "r")
    usedVersion = extractVersionFromLine(file.readLine())
    file.close()
  end
  
  if not usedVersion then
    if not silent then
      if useColoredOutput and term.isColor() then
        term.setTextColor(colors.red)
      end
      print("First line of local file does not contain a number!")
      if useColoredOutput and term.isColor() then
        term.setTextColor(colors.white)
      end
    end
    return false
  end
  
  if not silent then
    if useColoredOutput and term.isColor() then
      term.setTextColor(colors.yellow)
    end
    print("Checking version for \""..currentprogram.."\"")
    if useColoredOutput and term.isColor() then
      term.setTextColor(colors.white)
    end
  end
  
  local url
  if startswith(pastebinkeyOrURL,"http://") or startswith(pastebinkeyOrURL,"https://") then
    url = pastebinkeyOrURL
  else
    url = "http://pastebin.com/raw.php?i="..textutils.urlEncode( pastebinkeyOrURL )
  end
  
  local response = http.get(url)
  
  if response and response.getResponseCode() == 200 then
    local versionline = response.readLine()
    local content = response.readAll()
    
    local fileversion = extractVersionFromLine(versionline)
    if not fileversion then
      if not silent then
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.orange)
        end
        print("First line of online file does not contain a number!")
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.white)
        end
      end
      return false
    end
    if (fileversion > usedVersion) then
      local file = fs.open(currentprogram, "w")
      file.writeLine(versionline)
      file.write(content)
      file.close()
      
      if not silent then
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.lime)
        end
        print("Updated to "..tostring(fileversion).."!")
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.white)
        end
      end
      
      -- if this is not nil, pass the contained arguments to the updated program
      if cArgs ~= nil then
        for _,v in ipairs(cArgs) do
          currentprogram = currentprogram.." "..v
        end
        -- run updated program
        shell.run(currentprogram)
      end
      
      return true
    elseif fileversion == usedVersion and not silent then
      if useColoredOutput and term.isColor() then
        term.setTextColor(colors.lightBlue)
      end
      print("You already have the current version")
    elseif not silent then
      if useColoredOutput and term.isColor() then
        term.setTextColor(colors.magenta)
      end
      print("You even have a newer version! o.O")
    end
  elseif not silent then
    if useColoredOutput and term.isColor() then
      term.setTextColor(colors.orange)
    end
    print("Version check failed!")
  end
  
  if not silent and useColoredOutput and term.isColor() then
    term.setTextColor(colors.white)
  end
  -- nothing updated, nothing happened
  return false
end

--[[
  If a newer version than the given one
  was found, the updated program will be executed by this
  method (depending on "cArgs") and it will return true afterwards.
  Otherwise it will return false.
  So if this method returns true, you should immediately
  exit your program.
  Parameters:
    usedVersion = The version currently used. can be nil
    pastebinkey = The key on PasteBin for the file
                  of which the version should be checked
    cArgs = The command line arguments (table) of the current executing program.
            This is optional and is used to pass command line arguments
            to the udated program. If you hand in nil here, the updated program
            will NOT be automatically run. So if you want it to be run without
            parameters, just pass an empty table.
]]--
function updater.autoUpdate( par1, par2, par3, par4 )
  local params = {par1, par2, par3, par4}
  
  if isParamListValid(params,{ {"number","nil"}, "string", "table", {"boolean","nil"} }) then
    return update(par1, par2, par3, par4)
  elseif isParamListValid(params,{ "string", "table", {"boolean","nil"} }) then
    return update(nil, par1, par2, par3)
  end
end

--[[
  This method will call "updater.autoUpdate", but wraps it into a
  protected call. This prevents a program from failing
  just because an error occured during the update process.
]]--
function updater.safeAutoUpdate( par1, par2, par3, par4 )
    local useColoredOutput = updater.useColoredOutput
    -- try updating
    local success, result = pcall( updater.autoUpdate, par1, par2, par3, par4 )
    
    if not success then
      if not silent then
        if useColoredOutput and term.isColor() then
          term.setBackgroundColor(colors.black)
          term.setTextColor(colors.red)
        end
        print("Error occured in update check:")
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.orange)
        end
        print(" > "..result)
        if useColoredOutput and term.isColor() then
          term.setTextColor(colors.white)
        end
        print("Continuing in 5 seconds...")
        sleep(5)
      end
      return false
    else
      return result
    end
end


-- alias short function names
_UD.u  = _UD.autoUpdate
_UD.su = _UD.safeAutoUpdate

-- check for updates
if updater.safeAutoUpdate( "HF7vwabd", _args) then
  return
end

print("Using AutoUpdater version "..tostring(version))