-- This is the settings screen
local shared = ...
local charwidth = 5
local configitems = 8
local pagesize = 6
local hovered = 1 -- Main select (arm, prearm, etc)
local selected = 0
local subSelectionAvailable = false
local subHovered = 0 -- Switch or value
local subSelected = 0
local isSubMenu = false -- Determin if it is in the switch select menu
local subMenuHovered = 1
local possibleSwitchesSize = 10

switchNameValue = { 'arm', 'prearm', 'acro', 'angle', 'horizon', 'turtle', 'pitmode', 'gps' }

function writeSwitch(func) -- arreglar
    shared.switchSettings[switchNameValue[func]]['switch'] =  names.possibleSwitches[subMenuHovered]
    names.switches[selected] = names.possibleSwitches[subMenuHovered]
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function writeValue(func)
    shared.switchSettings[switchNameValue[func]]['target'] = (getValue(shared.switchSettings[switchNameValue[func]]['switch']) + 1024) / 20.48
    names.targets[func] = (getValue(shared.switchSettings[switchNameValue[func]]['switch']) + 1024) / 20.48
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function menuLogic(event)
    if event == EVT_ENTER_BREAK then
        if selected == 0 and not isSub and not isSubMenu then-- if it is hovering the main main menu
            selected = hovered
            subHovered = 1
            if not subSelectionAvailable then
              isSubMenu = true
            end
        elseif selected ~= 0 and subHovered == 1 and not isSubMenu then
            isSubMenu = true
        elseif isSubMenu then
            writeSwitch(selected)
            isSubMenu = false
            if not subSelectionAvailable then
              selected = 0
              subSelected = 0
              subHovered = 0
            end
        elseif subHovered == 2 and subSelected == 0 then
            subSelected = 2
        elseif subSelected == 2 then
            writeValue(selected)
            subSelected = 0
        end
    end
    if event == EVT_ROT_RIGHT then
        if selected == 0 then
            hovered = hovered +1
            if hovered > configitems then
                hovered = configitems
            end
        elseif not isSubMenu then
            subHovered = 2
        else
            subMenuHovered = subMenuHovered + 1
            if subMenuHovered > possibleSwitchesSize then
                subMenuHovered = possibleSwitchesSize
            end
        end
    end
    if event == EVT_ROT_LEFT then
        if selected == 0 then -- for main selection
            hovered = hovered - 1
            if hovered < 1 then
                hovered = 1
            end
        elseif not isSubMenu and subSelected == 0 then-- for sub selection
            subHovered = 1
        else -- For sub menu
            subMenuHovered = subMenuHovered - 1
            if subMenuHovered < 1 then
                subMenuHovered = 1
            end
        end
    end
    if event == EVT_EXIT_BREAK then
        if not isSubMenu and selected ~= 0 and subSelected ~= 2 then
            subHovered = 0
            selected = 0
        elseif selected == 0 then
            shared.changeScreen(-1)
        elseif subSelected == 2 then
            subSelected = 0
        elseif isSubMenu then
            isSubMenu = false
        end

    end
end

valuesIndex = { [0] = 'Up', [25] = 'Up-Mid', [50] = 'Mid', [75] = 'Mid-Dn', [100] = 'Dn' }

names = {
    names = { 'Arm', 'Prearm', 'Acro', 'Angle', 'Horizon', 'Turtlemode', 'Pitmode', 'GPS'},
    switches = {
        shared.switchSettings.arm.switch,
        shared.switchSettings.prearm.switch,
        shared.switchSettings.acro.switch,
        shared.switchSettings.angle.switch,
        shared.switchSettings.horizon.switch,
        shared.switchSettings.turtle.switch,
        shared.switchSettings.pitmode.switch,
        shared.switchSettings.gps.switch
    },
    reducedPossibleSwitches = { 'sa', 'sb', 'sc', 'sd', 'se', 'sf', 'sg', 'sh', 'On', 'Disabled' },
    possibleSwitches = { 'sa', 'sb', 'sc', 'sd', 'se', 'sf', 'sg', 'sh', 'On', 'Disabled' },
    targets = {
        shared.switchSettings.arm.target,
        shared.switchSettings.prearm.target,
        shared.switchSettings.acro.target,
        shared.switchSettings.angle.target,
        shared.switchSettings.horizon.target,
        shared.switchSettings.turtle.target,
        shared.switchSettings.pitmode.target,
        shared.switchSettings.gps.target
    },
}

function mainMenu()
    -- Draw title
    -- local itemcount = ''..hovered..'/'..configitems
    lcd.drawText(1, 1, 'CONFIG',  LEFT + INVERS)
    --lcd.drawText(
    --  screen.w-#itemcount, 1, 
    --  itemcount, 
    --  RIGHT)
    
    for idx, item in pairs(names.names) do
        if hovered - pagesize > 0 then
          textline = (idx + 1 - (hovered-pagesize))
        else
          textline = (idx + 1)
        end
        offset = textline * 9 - 7
        if textline > 1 then
          lcd.drawText(2, offset, item)
          
          lcd.drawText(screen.w - 48, offset, string.upper(names.switches[idx]), 
            hovered == idx and (subHovered == 0 or subHovered == 1) and INVERS or 0
          )
          
          local localSubSelection = not( names.switches[idx] == 'Disabled' or names.switches[idx] == 'On' )
          if hovered == idx then
            subSelectionAvailable = localSubSelection
          end
          
          if localSubSelection then
            lcd.drawText(
              screen.w - 23, offset, 
              valuesIndex[((selected == idx and subSelected == 2) and (getValue(names.switches[idx]) + 1024) / 20.48) or names.targets[idx]], 
              hovered == idx and subSelected == 2 and INVERS + BLINK or
              hovered == idx and (subHovered == 0 or subHovered == 2) and INVERS or 0
            )
          else
            if selected == idx then
              subHovered = 1
            end
          end
        end
    end
end

function subMenu(func)
    local headline = 'SELECT SWITCH / ON / OFF'
    lcd.drawText(
      screen.w / 2, 
      2, 
      headline, 
      SMLSIZE + INVERS + CENTER
    )

    for idx, switch in pairs (names.possibleSwitches) do
        -- y
        local itemsPerRow = 3
        local row = math.ceil(idx / itemsPerRow) + 1
        local yoffset = row * 9
        if switch == 'On' or switch == 'Disabled' then -- assign special place at the bottom for 'On' and 'Disabled' Menuitems
           yoffset = 50
           itemsPerRow = 2
        end
  
        -- x
        local column = (idx-1) % itemsPerRow + 1
        local itemWidth = ( screen.w / itemsPerRow )
        local xoffset = itemWidth * column - itemWidth / 2
        
        -- draw
        lcd.drawText(xoffset, yoffset, string.upper(switch), CENTER + SMLSIZE + (subMenuHovered == idx and INVERS or 0))
        
        if subMenuHovered == idx then
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

    -- Draw main rectangle
    --lcd.drawRectangle(0, 0, screen.w, screen.h)

    -- Draw title and rectangle
    -- lcd.drawFilledRectangle(1, 1, screen.w - 2, 9)
    if isSubMenu == true then
        subMenu(selected)
    else
        mainMenu()
    end
end