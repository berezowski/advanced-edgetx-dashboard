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

function writeSwitch()
    currentOption.settings.switch = currentSubmenuSwitch
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function writeValue()
    currentOption.settings.target = (getValue(currentOption.settings.switch) + 1024) / 20.48
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

mainMenu = {
  optionHoverIdx = 1, -- Main select (arm, prearm, etc)
  mainMenuScroll = 0,
  pagesize = 6,
  configitems = 8,
  targetsAvailable = function() 
    return not(currentOption.settings.switch == 'Disabled' or currentOption.settings.switch == 'On')
  end,
  run = function(self)

    -- Draw Headline
    lcd.drawText(1, 1, 'CONFIG',  LEFT + INVERS)

    local linePixelHeight = 9
    local marginToHeadline = 1
    
    -- setup pagescrolling
    if self.pagesize + self.mainMenuScroll - self.optionHoverIdx < 0 then
      self.mainMenuScroll = self.mainMenuScroll + 1
    end

    if self.optionHoverIdx - self.mainMenuScroll <= 0 then
      self.mainMenuScroll = self.mainMenuScroll - 1
    end
    
    -- draw a line for each option below headline
    for idx, item in pairs(options) do
      if self.optionHoverIdx == idx then
        currentOption = item                        -- store reference to item for saving / manipulation
      end
      if idx > self.mainMenuScroll then -- skip off screen items on top, off screen on bottom is irrelevant
        local offset = (idx - self.mainMenuScroll) * linePixelHeight + marginToHeadline
        lcd.drawText(2, offset, item.name) -- draw optionname e.g. 'arm'
        
        lcd.drawText(screen.w - 48, offset, string.upper(item.settings.switch),  --draw swichname e.g. 'sa'
          self.optionHoverIdx == idx and (not self.fragment or self.fragment == 'switch') and INVERS or 0
        )
        
        local targetAvailableForIteration = not( item.settings.switch == 'Disabled' or item.settings.switch == 'On' )
        if targetAvailableForIteration then
          lcd.drawText( --draw switch target e.g. 'up'
            screen.w - 23, offset, 
            valuesMap[((self.optionHoverIdx == idx and self.editing and self.fragment == 'target') and (getValue(item.settings.switch) + 1024) / 20.48) or item.settings.target],
            self.optionHoverIdx == idx and self.editing and self.fragment == 'target' and INVERS + BLINK or
            self.optionHoverIdx == idx and (not self.fragment or self.fragment == 'target') and INVERS or 0
          )
        else
          if selected == idx then
            self.fragment = 'switch'
          end
        end
    end
  end
end
}

switchMenu = {
  submenuSwitchHoverIdx = 0,
  run = function(self)
    local headline = ' '..currentOption.name..' '--(currentOption.switchRange == minimalSwitches and ' [ On | Off ]' or ' [ Switch | On | Off ]')
    lcd.drawText(
      0, 
      1, 
      headline, 
      INVERS + LEFT
    )
      
    for idx, switch in pairs (currentOption.switchRange) do
      -- hover over saved switch upon first entering the screen
      if self.submenuSwitchHoverIdx == 0 and switch == currentOption.settings.switch then
        self.submenuSwitchHoverIdx = idx
      end

      local itemsPerRow = 3
      local row = math.ceil(idx / itemsPerRow) + 1
      local yoffset = row * 9
      if switch == 'On' or switch == 'Disabled' then -- assign special place at the bottom for 'On' and 'Disabled' Menuitems
          yoffset = currentOption.switchRange == minimalSwitches and 30 or 50
          itemsPerRow = 2
      end

      -- x
      local column = (idx-1) % itemsPerRow + 1
      local itemWidth = ( screen.w / itemsPerRow )
      local xoffset = itemWidth * column - itemWidth / 2
        
      -- draw
      lcd.drawText(xoffset, yoffset, string.upper(switch), CENTER + SMLSIZE + (self.submenuSwitchHoverIdx == idx and INVERS or 0))
      
      if self.submenuSwitchHoverIdx == idx then
        currentSubmenuSwitch = switch -- store switch for saving
      end
    end
  end
}

mainMenuSubselected = {
  editing = false,
  fragment = 'switch',
  run = function(self)
    self.optionHoverIdx = mainMenu.optionHoverIdx 
    self.mainMenuScroll = mainMenu.mainMenuScroll
    self.pagesize = mainMenu.pagesize
    self.configitems = mainMenu.configitems
    mainMenu.run(self) -- run mainmenu with settings from this scope
  end
}

local state = mainMenu
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
      state = mainMenu.targetsAvailable() and mainMenuSubselected or switchMenu
    end),
    [EVT_EXIT_BREAK] = (function() -- exit screen
      -- print('main menu event exit')
      shared.changeScreen(-1)
    end),
  },
  [mainMenuSubselected] = {
    [EVT_ROT_RIGHT] = (function() -- toggle switch/target
      -- print('main menu event rotate right')
      if mainMenuSubselected.editing and mainMenuSubselected.fragment == 'switch' then
      elseif mainMenuSubselected.editing and mainMenuSubselected.fragment == 'target' then
      else
        mainMenuSubselected.fragment = mainMenuSubselected.fragment == 'switch' and 'target' or 'switch'
      end
    end),
    [EVT_ROT_LEFT] = (function() -- toggle switch/target
      -- print('main menu event rotate left')
      if mainMenuSubselected.editing and mainMenuSubselected.fragment == 'switch' then
      elseif mainMenuSubselected.editing and mainMenuSubselected.fragment == 'target' then
      else
        mainMenuSubselected.fragment = mainMenuSubselected.fragment == 'switch' and 'target' or 'switch'
      end
    end),
    [EVT_ENTER_BREAK] = (function() -- enter switchmenu or save target
      -- print('main menu event enter')
      if not(mainMenuSubselected.editing) and mainMenuSubselected.fragment == 'switch' then
        state = switchMenu
      elseif not(mainMenuSubselected.editing) and mainMenuSubselected.fragment == 'target' then
        mainMenuSubselected.editing = true
      else
        writeValue()
        mainMenuSubselected.editing = false
      end
    end),
    [EVT_EXIT_BREAK] = (function() -- enter mainMenu
      -- print('main menu event exit')
      if mainMenuSubselected.editing then
        mainMenuSubselected.editing = false
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
    end),
    [EVT_ROT_LEFT] = (function() -- scroll to previous switch
      -- print('main menu event rotate left')
      switchMenu.submenuSwitchHoverIdx = switchMenu.submenuSwitchHoverIdx - 1
      if switchMenu.submenuSwitchHoverIdx < 1 then
        local maxItems = currentOption.switchRange == minimalSwitches and 2 or 10 -- handle overflow
        switchMenu.submenuSwitchHoverIdx = maxItems
      end
    end),
    [EVT_ENTER_BREAK] = (function() -- save switch and enter switchmenu or mainMenuSubselected
      -- print('main menu event enter')
      writeSwitch()
      switchMenu.submenuSwitchHoverIdx = 0
      state = mainMenu.targetsAvailable() and mainMenuSubselected or mainMenu
    end),
    [EVT_EXIT_BREAK] = (function() -- enter switchmenu or mainMenuSubselected
      -- print('main menu event exit')
      switchMenu.submenuSwitchHoverIdx = 0
      state = mainMenu.targetsAvailable() and mainMenuSubselected or mainMenu
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