-- @description Add prefix to the NAME of Selected Item
-- @author Mariow
-- @version 1.0
-- @changelog Initial Relaeas
-- @provides
--   [main] Utility/prefix-to-name.lua
-- @link https://github.com/Geeksound/Reaper_Scripts-Mariow
-- @tags name,items,editing
-- @about
--   # prefix-to-name
--   Contextual add prefix to the NAME of Selected Item in Reaper 7.0.
--   This script was developed with the help of GitHub Copilot.

-- Ask for the Suffix to add
local retval, suffix = reaper.GetUserInputs("Add prefix to Name", 1, "Prefix to add :", "")
if not retval then return end

reaper.Undo_BeginBlock()

-- Parcours des items sélectionnés
local num_items = reaper.CountSelectedMediaItems(0)
for i = 0, num_items - 1 do
local item = reaper.GetSelectedMediaItem(0, i)
local take = reaper.GetActiveTake(item)
if take and not reaper.TakeIsMIDI(take) then
local name_ok, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
if name_ok then
local new_name = suffix .. name
reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
end
end
end

reaper.Undo_EndBlock("Add prefix to the NAME of Selected Item", -1)
reaper.UpdateArrange()
