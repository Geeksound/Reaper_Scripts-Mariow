--[[
@description Dial-EditConform
@version 1.0
@author Mariow
@license MIT
@changelog
  v1.0 (2025-06-08)
  - Initial release
@provides
  [main] Field-Recorder_Workflow/Dial-EditConform.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags dialogue editing conformation workflow timecode display items
@about
  # Dial-EditConform

  This script comes after FieldrecorderTrackmatching to automate dialogue audio conforming:
  - Creating tracks from iXML/BWF metadata,
  - Exploding multichannel items into separate mono tracks (thanks to RODILAB for this),
  - Renaming items according to their source and metadata,
  - Moving items to appropriate tracks based on take names,
  - Deleting empty tracks or tracks containing only items/takes named "DISARMED".

  Ends by deselecting all items and tracks for a clean state.

  Advanced dialogue track conforming and organizing (iXML/BWF metadata, splitting, renaming, moving, cleaning).

  This script was developed with the help of GitHub Copilot.
--]]

local r = reaper

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

-- Select all items on selected track
reaper.Main_OnCommand(40421, 0) -- Item: Select all items on selected tracks

-- ==== SCRIPT 1 :Create tracks from iXML/BWF ====
local function TrackNameExists(name)
  for i = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, i)
    local _, existingName = r.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if existingName:lower() == name:lower() then return true end
  end
  return false
end

local function ExtractTrackNames(filepath)
  local names, seen = {}, {}
  local src = r.PCM_Source_CreateFromFile(filepath)
  if not src then return names end
  local _, trackCountStr = r.GetMediaFileMetadata(src, "IXML:TRACK_LIST:TRACK_COUNT")
  local trackCount = tonumber(trackCountStr) or 0

  for i = 1, trackCount do
    local tag = (i == 1) and "IXML:TRACK_LIST:TRACK:NAME" or ("IXML:TRACK_LIST:TRACK:NAME:" .. i)
    local _, name = r.GetMediaFileMetadata(src, tag)
    if name and name ~= "" and not seen[name] then
      table.insert(names, name)
      seen[name] = true
    else
      for _, prefix in ipairs({"d", "a", "s", "g", "r"}) do
        local _, altName = r.GetMediaFileMetadata(src, prefix .. "TRK" .. i)
        if altName and altName ~= "" and not seen[altName] then
          table.insert(names, altName)
          seen[altName] = true
          break
        end
      end
    end
  end
  r.PCM_Source_Destroy(src)
  return names
end

do
  local allNames, seen = {}, {}
  for i = 0, r.CountSelectedMediaItems(0) - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local src = r.GetMediaItemTake_Source(take)
      local filepath = r.GetMediaSourceFileName(src, "")
      for _, name in ipairs(ExtractTrackNames(filepath)) do
        if not seen[name] then table.insert(allNames, name); seen[name] = true end
      end
    end
  end

  for _, name in ipairs(allNames) do
    if not TrackNameExists(name) then
      local index = r.CountTracks(0)
      r.InsertTrackAtIndex(index, true)
      r.GetSetMediaTrackInfo_String(r.GetTrack(0, index), "P_NAME", name, true)
    end
  end
end

