--[[
@description Toggle Link/Unlink TimelineEdit Selection (ImGui)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-12)
  - Initial release
  - Small floating ImGui window showing current link state
  - Toggle Timeline / Edit Selection link/unlink
@provides
  [main] PROTOOLS/LinkUnlink-TimelineANDEdit-SelOneKNOB.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags timeline, edit selection, link, unlink, Pro Tools, ImGui
@about
  # Pro Tools Style Timeline & Edit Selection Link Toggle (One Button)
  This script provides a small floating ImGui window with a single button 
  to display and toggle the "Link/Unlink Timeline and Edit Selection" state.

  - Button color and label indicate current state (LINKED/UNLINKED)
  - Works well in combination with LinkUnlink-TimelineANDEdit-Sel.lua
    to quickly toggle or monitor the link state.
  - Works with REAPER v6.80+ and ReaImGui extension
  - Useful for visually confirming selection behavior during editing
--]]

-- === SETTINGS ===
local window_title = "LK Timeline&Edit"
local extSection, extKey = "ProToolsLink", "LinkState"

-- === INIT ImGui ===
local ctx = reaper.ImGui_CreateContext(window_title)
local font = reaper.ImGui_CreateFont('sans-serif', 16)
reaper.ImGui_Attach(ctx, font)

-- === FUNCTIONS ===
local function GetState()
  local state = reaper.GetExtState(extSection, extKey)
  if state == "" then state = "1" end -- default: linked
  return state
end

local function SetState(newState)
  reaper.SetExtState(extSection, extKey, newState, true)
end

local function ToggleLink()
  local state = GetState()
  local newState = (state == "1") and "0" or "1"

  -- Toggle REAPER commands
  reaper.Main_OnCommand(40621, 0) -- toggle loop points link to time selection
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWCLRTIMESELCLKTOG"), 0)

  SetState(newState)
end

-- === DRAW LOOP ===
function Main()
  local visible, open = reaper.ImGui_Begin(ctx, window_title, true, reaper.ImGui_WindowFlags_AlwaysAutoResize())
  if visible then
    local state = GetState()
    local linked = (state == "1")

    -- Title
    reaper.ImGui_Text(ctx, "Timeline ↔ Edit Sel")
    reaper.ImGui_Separator(ctx)

    -- Button
    local label = linked and "🔗  LINKED" or "🔓  UNLINKED"
    local color_bg = linked and 0x33BB33FF or 0xBB3333FF
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), color_bg)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), color_bg | 0x20202000)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), color_bg)
    if reaper.ImGui_Button(ctx, label, 120, 20) then
      ToggleLink()
    end
    reaper.ImGui_PopStyleColor(ctx, 3)

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_TextWrapped(ctx, linked
      and "Sel move together."
      or "Sel act independently."
    )

    reaper.ImGui_End(ctx)
  end

if open then
    reaper.defer(Main)
else
    if ctx and reaper.ImGui_DestroyContext then
        reaper.ImGui_DestroyContext(ctx)
        ctx = nil
    end
  end  
end

reaper.defer(Main)

