-- This is the settings screen
local shared = ...
local minimalSwitches = { 'On', 'Disabled' }
local validSwitches = { 'sa', 'sb', 'sc', 'sd', 'se', 'sf', 'sg', 'sh', 'On', 'Disabled' }
valuesMap = { [0] = 'Up', [25] = 'Up-Mid', [50] = 'Mid', [75] = 'Mid-Dn', [100] = 'Dn' }
options = {
    { name = 'Arm',
      settings = shared.switchSettings.arm,
      switchRange = validSwitches
    }, { name = 'Prearm',
      settings = shared.switchSettings.prearm,
      switchRange = validSwitches
    }, { name = 'Acro',
      settings = shared.switchSettings.acro,
      switchRange = validSwitches
    }, { name = 'Angle',
      settings = shared.switchSettings.angle,
      switchRange = validSwitches
    }, { name = 'Horizon',
      settings = shared.switchSettings.horizon,
      switchRange = validSwitches
    }, { name = 'Turtlemode',
      settings = shared.switchSettings.turtle,
      switchRange = validSwitches
    }, { name = 'Pitmode',
      settings = shared.switchSettings.pitmode,
      switchRange = validSwitches
    }, { name = 'GPS',
      settings = shared.switchSettings.gps,
      switchRange = minimalSwitches
    }
}
local currentOption = options[1]
local danglingSetting = {'switch', 'target'}
function clearDanglingSettings()
    danglingSetting = {'switch', 'target'}
end
local oldMonitorValues = {}
function monitor_change(array)
  for idx, switch in pairs(array) do
    if not (switch == 'On' or switch == 'Disabled') then -- continue to next iteration
      actual = getValue(switch)
      if oldMonitorValues[idx] and oldMonitorValues[idx] ~= actual then
        oldMonitorValues = {}
        return { idx = idx, switch = switch, value = actual }
      end
      oldMonitorValues[idx] = actual -- store for future comparison
    end
  end
end

function normalizeValue(value)
  return (value + 1024) / 20.48
end

function commitSettings()
  if danglingSetting.switch then
    currentOption.settings.switch = danglingSetting.switch
  end
  if danglingSetting.target then
    currentOption.settings.target = danglingSetting.target
  end
  clearDanglingSettings()
  loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

mainMenu = {
  optionHoverIdx = 1, -- Main select (arm, prearm, etc)
  mainMenuScroll = 0,
  pagesize = 6,
  configitems = 8,
  currentSwitch = '',
  currentTartget = '',
  targetsAvailable = function() 
    return not(currentOption.settings.switch == 'Disabled' or currentOption.settings.switch == 'On')
  end,
  run = function(self)
    local linePixelHeight = 9
    local marginToHeadline = 1

    -- Draw Headline
    lcd.drawText(1, 1, 'CONFIG',  LEFT + INVERS)
    
    -- setup pagescrolling
    if self.pagesize + self.mainMenuScroll - self.optionHoverIdx < 0 then
      self.mainMenuScroll = self.mainMenuScroll + 1
    end

    if self.optionHoverIdx - self.mainMenuScroll <= 0 then
      self.mainMenuScroll = self.mainMenuScroll - 1
    end
  
    for idx, item in pairs(options) do
      if self.optionHoverIdx == idx then
        currentOption = item -- store reference to item for saving / manipulation
      end
      if idx > self.mainMenuScroll then -- skip off screen items on top, off screen on bottom is irrelevant
        ---------- THIS    xx xx --------------- e.g. 'arm'
        local offset = (idx - self.mainMenuScroll) * linePixelHeight + marginToHeadline
        lcd.drawText(2, offset, item.name) -- draw optionname e.g. 'arm'
        
        ---------- xx    THIS xx --------------- e.g. 'sa'
        lcd.drawText(screen.w - 48, offset, string.upper(item.settings.switch), --draw swichname e.g. 'sa'
          (self.optionHoverIdx == idx and state ~= mainMenuTargetSelection) and INVERS or 0
        )

        ---------- xx    xx THIS --------------- e.g. 'up'
        local targetAvailableForIteration = not( item.settings.switch == 'Disabled' or item.settings.switch == 'On' )
        if targetAvailableForIteration then

          lcd.drawText( --draw switch target e.g. 'up'
            screen.w - 33, offset, 
            valuesMap[
              (self.optionHoverIdx == idx and self.editing and state == mainMenuTargetSelection)
                and danglingSetting.target -- display dangling target if it is being edited
                or item.settings.target -- display stored value in all other cases
            ],
            (self.optionHoverIdx == idx and state ~= mainMenuSwitchSelection) and INVERS + (
              self.editing and state == mainMenuTargetSelection and BLINK or 0
            ) or 0
          )
        end
    end
  end
end
}

