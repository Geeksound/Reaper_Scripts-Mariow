--[[
@description Dual Trim Sliders for Even & Odd Items
@version 1.0
@author Mariow
@changelog
  v1.0 (2026-01-08)
  - Initial release: dual sliders controlling left/right edges of selected items
    - Slider 1 affects odd items primarily
    - Slider 2 affects even items primarily
    - Actions executed according to REAPER command IDs
@provides
  [main]  Editing_TRIM/DualTrimSlider-EvenOddItems.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags items, editing, trim, slider, utility, even/odd
@about
  # Dual Trim Sliders – Even & Odd Items
  This script provides an ImGui interface with two cumulative sliders to trim
  the edges of selected items in REAPER according to their selection order:
  
  - **Slider 1** controls odd items (with complementary effect on even items)
  - **Slider 2** controls even items (with complementary effect on odd items)
  
  Features:
  - Trim left and right edges of selected items via REAPER actions
  - Pair and odd item logic based on selection order
  - Undo-friendly, selection preserved
  - Adjustable sensitivity with dead zone and step divider
  - Reset sliders button without changing any item
--]]


-----------------------------------------------------
-- User tuning
-----------------------------------------------------
local STEP_LIMIT   = 100
local DEAD_ZONE    = 2
local STEP_DIVIDER = 3

-----------------------------------------------------
-- Init
-----------------------------------------------------
local ctx = reaper.ImGui_CreateContext('Dual Trim Sliders - Even / Odd')
local slider1 = 0
local slider2 = 0

local CMD = {
  ShrinkRight = 40227,
  GrowRight   = 40228,
  GrowLeft    = 40225,
  ShrinkLeft  = 40226
}

-----------------------------------------------------
-- Selection utilities
-----------------------------------------------------
local function getSelectedItems()
  local items = {}
  local count = reaper.CountSelectedMediaItems(0)
  for i = 0, count - 1 do
    items[#items + 1] = reaper.GetSelectedMediaItem(0, i)
  end
  return items
end

local function setSelection(items)
  reaper.SelectAllMediaItems(0, false)
  for _, item in ipairs(items) do
    reaper.SetMediaItemSelected(item, true)
  end
end

-----------------------------------------------------
-- Core logic
-----------------------------------------------------
local function applySteps(delta, items, negOdd, negEven, posOdd, posEven)
  if #items == 0 then return end
  if math.abs(delta) <= DEAD_ZONE then return end

  local steps = math.floor(math.abs(delta) / STEP_DIVIDER)
  if steps == 0 then return end

  local oddItems  = {}
  local evenItems = {}

  for i, item in ipairs(items) do
    if i % 2 == 1 then
      oddItems[#oddItems + 1] = item
    else
      evenItems[#evenItems + 1] = item
    end
  end

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  for _ = 1, steps do
    if delta < 0 then
      if #oddItems > 0 then
        setSelection(oddItems)
        reaper.Main_OnCommand(negOdd, 0)
      end
      if #evenItems > 0 then
        setSelection(evenItems)
        reaper.Main_OnCommand(negEven, 0)
      end
    else
      if #oddItems > 0 then
        setSelection(oddItems)
        reaper.Main_OnCommand(posOdd, 0)
      end
      if #evenItems > 0 then
        setSelection(evenItems)
        reaper.Main_OnCommand(posEven, 0)
      end
    end
  end

  setSelection(items)

  reaper.Undo_EndBlock('Dual trim sliders item edge edit', -1)
  reaper.PreventUIRefresh(-1)
end

-----------------------------------------------------
-- GUI loop
-----------------------------------------------------
local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 340, 200, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Even / Odd Trim Sliders', true)

  if visible then
    local items = getSelectedItems()

    -- Slider 1
    reaper.ImGui_Text(ctx, 'Slider 1 (Odd primary)')
    local changed1, v1 = reaper.ImGui_SliderInt(ctx, '##slider1', slider1, -STEP_LIMIT, STEP_LIMIT)
    if changed1 then
      local delta1 = v1 - slider1
      applySteps(delta1, items,
        CMD.ShrinkRight, CMD.GrowLeft,
        CMD.GrowRight, CMD.ShrinkLeft)
      slider1 = v1
    end

    reaper.ImGui_Separator(ctx)

    -- Slider 2
    reaper.ImGui_Text(ctx, 'Slider 2 (Even primary)')
    local changed2, v2 = reaper.ImGui_SliderInt(ctx, '##slider2', slider2, -STEP_LIMIT, STEP_LIMIT)
    if changed2 then
      local delta2 = v2 - slider2
      applySteps(delta2, items,
        CMD.GrowLeft, CMD.ShrinkRight,
        CMD.ShrinkLeft, CMD.GrowRight)
      slider2 = v2
    end

    reaper.ImGui_Separator(ctx)

    -- Reset button
    if reaper.ImGui_Button(ctx, "Reset Sliders") then
      slider1 = 0
      slider2 = 0
    end

    reaper.ImGui_End(ctx)
  end
if open then
  reaper.defer(loop)
end

end

-----------------------------------------------------
-- Start
-----------------------------------------------------
reaper.defer(loop)