-- ==== SCRIPT 2 : Explode with RODILAB ====
local count = r.CountSelectedMediaItems(0)
if count > 0 then
  -- Save selected items in a list
  local item_list = {}
  for i = 0, count - 1 do
    item_list[i + 1] = r.GetSelectedMediaItem(0, i)
  end

  local new_items_list = {}
  local new_tracks_list = {}
  local previous_track = nil
  local track_max_chan = 1

  local track_parnames = {
    "B_MUTE", "B_PHASE", "B_RECMON_IN_EFFECT", "I_SOLO", "I_FXEN", "I_RECARM",
    "I_RECINPUT", "I_RECMODE", "I_RECMON", "I_RECMONITEMS", "I_AUTOMODE",
    "I_FOLDERCOMPACT", "I_PERFFLAGS", "I_CUSTOMCOLOR", "I_HEIGHTOVERRIDE",
    "B_HEIGHTLOCK", "D_VOL", "D_PAN", "D_WIDTH", "D_DUALPANL", "D_DUALPANR",
    "I_PANMODE", "D_PANLAW", "B_SHOWINMIXER", "B_SHOWINTCP", "B_MAINSEND",
    "C_MAINSEND_OFFS", "C_BEATATTACHMODE", "F_MCP_FXSEND_SCALE", "F_MCP_FXPARM_SCALE",
    "F_MCP_SENDRGN_SCALE", "F_TCP_FXPARM_SCALE", "I_PLAY_OFFSET_FLAG", "D_PLAY_OFFSET"
  }

  for _, item in ipairs(item_list) do
    local take = r.GetActiveTake(item)
    if take then
      local source = r.GetMediaItemTake_Source(take)
      if r.GetMediaSourceSampleRate(source) > 0 then
        local track = r.GetMediaItem_Track(item)
        local track_id = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        local take_name = r.GetTakeName(take)
        local take_chanmode = r.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
        local source_chan = r.GetMediaSourceNumChannels(source)
        local position = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local playrate = r.GetMediaItemInfo_Value(item, "D_PLAYRATE")

        local take_chan
        if source_chan > 1 and take_chanmode < 2 then
          take_chan = source_chan
        elseif source_chan > 1 and take_chanmode > 66 then
          take_chan = 2
        else
          take_chan = 1
        end

        if take_chan > 1 then
          if track == previous_track then
            if track_max_chan < take_chan then
              for j = 0, take_chan - track_max_chan - 1 do
                r.InsertTrackAtIndex(track_id + track_max_chan + j, true)
                local _, track_name = r.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                local new_track = r.GetTrack(0, track_id + track_max_chan + j)
                table.insert(new_tracks_list, new_track)
                r.GetSetMediaTrackInfo_String(new_track, "P_NAME", track_name .. " - " .. (j + track_max_chan + 1), true)
                for _, parname in ipairs(track_parnames) do
                  r.SetMediaTrackInfo_Value(new_track, parname, r.GetMediaTrackInfo_Value(track, parname))
                end
              end
              track_max_chan = take_chan
            end
          else
            track_max_chan = take_chan
            for j = 0, take_chan - 1 do
              r.InsertTrackAtIndex(track_id + j, true)
              local _, track_name = r.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
              local new_track = r.GetTrack(0, track_id + j)
              table.insert(new_tracks_list, new_track)
              r.GetSetMediaTrackInfo_String(new_track, "P_NAME", track_name .. " - " .. (j + 1), true)
              for _, parname in ipairs(track_parnames) do
                r.SetMediaTrackInfo_Value(new_track, parname, r.GetMediaTrackInfo_Value(track, parname))
              end
            end
          end
          previous_track = track
          track_id = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

          r.Main_OnCommand(40769, 0) -- Unselect all
          r.SetMediaItemSelected(item, true)
          r.Main_OnCommand(40698, 0) -- Copy item
          r.SetEditCurPos(position, false, false)
          r.SetOnlyTrackSelected(track)

          for i = 0, take_chan - 1 do
            r.Main_OnCommand(40285, 0) -- Go to next track
            r.SetEditCurPos(position, false, false)
            r.Main_OnCommand(42398, 0) -- Paste item

            local new_item = r.GetSelectedMediaItem(0, 0)
            r.SetMediaItemInfo_Value(new_item, "D_POSITION", position)
            r.SetMediaItemInfo_Value(new_item, "D_LENGTH", length)
            r.SetMediaItemInfo_Value(new_item, "D_PLAYRATE", playrate)
            table.insert(new_items_list, new_item)
            local new_take = r.GetActiveTake(new_item)
            r.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", take_name .. " - " .. (i + 1), true)

            if take_chanmode == 0 then
              r.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", i + 3)
            elseif take_chanmode == 1 then
              if i == 0 then
                r.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", 4)
              elseif i == 1 then
                r.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", 3)
              else
                r.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", i + 3)
              end
            elseif take_chanmode > 66 then
              r.SetMediaItemTakeInfo_Value(new_take, "I_CHANMODE", (take_chanmode - 67) + i + 3)
            end
          end
        end
      end
    end
  end

  r.SelectAllMediaItems(0, false)
  for _, item in ipairs(new_items_list) do
    r.SetMediaItemSelected(item, true)
  end

  for i, track in ipairs(new_tracks_list) do
    if i == 1 then
      r.SetOnlyTrackSelected(track)
    end
    r.SetTrackSelected(track, true)
  end
end

-- ==== SCRIPT 3 : Rename from Metadata ====
local function Msg(str) r.ShowConsoleMsg(tostring(str) .. "\n") end

local function GetItemSourcePath(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return nil, nil end

  local chanmode = r.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
  if chanmode == 0 then
    r.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", 1)
    chanmode = 1
  end

  local src = r.GetMediaItemTake_Source(take)
  if chanmode >= 3 then
    return r.GetMediaSourceFileName(src, ""), math.floor(chanmode - 2)
  else
    return r.GetMediaSourceFileName(src, ""), 1
  end
end

local function CountDisarmedBefore(channelIndex, src)
  local disarmedCount = 0
  for i = 1, channelIndex - 1 do
    local tag = (i == 1)
      and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
      or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. i)
    local _, value = r.GetMediaFileMetadata(src, tag)
    if value == "DISARMED" then
      disarmedCount = disarmedCount + 1
    end
  end
  return disarmedCount
end