switchMenu = {
  submenuSwitchHoverIdx = 0,
  run = function(self)
    local headline = ' '..currentOption.name..' '

    --(currentOption.switchRange == minimalSwitches and ' [ On | Off ]' or ' [ Switch | On | Off ]')
    lcd.drawText(
      0, 
      1, 
      headline, 
      INVERS + LEFT
    )

    catch = monitor_change(currentOption.switchRange) 
    if catch then
      self.submenuSwitchHoverIdx = catch.idx
      danglingSetting.target = normalizeValue(catch.value) -- also store switch position
    end

    for idx, switch in pairs (currentOption.switchRange) do
      
      -- hover over saved switch upon first entering the screen
      if self.submenuSwitchHoverIdx == 0 and switch == currentOption.settings.switch then
        self.submenuSwitchHoverIdx = idx -- if the switch is detected by the monitor we will also take it's value,
      end

      -- y position
      local itemsPerRow = 3
      local row = math.ceil(idx / itemsPerRow) + 1
      local yoffset = row * 9
      if switch == 'On' or switch == 'Disabled' then -- assign special place at the bottom for 'On' and 'Disabled' Menuitems
          yoffset = currentOption.switchRange == minimalSwitches and 30 or 50
          itemsPerRow = 2
      end

      -- x position
      local column = (idx-1) % itemsPerRow + 1
      local itemWidth = ( screen.w / itemsPerRow )
      local xoffset = itemWidth * column - itemWidth / 2
        
      -- draw
      lcd.drawText(xoffset, yoffset, 
        -- let the user know we sometimes also store the value if it was detected by displaying it behind the switch
        string.upper(switch)..( 
          self.submenuSwitchHoverIdx == idx and (
            danglingSetting.target and ' ('..valuesMap[danglingSetting.target]..')' or ''
          ) or ''
        ), 
        CENTER + SMLSIZE + (self.submenuSwitchHoverIdx == idx and INVERS or 0))
      
      if self.submenuSwitchHoverIdx == idx then
        danglingSetting.switch = switch -- store switch for saving
      end
    end
  end
}

mainMenuSwitchSelection = {
  pagesize = mainMenu.pagesize,
  configitems = mainMenu.configitems,
  run = function(self)
    self.optionHoverIdx = mainMenu.optionHoverIdx 
    self.mainMenuScroll = mainMenu.mainMenuScroll
    mainMenu.run(self) -- run mainmenu with settings from this scope
  end
}

mainMenuTargetSelection = {
  editing = false,
  pagesize = mainMenu.pagesize,
  configitems = mainMenu.configitems,
  run = function(self)
    self.optionHoverIdx = mainMenu.optionHoverIdx 
    self.mainMenuScroll = mainMenu.mainMenuScroll
    
    -- update Target
    if self.editing then
      if not(danglingSetting.target) then
        danglingSetting.target = currentOption.settings.target
      end
      catch = monitor_change({currentOption.settings.switch})
      if catch then
        danglingSetting.target = normalizeValue(catch.value)
      end
    end
    mainMenu.run(self) -- run mainmenu with settings from this scope
  end
}

