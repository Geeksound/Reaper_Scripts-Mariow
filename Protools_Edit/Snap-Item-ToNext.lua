--[[
@description SnapItemToNext(ProTools-like)
@version 1.1
@author Mariow
@changelog
  v1.1 (2026-01-07)
- Process all selected items one by one safely
  v1.0 (2025-11-26)
  - Initial release: moves selected item so its right edge aligns with next item on the same track
@provides
  [main] Protools_Edit/Snap-Item-ToNext.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags editing, items, snapping, alignment, (protools-like)
@about
  # Move item right edge to next item’s left edge (ProTools-like)
  Moves the selected item so that its right edge snaps exactly to the
  left edge of the next item on the same track, emulating Pro Tools' 
  edge-alignment workflow.
--]]


local r = reaper

------------------------------------------------
-- 🧠 Traitement d’un item unique
------------------------------------------------

local function process_item(item)
  if not r.ValidatePtr(item, "MediaItem*") then return end
  
  local track = r.GetMediaItem_Track(item)
  if not track then return end
  
  local pos   = r.GetMediaItemInfo_Value(item, "D_POSITION")
  local len   = r.GetMediaItemInfo_Value(item, "D_LENGTH")
  local right = pos + len
  
  local itemCount = r.GetTrackNumMediaItems(track)
  local nextStart = nil
  
  for i = 0, itemCount - 1 do
    local it = r.GetTrackMediaItem(track, i)
    if it ~= item then
      local p = r.GetMediaItemInfo_Value(it, "D_POSITION")
      if p > right and (not nextStart or p < nextStart) then
        nextStart = p
      end
    end
  end
  
  if nextStart then
    local newPos = nextStart - len
    r.SetMediaItemInfo_Value(item, "D_POSITION", newPos)
  end
end


------------------------------------------------
-- 🚀 MAIN — traitement séquentiel
------------------------------------------------

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local count_sel = r.CountSelectedMediaItems(0)
if count_sel == 0 then
  r.MB("Aucun item sélectionné", "Erreur", 0)
  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("Snap items to next (sequential)", -1)
  return
end

-- Sauvegarder la sélection
local items = {}
for i = 0, count_sel - 1 do
  local item = r.GetSelectedMediaItem(0, i)
  if item then
    items[#items + 1] = item
  end
end

-- Désélectionner tous les items
r.SelectAllMediaItems(0, false)

-- Traiter les items un par un
for i = 1, #items do
  local item = items[i]
  if r.ValidatePtr(item, "MediaItem*") then
    r.SelectAllMediaItems(0, false)
    r.SetMediaItemSelected(item, true)
    process_item(item)
  end
end

-- Restaurer la sélection initiale
r.SelectAllMediaItems(0, false)
for i = 1, #items do
  if r.ValidatePtr(items[i], "MediaItem*") then
    r.SetMediaItemSelected(items[i], true)
  end
end

r.UpdateArrange()
r.PreventUIRefresh(-1)
r.Undo_EndBlock("Snap items to next (sequential)", -1)