local function RenameItem(item)
  local path, chanIndex = GetItemSourcePath(item)
  if not path or not chanIndex then return end

  local src = r.PCM_Source_CreateFromFile(path)
  if not src then
    Msg("Impossible de charger le fichier : " .. path)
    return
  end

  local tag = "dTRK" .. chanIndex
  local _, name = r.GetMediaFileMetadata(src, tag)

  if not name or name == "" then
    local disarmTag = chanIndex == 1
      and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
      or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. chanIndex)
    local _, isDisarmed = r.GetMediaFileMetadata(src, disarmTag)

    if isDisarmed == "DISARMED" then
      name = "DISARMED"
    else
      local disarmedBefore = CountDisarmedBefore(chanIndex, src)
      local adjustedIndex = chanIndex - disarmedBefore
      local ixmlTag = adjustedIndex == 1
        and "IXML:TRACK_LIST:TRACK:NAME"
        or ("IXML:TRACK_LIST:TRACK:NAME:" .. adjustedIndex)
      local _, ixmlName = r.GetMediaFileMetadata(src, ixmlTag)
      name = (ixmlName and ixmlName ~= "") and ixmlName or "[Nom introuvable]"
    end
  end

  r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(item), "P_NAME", name, true)
  r.PCM_Source_Destroy(src)
end

do
  local itemCount = r.CountSelectedMediaItems(0)
  for i = 0, itemCount - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    RenameItem(item)
  end
end

-- ==== SCRIPT 4 :Move items to  Tracks ====
local item_count = r.CountSelectedMediaItems(0)
if item_count > 0 then
  -- Collecter items sélectionnés
  local items = {}
  for i = 0, item_count - 1 do
    items[#items + 1] = r.GetSelectedMediaItem(0, i)
  end

  -- Construire table nom_piste -> piste
  local track_map = {}
  for i = 0, r.CountTracks(0) - 1 do
    local track = r.GetTrack(0, i)
    local _, name = r.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if name ~= "" then track_map[name] = track end
  end

  -- Déplacer items vers piste correspondante au nom take
  for _, item in ipairs(items) do
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local take_name = r.GetTakeName(take)
      local target_track = track_map[take_name]
      if target_track then
        r.MoveMediaItemToTrack(item, target_track)
      end
    end
  end
end

-- ==== SCRIPT 5 :RE-Rename ====
local function GetItemSourcePath2(item)
  local take = r.GetActiveTake(item)
  if not take or r.TakeIsMIDI(take) then return nil, nil end
  local chanmode = r.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
  if chanmode == 0 then
    r.SetMediaItemTakeInfo_Value(take, "I_CHANMODE", 1)
    chanmode = 1
  end
  local src = r.GetMediaItemTake_Source(take)
  if chanmode >= 3 then
    return r.GetMediaSourceFileName(src, ""), math.floor(chanmode - 2)
  else
    return r.GetMediaSourceFileName(src, ""), nil
  end
end

local function RenameItem2(item)
  local path, chanIndex = GetItemSourcePath2(item)
  if not path or not chanIndex then return end

  local src = r.PCM_Source_CreateFromFile(path)
  if not src then
    Msg("Impossible de charger le fichier : " .. path)
    return
  end

  local _, sceneValue = r.GetMediaFileMetadata(src, "IXML:SCENE")
  local _, takeValue = r.GetMediaFileMetadata(src, "IXML:TAKE")
  local tag = "dTRK" .. chanIndex
  local _, name = r.GetMediaFileMetadata(src, tag)

  if not name or name == "" then
    local disarmTag = chanIndex == 1
      and "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
      or ("IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE:" .. chanIndex)
    local _, isDisarmed = r.GetMediaFileMetadata(src, disarmTag)

    if isDisarmed == "DISARMED" then
      name = "DISARMED"
    else
      local disarmedBefore = CountDisarmedBefore(chanIndex, src)
      local adjustedIndex = chanIndex - disarmedBefore
      local ixmlTag = adjustedIndex == 1
        and "IXML:TRACK_LIST:TRACK:NAME"
        or ("IXML:TRACK_LIST:TRACK:NAME:" .. adjustedIndex)
      local _, ixmlName = r.GetMediaFileMetadata(src, ixmlTag)
      name = (ixmlName and ixmlName ~= "") and ixmlName or "[Nom introuvable]"
    end
  end

  if sceneValue and takeValue then
    name = sceneValue .. "/" .. takeValue .. " - " .. name
  end

  r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(item), "P_NAME", name, true)
  r.PCM_Source_Destroy(src)
end

do
  local itemCount = r.CountSelectedMediaItems(0)
  for i = 0, itemCount - 1 do
    local item = r.GetSelectedMediaItem(0, i)
    RenameItem2(item)
  end
end

-- ==== SCRIPT 6 : Del unused ====
local function is_disarmed_only(track)
  local item_count = r.CountTrackMediaItems(track)
  if item_count == 0 then return true end
  for i = 0, item_count - 1 do
    local item = r.GetTrackMediaItem(track, i)
    local take = r.GetActiveTake(item)
    if take and not r.TakeIsMIDI(take) then
      local take_name = r.GetTakeName(take)
      if not take_name:upper():find("DISARMED") then
        return false
      end
    else
      return false
    end
  end
  return true
end

for i = r.CountTracks(0) - 1, 0, -1 do
  local track = r.GetTrack(0, i)
  if is_disarmed_only(track) then
    r.DeleteTrack(track)
  end
end

r.Undo_EndBlock("Processus complet : création, explosion, renommage, déplacement et nettoyage", -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

  -- Step 6: Deselect all items and tracks
reaper.Main_OnCommand(40769, 0)


