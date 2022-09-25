setDefaultTab("HP")
healPanelName = "healbot"
local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('FugaBot')

  Button
    id: combos
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

]])
ui:setId(healPanelName)

if not storage[healPanelName] or not storage[healPanelName].spellTable or not storage[healPanelName].itemTable then
  storage[healPanelName] = {
    enabled = false,
    spellTable = {}
  }
end

ui.title:setOn(storage[healPanelName].enabled)
ui.title.onClick = function(widget)
storage[healPanelName].enabled = not storage[healPanelName].enabled
widget:setOn(storage[healPanelName].enabled)
end

ui.combos.onClick = function(widget)
  healWindow:show()
  healWindow:raise()
  healWindow:focus()
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
  healWindow = g_ui.createWidget('HealWindow', rootWidget)
  healWindow:hide()

  local refreshSpells = function()
    if storage[healPanelName].spellTable and #storage[healPanelName].spellTable > 0 then
      for i, child in pairs(healWindow.spells.spellList:getChildren()) do
        child:destroy()
      end
      for _, entry in pairs(storage[healPanelName].spellTable) do
        local label = g_ui.createWidget("SpellEntry", healWindow.spells.spellList)
        label.enabled:setChecked(entry.enabled)
        label.enabled.onClick = function(widget)
          entry.enabled = not entry.enabled
          label.enabled:setChecked(entry.enabled)
        end
        label.remove.onClick = function(widget)
          table.removevalue(storage[healPanelName].spellTable, entry)
          reindexTable(storage[healPanelName].spellTable)
          label:destroy()
        end
        label:setColoredText({"[", "white", entry.value.."%", "red","] ", "white", entry.spell, "teal", " [", "white", (entry.cost/1000).. "s", "orange", "]", "white"})
      end
    end
  end
  refreshSpells()


  healWindow.spells.MoveUp.onClick = function(widget)
    local input = healWindow.spells.spellList:getFocusedChild()
    if not input then return end
    local index = healWindow.spells.spellList:getChildIndex(input)
    if index < 2 then return end

    local move
    if storage[healPanelName].spellTable and #storage[healPanelName].spellTable > 0 then
      for _, entry in pairs(storage[healPanelName].spellTable) do
        if entry.index == index -1 then
          move = entry
        end
        if entry.index == index then
          move.index = index
          entry.index = index -1
        end
      end
    end
    table.sort(storage[healPanelName].spellTable, function(a,b) return a.index < b.index end)

    healWindow.spells.spellList:moveChildToIndex(input, index - 1)
    healWindow.spells.spellList:ensureChildVisible(input)
  end

  healWindow.spells.MoveDown.onClick = function(widget)
    local input = healWindow.spells.spellList:getFocusedChild()
    if not input then return end
    local index = healWindow.spells.spellList:getChildIndex(input)
    if index >= healWindow.spells.spellList:getChildCount() then return end

    local move
    local move2
    if storage[healPanelName].spellTable and #storage[healPanelName].spellTable > 0 then
      for _, entry in pairs(storage[healPanelName].spellTable) do
        if entry.index == index +1 then
          move = entry
        end
        if entry.index == index then
          move2 = entry
        end
      end
      if move and move2 then
        move.index = index
        move2.index = index + 1
      end
    end
    table.sort(storage[healPanelName].spellTable, function(a,b) return a.index < b.index end)

    healWindow.spells.spellList:moveChildToIndex(input, index + 1)
    healWindow.spells.spellList:ensureChildVisible(input)
  end

  healWindow.spells.addSpell.onClick = function(widget)
 
    local spellFormula = healWindow.spells.spellFormula:getText():trim()
    local manaCost = tonumber(healWindow.spells.manaCost:getText())
    local spellTrigger = tonumber(healWindow.spells.spellValue:getText())
    local spellSource = healWindow.spells.spellSource:getCurrentOption().text
    local spellEquasion = healWindow.spells.spellCondition:getCurrentOption().text
    local source
    local equasion

    if not manaCost then  
      warn("FugaBot: put a cooldown spell!")       
      healWindow.spells.spellFormula:setText('')
      healWindow.spells.spellValue:setText('')
      healWindow.spells.manaCost:setText('') 
      return 
    end
    if not spellTrigger then  
      warn("FugaBot: incorrect cooldown value.") 
      healWindow.spells.spellFormula:setText('')
      healWindow.spells.spellValue:setText('')
      healWindow.spells.manaCost:setText('')
      return 
    end

    if spellSource == "Health Percent" then
      source = "HP%"
    end
    if spellEquasion == "Below" then
      equasion = "<"
    end

    if spellFormula:len() > 0 then
      table.insert(storage[healPanelName].spellTable,  {totalcd = 0, index = #storage[healPanelName].spellTable+1, spell = spellFormula, sign = equasion, origin = source, cost = (manaCost * 1000), value = spellTrigger, enabled = true})
      healWindow.spells.spellFormula:setText('')
      healWindow.spells.spellValue:setText('')
      healWindow.spells.manaCost:setText('')
    end
    refreshSpells()
  end
  end

  healWindow.closeButton.onClick = function(widget)
    healWindow:hide()
  end

onTalk(function(name, level, mode, text, channelId, pos)
  if not storage[healPanelName].enabled then return end
  for _, entry in pairs(storage[healPanelName].spellTable) do
    if name ~= player:getName() then return end
      text = text:lower()
      if text == entry.spell then
      entry.totalcd = now + entry.cost
      end
    end
  end)

-- spells
macro(1, function()
  if not storage[healPanelName].enabled then return end

  for _, entry in pairs(storage[healPanelName].spellTable) do
    if entry.enabled then
      if entry.origin == "HP%" then
        if entry.sign == "<" and hppercent() <= entry.value and entry.totalcd <= now then
          say(entry.spell)
          return
        end  
      end
    end  
end  
end) 
