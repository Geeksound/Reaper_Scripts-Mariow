--[[
@description Paste PT-like compatible with Razor
@version 1.0
@author Mariow
@changelog
  v1.0 (2026-02-23)
  - Initial release
  - Reproduces a Pro Tools-style exact paste sequence
  - Automatically matches pasted item color to parent track color
  - Clears Razor Edits and resets ripple state
@provides
  [main] PROTOOLS/Geeksound_Paste(Pt-like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags paste, protools, editing, color, workflow
@about
  # Paste PT-like Exact Sequence + Track Color Match

  This script reproduces a Pro Tools-style paste workflow inside REAPER.

  Workflow:
  • Enables "Trim content behind media items when editing"
  • Executes a double paste sequence to preserve exact timing behavior
  • Moves edit cursor to item start
  • Matches pasted item color to its parent track color
  • Clears Razor Edits
  • Resets ripple editing state

  Designed for fast dialog editing and PT-style workflows.
--]]


reaper.Undo_BeginBlock()

-- 1️⃣ Options: Enable trim content behind media items when editing
reaper.Main_OnCommand(41120, 0)

-- 2️⃣ Item: Paste items/tracks
reaper.Main_OnCommand(42398, 0)

-- 3️⃣ Item navigation: Move cursor to start of items
reaper.Main_OnCommand(41173, 0)

-- 4️⃣ Edit: Undo
reaper.Main_OnCommand(40029, 0)

-- 5️⃣ Item: Paste items/tracks
reaper.Main_OnCommand(42398, 0)

-- 6️⃣ Item navigation: Move cursor to start of items
reaper.Main_OnCommand(41173, 0)

-- 🔹 Récupérer tous les items nouvellement collés
local num_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_items-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    
    -- Obtenir la couleur de la piste
    local track_color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
    
    -- Appliquer la couleur de la piste si l’item n’a pas de couleur custom
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", track_color)
end

-- 7️⃣ Razor edit: Clear all areas
reaper.Main_OnCommand(42406, 0)

-- 8️⃣ Item: Unselect (clear selection of) all items
reaper.Main_OnCommand(40289, 0)

-- 9️⃣ Set ripple editing off
reaper.Main_OnCommand(40309, 0)

reaper.UpdateArrange()
reaper.Undo_EndBlock("Paste PT-like exact sequence + match color", -1)

--[[ This script is for replacement off thie  Custom Action
Custom: Mario Paste For Razor
  Options: Enable trim content behind media items when editing
  Custom: MARIO Paste Items
    Item: Paste items/tracks
    Item navigation: Move cursor to start of items
  Custom: CUSTOM - Pro Tools Undo
    Edit: Undo
  Custom: MARIO Paste Items
    Item: Paste items/tracks
    Item navigation: Move cursor to start of items
  Razor edit: Clear all areas
  Item: Unselect (clear selection of) all items
  Set ripple editing off
  --]]