state = mainMenu
local states = {
  [mainMenu] = {
    [EVT_ROT_RIGHT] = (function() -- scroll menu down
      -- print('main menu event rotate right')
      if mainMenu.optionHoverIdx < mainMenu.configitems then
          mainMenu.optionHoverIdx = mainMenu.optionHoverIdx +1
      end
    end),
    [EVT_ROT_LEFT] = (function() -- scroll menu up
      -- print('main menu event rotate left')
      mainMenu.optionHoverIdx = mainMenu.optionHoverIdx <= 1 and 1 or mainMenu.optionHoverIdx - 1
    end),
    [EVT_ENTER_BREAK] = (function() -- enter switchmenu or mainMenuSubselected
      -- print('main menu event enter')
      state = mainMenu.targetsAvailable() and mainMenuSwitchSelection or switchMenu
    end),
    [EVT_EXIT_BREAK] = (function() -- exit screen
      -- print('main menu event exit')
      shared.changeScreen(-1)
    end),
  },
  [mainMenuSwitchSelection] = {
    [EVT_ROT_RIGHT] = (function() -- toggle switch/target
      -- print('main menu event rotate right')
      state = mainMenuTargetSelection
    end),
    [EVT_ROT_LEFT] = (function() -- toggle switch/target
      -- print('main menu event rotate left')
      state = mainMenuTargetSelection
    end),
    [EVT_ENTER_BREAK] = (function() -- enter switchmenu or save target
      -- print('main menu event enter')
      state = switchMenu
    end),
    [EVT_EXIT_BREAK] = (function() -- enter mainMenu
      -- print('main menu event exit')
      state = mainMenu
    end),
  },
  [mainMenuTargetSelection] = {
    [EVT_ROT_RIGHT] = (function() -- toggle switch/target
      -- print('main menu event rotate right')
      if mainMenuTargetSelection.editing then
        danglingSetting.target = (danglingSetting.target - 25) % 125 -- 25 : normalized step, 100: max value
      else
        state = mainMenuSwitchSelection
      end
    end),
    [EVT_ROT_LEFT] = (function() -- toggle switch/target
      -- print('main menu event rotate left')
      if mainMenuTargetSelection.editing then
        danglingSetting.target = (danglingSetting.target + 25) % 125 -- 25 : normalized step, 100: max value
      else
        state = mainMenuSwitchSelection
      end
    end),
    [EVT_ENTER_BREAK] = (function() -- enter switchmenu or save target
      -- print('main menu event enter')
      if mainMenuTargetSelection.editing then
        mainMenuTargetSelection.editing = false
        commitSettings()
        if not mainMenu.targetsAvailable() then
          state = mainMenuSwitchSelection
        end
      else
        mainMenuTargetSelection.editing = true
      end
    end),
    [EVT_EXIT_BREAK] = (function() -- enter mainMenu
      -- print('main menu event exit')
      clearDanglingSettings()
      if mainMenuTargetSelection.editing then
        mainMenuTargetSelection.editing = false
      else
        state = mainMenu
      end
    end),
  },
  [switchMenu] = {
    [EVT_ROT_RIGHT] = (function() -- scroll to next switch
      -- print('main menu event rotate right')
      switchMenu.submenuSwitchHoverIdx = switchMenu.submenuSwitchHoverIdx + 1
      local maxItems = currentOption.switchRange == minimalSwitches and 2 or 10 -- handle overflow
      if switchMenu.submenuSwitchHoverIdx > maxItems
        then switchMenu.submenuSwitchHoverIdx = 1
      end
      danglingSetting.target = nil --clear monitored target
    end),
    [EVT_ROT_LEFT] = (function() -- scroll to previous switch
      -- print('main menu event rotate left')
      switchMenu.submenuSwitchHoverIdx = switchMenu.submenuSwitchHoverIdx - 1
      if switchMenu.submenuSwitchHoverIdx < 1 then
        local maxItems = currentOption.switchRange == minimalSwitches and 2 or 10 -- handle overflow
        switchMenu.submenuSwitchHoverIdx = maxItems
      end
      danglingSetting.target = nil --clear monitored target
    end),
    [EVT_ENTER_BREAK] = (function() -- save switch and enter switchmenu or mainMenuSubselected
      -- print('main menu event enter')
      local storedTarget = danglingSetting.target ~= nil
      commitSettings()
      switchMenu.submenuSwitchHoverIdx = 0
      state = ( -- jump directly to the mainMenu if a target was detected or after the selection none are Available anymore
          not mainMenu.targetsAvailable()
          or storedTarget
        ) and mainMenu or mainMenuSwitchSelection
    end),
    [EVT_EXIT_BREAK] = (function() -- enter switchmenu or mainMenuSubselected
      -- print('main menu event exit')
      clearDanglingSettings()
      switchMenu.submenuSwitchHoverIdx = 0
      state = mainMenu.targetsAvailable() and mainMenuSwitchSelection or mainMenu
    end),
  },
}

function shared.run(event)
  
  -- handle events
  local destination = states[state][event]
  if(destination) then -- check if the state cares about the event
    destination() -- run events for state
  end

  -- draw screen
  lcd.clear()
  state:run() -- run state

end