--[[
@description Cycle Track Envelope Pan → Mute → Volume(PT-like)
@version 1.0 
@author Mariow
@changelog
  v1.0 (2025-12-08)
  - Initial release
  - Cycles through: Pan → Mute → Volume (ProTools-style)
  - Shares ExtState key with forward cycling script
@provides
  [main] ProTools_Essentials/CycleEnvelope(PT ctrlCmd <-).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags envelope, cycle, reverse, prot tools, volume, mute, pan, hide
@about
  # Cycle Track Envelope Hide → Pan → Mute → Volume (reverse, PT-like)
  Reverse version of the ProTools-like cycling shortcut.
  This script:
  - Cycles **Hide → Pan → Mute → Volume**
  - Uses ExtState to stay synchronized with the forward cycle script
  - Does not handle display by itself
--]]


local section = "PT_Toggles"
local key     = "CycleVolMutePanHide" -- 0=Vol,1=Mute,2=Pan,3=Hide

-- Lire l'état actuel
local state = tonumber(reaper.GetExtState(section, key)) or 0

-- Commandes
local SHOW_VOL  = 41866
local SHOW_MUTE = 41871
local SHOW_PAN  = 41868
local HIDE_ALL  = 40889

-- Déterminer étape précédente (cycle inverse)
local next_state = (state - 1) % 4  -- modulo pour boucler de 0 à 3

-- Exécuter la commande correspondante
if next_state == 0 then
    reaper.Main_OnCommand(HIDE_ALL,0)
    reaper.Main_OnCommand(SHOW_VOL,0)
elseif next_state == 1 then
    reaper.Main_OnCommand(HIDE_ALL,0)
    reaper.Main_OnCommand(SHOW_MUTE,0)
elseif next_state == 2 then
    reaper.Main_OnCommand(HIDE_ALL,0)
    reaper.Main_OnCommand(SHOW_PAN,0)
elseif next_state == 3 then
    --reaper.Main_OnCommand(HIDE_ALL,0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_CYCLACTION_24"), 0)
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_CYCLACTION_24"), 0)
end

-- Sauvegarde de l'état
reaper.SetExtState(section,key,tostring(next_state),true)
