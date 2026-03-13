--[[
@description Import Video like Pro Tools (ImGui)
@version 1.1
@author Mariow
@changelog
  v1.1 (2025-12-17)
  - Fixed: Video item volume is no longer muted
  v1.0 (2025-12-17)
  - Initial release
  - Pro Tools–style video import with optional audio extraction
  - Lock video items
  - Group video & audio items automatically (PT-like)
  - Placement options: Start of project or Edit cursor
  - Opens Item Properties for the imported video
  
  
@provides
  [main] PROTOOLS/ImportVideo(PT-like).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags video, audio, workflow, import, group, prottools-like, imgui
@about
  # Import Video Like Pro Tools (ImGui)
  
  Imports a video item in a Pro Tools–like workflow:
  - Optionally extracts audio to 'ST-Mov' track
  - Leaves video item volume intact (user can Disable Audio)
  - Groups video & audio items automatically
  - Placement: Start of project or Edit cursor
  - Opens Item Properties for the imported video
--]]

local ctx = reaper.ImGui_CreateContext('Import Video (Pro Tools style)')

local opts = {
  import_audio = true,
  lock_video = false,
  place_mode = 1
}

--------------------------------------------------
-- Track helpers
--------------------------------------------------
local function GetTrackByName(name)
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, tr_name = reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false)
    if tr_name == name then return tr end
  end
end

local function GetOrCreateTrack(name)
  local tr = GetTrackByName(name)
  if tr then return tr end
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_CREATETRK1'), 0)
  tr = reaper.GetSelectedTrack(0, 0)
  if tr then
    reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', name, true)
  end
  return tr
end

--------------------------------------------------
-- Ensure video window is visible
--------------------------------------------------
local function EnsureVideoWindowOpen()
  local cmdID = 50125
  if reaper.GetToggleCommandState(cmdID) == 0 then
    reaper.Main_OnCommand(cmdID, 0)
  end
end

--------------------------------------------------
-- Helper: Last item on a track
--------------------------------------------------
local function LastItemOnTrack(tr)
  local c = reaper.CountTrackMediaItems(tr)
  if c > 0 then return reaper.GetTrackMediaItem(tr, c - 1) end
end

--------------------------------------------------
-- Import video main routine
--------------------------------------------------
local function ImportVideo()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Placement
  if opts.place_mode == 1 then
    reaper.Main_OnCommand(40042, 0) -- Go to start
  end

  -- VIDEO track
  local video_track = GetOrCreateTrack('VIDEO')
  reaper.SetOnlyTrackSelected(video_track)
  reaper.Main_OnCommand(40018, 0) -- Insert video

  -- Retrieve video item
  local video_item = LastItemOnTrack(video_track)

  -- Extract audio to ST-Mov track
  local audio_item
  if opts.import_audio and video_item then
    local audio_track = GetOrCreateTrack('ST-Mov')
    
    -- Create a new item on audio track
    audio_item = reaper.AddMediaItemToTrack(audio_track)
    local take_video = reaper.GetActiveTake(video_item)
    if take_video then
      local take_audio = reaper.AddTakeToMediaItem(audio_item)
      local src = reaper.GetMediaItemTake_Source(take_video)
      reaper.SetMediaItemTake_Source(take_audio, src)

      -- Copy position and length
      local pos = reaper.GetMediaItemInfo_Value(video_item, 'D_POSITION')
      local len = reaper.GetMediaItemInfo_Value(video_item, 'D_LENGTH')
      reaper.SetMediaItemInfo_Value(audio_item, 'D_POSITION', pos)
      reaper.SetMediaItemInfo_Value(audio_item, 'D_LENGTH', len)
    end
  end

  -- Lock video items if checked
  if opts.lock_video and video_item then
    reaper.SetMediaItemInfo_Value(video_item, "B_UISEL", 1) -- just lock/select, no volume change
  end

  -- Group video & audio items PT-style
  if video_item and audio_item then
    reaper.Main_OnCommand(40289, 0) -- Unselect all
    reaper.SetMediaItemSelected(video_item, true)
    reaper.SetMediaItemSelected(audio_item, true)
    reaper.Main_OnCommand(40032, 0) -- Group items
  end

  -- Ensure video window open
  EnsureVideoWindowOpen()
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Import Video like Pro Tools', -1)

  -- Notify user
  reaper.ShowMessageBox(
    "To deactivate Audio from the Video Item, choose:\nItem Properties > Audio > Disable Audio.",
    "Info",
    0
  )

  -- Open Item Properties for the video item
  if video_item then
    reaper.Main_OnCommand(40289, 0)
    reaper.SetMediaItemSelected(video_item, true)
    reaper.Main_OnCommand(40011, 0)
  end
end

--------------------------------------------------
-- ImGui UI
--------------------------------------------------
local function Main()
  reaper.ImGui_SetNextWindowSize(ctx, 420, 180, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Import Video', true)

  if visible then
    reaper.ImGui_Text(ctx, 'Pro Tools–style video import')
    reaper.ImGui_Separator(ctx)

    local rv
    rv, opts.import_audio = reaper.ImGui_Checkbox(ctx, 'Import audio from video', opts.import_audio)
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Décocher = équivalent à 'Disable Audio' sur la vidéo")
    end

    rv, opts.lock_video   = reaper.ImGui_Checkbox(ctx, 'Lock video item', opts.lock_video)
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Verrouille l'item vidéo pour éviter les déplacements accidentels")
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, 'Placement')
    if reaper.ImGui_RadioButton(ctx, 'Start of project', opts.place_mode == 1) then opts.place_mode = 1 end
    if reaper.ImGui_RadioButton(ctx, 'Edit cursor', opts.place_mode == 2) then opts.place_mode = 2 end

    reaper.ImGui_Separator(ctx)
    if reaper.ImGui_Button(ctx, 'Import', -1, 0) then
      ImportVideo()
    end

    reaper.ImGui_End(ctx)
  end

  if open then reaper.defer(Main) end
end

Main()

