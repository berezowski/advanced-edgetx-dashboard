-- This is the settings screen
local shared = ...
local configitems = 8
local pagesize = 6
local optionHoverIdx = 1 -- Main select (arm, prearm, etc)
local selected = 0
local subSelectionAvailable = false
local editingSwitchIdx = shared.switchSettings.arm
local subOptionHoverIdx = 0 -- Switch or value
local subSelected = 0
local currentOption
local currentSubmenuSwitch
local isSubMenu = false -- Determin if it is in the switch select menu
local submenuSwitchHoverIdx = 1
local mainMenuScroll = 0

valuesMap = { [0] = 'Up', [25] = 'Up-Mid', [50] = 'Mid', [75] = 'Mid-Dn', [100] = 'Dn' }
local minimalSwitches = { 'On', 'Disabled' }
local validSwitches = { 'sa', 'sb', 'sc', 'sd', 'se', 'sf', 'sg', 'sh', 'On', 'Disabled' }
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

function writeSwitch()
    currentOption.settings.switch = currentSubmenuSwitch
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function writeValue(func, switchValue)
    currentOption.settings.target = (getValue(currentOption.settings.switch) + 1024) / 20.48
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function resetSubSelection()
  selected = 0
  subSelected = 0
  subOptionHoverIdx = 0
end

function menuLogic(event)
    if event == EVT_ENTER_BREAK then
        if selected == 0 and not isSub and not isSubMenu then-- if it is hovering the main main menu
          selected = optionHoverIdx
          subOptionHoverIdx = 1
          if not subSelectionAvailable then
            submenuSwitchHoverIdx = 0
            isSubMenu = true
          end
        elseif selected ~= 0 and subOptionHoverIdx == 1 and not isSubMenu then
          submenuSwitchHoverIdx = 0
          isSubMenu = true
        elseif isSubMenu then
          writeSwitch(selected)
          isSubMenu = false
          if not subSelectionAvailable then
            resetSubSelection()
          end
        elseif subOptionHoverIdx == 2 and subSelected == 0 then
            subSelected = 2
        elseif subSelected == 2 then
            writeValue(selected)
            subSelected = 0
        end
    end
    if event == EVT_ROT_RIGHT then
        if selected == 0 then
            optionHoverIdx = optionHoverIdx +1
            if optionHoverIdx > configitems then
                optionHoverIdx = configitems
            end
        elseif not isSubMenu then
            subOptionHoverIdx = 2
        else -- submenu
            submenuSwitchHoverIdx = submenuSwitchHoverIdx + 1
            local maxItems = currentOption.switchRange == minimalSwitches and 2 or 10 -- handle overflow
            if submenuSwitchHoverIdx > maxItems
              then submenuSwitchHoverIdx = 1
            end
        
        end
    end
    if event == EVT_ROT_LEFT then
        if selected == 0 then -- for main selection
            optionHoverIdx = optionHoverIdx - 1
            if optionHoverIdx < 1 then
                optionHoverIdx = 1
            end
        elseif not isSubMenu and subSelected == 0 then-- for sub selection
            subOptionHoverIdx = 1
        else -- submenu
            submenuSwitchHoverIdx = submenuSwitchHoverIdx - 1
            if submenuSwitchHoverIdx < 1 then
              local maxItems = currentOption.switchRange == minimalSwitches and 2 or 10 -- handle overflow
              submenuSwitchHoverIdx = maxItems
            end
        end
    end
    if event == EVT_EXIT_BREAK then
        if not isSubMenu and selected ~= 0 and subSelected ~= 2 then
            subOptionHoverIdx = 0
            selected = 0
        elseif selected == 0 then
            shared.changeScreen(-1)
        elseif subSelected == 2 then
            subSelected = 0
        elseif isSubMenu then
            isSubMenu = false
            if not subSelectionAvailable then
              resetSubSelection()
            end
        end

    end
end


function mainMenu()
    -- Draw title
    lcd.drawText(1, 1, 'CONFIG',  LEFT + INVERS)
    
    for idx, item in pairs(options) do
      
      if pagesize + mainMenuScroll - optionHoverIdx < 0 then
        mainMenuScroll = mainMenuScroll + 1
      end
      
      if optionHoverIdx - mainMenuScroll <= 0 then
        mainMenuScroll = mainMenuScroll -1
      end
        
      if idx > mainMenuScroll then
        offset = (idx - mainMenuScroll) * 9 + 1
        lcd.drawText(2, offset, item.name)
        
        lcd.drawText(screen.w - 48, offset, string.upper(item.settings.switch), 
          optionHoverIdx == idx and (subOptionHoverIdx == 0 or subOptionHoverIdx == 1) and INVERS or 0
        )
        
        local localSubSelection = not( item.settings.switch == 'Disabled' or item.settings.switch == 'On' )
        if optionHoverIdx == idx then
          currentOption = item
          editingSwitchIdx = idx
          subSelectionAvailable = localSubSelection
        end
        
        if localSubSelection then
          lcd.drawText(
            screen.w - 23, offset, 
            valuesMap[((selected == idx and subSelected == 2) and (getValue(item.settings.switch) + 1024) / 20.48) or item.settings.target],
            optionHoverIdx == idx and subSelected == 2 and INVERS + BLINK or
            optionHoverIdx == idx and (subOptionHoverIdx == 0 or subOptionHoverIdx == 2) and INVERS or 0
          )
        else
          if selected == idx then
            subOptionHoverIdx = 1
          end
        end
    end
  end
end

function subMenu(func)
  local headline = currentOption.name..(currentOption.switchRange == minimalSwitches and ' [ On | Off ]' or ' [ Switch | On | Off ]')
  lcd.drawText(
    screen.w / 2, 
    2, 
    headline, 
    SMLSIZE + INVERS + CENTER
  )
    
  for idx, switch in pairs (
    currentOption.switchRange
  ) do
    local selected

    if submenuSwitchHoverIdx == 0 and switch == currentOption.settings.switch then
      submenuSwitchHoverIdx = idx
      selected = true
    else
      selected = idx == submenuSwitchHoverIdx
    end

    local itemsPerRow = 3
    local row = math.ceil(idx / itemsPerRow) + 1
    local yoffset = row * 9
    if switch == 'On' or switch == 'Disabled' then -- assign special place at the bottom for 'On' and 'Disabled' Menuitems
        yoffset = currentOption.switchRange == minimalSwitches and 20 or 50
        itemsPerRow = 2
    end

    -- x
    local column = (idx-1) % itemsPerRow + 1
    local itemWidth = ( screen.w / itemsPerRow )
    local xoffset = itemWidth * column - itemWidth / 2
      
    -- draw
    lcd.drawText(xoffset, yoffset, string.upper(switch), CENTER + SMLSIZE + (selected and INVERS or 0))
      if selected then
        currentSubmenuSwitch = switch
        if switch == 'Disabled' or switch == 'On' then
          subSelectionAvailable = false
        else
          subSelectionAvailable = true
        end
      end
  end
end

function shared.run(event)
    lcd.clear()
    
    menuLogic(event)

    if isSubMenu == true then
        subMenu(selected)
    else
        mainMenu()
    end
end