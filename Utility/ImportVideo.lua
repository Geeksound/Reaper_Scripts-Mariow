--[[
@description Import Video easilly
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-17)
  - Initial release
  - Imports video following Pro Tools–style workflow
  - Extracts audio to 'ST-Mov' track (creates if missing)
  - Reuses existing 'VIDEO' and 'ST-Mov' tracks if present
  - Mutes video items automatically
  - Groups video & audio items automatically
  - Placement options: Start of project or Edit cursor
  - Ensures video window is visible (safe, non-toggle)
@provides
  [main] Utility/ImportVideo.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags video, audio, import, group, workflow, imgui, utility
@about
  # Import Video like Pro Tools (ImGui) – Utility Version

  This REAPER script imports video items in a Pro Tools–style workflow.
  Optionally extracts audio to a dedicated track ('ST-Mov'), mutes video items,
  and automatically groups video & audio items for tight synchronization.

  Behavior:
  - Reuses existing 'VIDEO' and 'ST-Mov' tracks if they exist
  - Extracts audio only if enabled
  - Mutes video items automatically
  - Groups video & audio items PT-style
  - Placement options: Start of project or at the edit cursor
  - Opens the video window safely if hidden
--]]


local ctx = reaper.ImGui_CreateContext('Import Video (Pro Tools style)')

local opts = {
  audio_from_video = true,
  place_mode = 1
}

--------------------------------------------------
-- Ensure video window is visible (safe, non-toggle)
--------------------------------------------------
local function EnsureVideoWindowOpen()
  local cmdID = 50125 -- Video: Show/hide video window
  local state = reaper.GetToggleCommandState(cmdID)

  if state == 0 then
    reaper.Main_OnCommand(cmdID, 0)
  end
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

  -- Create VIDEO track
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_CREATETRK1'), 0)
  local video_track = reaper.GetSelectedTrack(0, 0)
  if video_track then
    reaper.GetSetMediaTrackInfo_String(video_track, 'P_NAME', 'VIDEO', true)
  end

  -- Insert video
  reaper.Main_OnCommand(40018, 0)

  -- Retrieve the last inserted video item
  local video_item
  if video_track then
    local item_count = reaper.CountTrackMediaItems(video_track)
    if item_count > 0 then
      video_item = reaper.GetTrackMediaItem(video_track, item_count - 1)
    end
  end

  local audio_track, audio_item

  -- Extract audio if Audio from video is checked
  if opts.audio_from_video and video_item then

    -- Check if a track named ST-Mov already exists
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
      local tr = reaper.GetTrack(0, i)
      local _, name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if name == "ST-Mov" then
        audio_track = tr
        break
      end
    end

    -- Create AUDIO track if it doesn't exist
    if not audio_track then
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_CREATETRK1'), 0)
      audio_track = reaper.GetSelectedTrack(0, 0)
      if audio_track then
        reaper.GetSetMediaTrackInfo_String(audio_track, 'P_NAME', 'ST-Mov', true)
      end
    end

    -- Duplicate the video item to audio track
    if audio_track then
      local new_item = reaper.AddMediaItemToTrack(audio_track)
      local take = reaper.GetActiveTake(video_item)
      if take then
        local new_take = reaper.AddTakeToMediaItem(new_item)
        local src = reaper.GetMediaItemTake_Source(take)
        reaper.SetMediaItemTake_Source(new_take, src)
        reaper.SetMediaItemInfo_Value(new_item, "D_POSITION",
          reaper.GetMediaItemInfo_Value(video_item, "D_POSITION"))
        reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH",
          reaper.GetMediaItemInfo_Value(video_item, "D_LENGTH"))

        reaper.Main_OnCommand(40421, 0) -- Glue items ignoring time selection
        audio_item = new_item
      end
    end
  end

  -- Mute all items on VIDEO track
  if video_track then
    local count = reaper.CountTrackMediaItems(video_track)
    for i = 0, count - 1 do
      local item = reaper.GetTrackMediaItem(video_track, i)
      reaper.SetMediaItemInfo_Value(item, "D_VOL", 0.0)
      reaper.SetMediaItemSelected(item, true)
    end
  end

  -- Group VIDEO and AUDIO items
  if video_item and audio_item then
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.SetMediaItemSelected(video_item, true)
    reaper.SetMediaItemSelected(audio_item, true)
    reaper.Main_OnCommand(40032, 0) -- Item: Group items
  end

  -- Ensure video window is open (safe)
  EnsureVideoWindowOpen()

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Import Video like Pro Tools', -1)
end

--------------------------------------------------
-- ImGui UI
--------------------------------------------------
local function Main()
  reaper.ImGui_SetNextWindowSize(ctx, 400, 160, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Import Video', true)

  if visible then
    --reaper.ImGui_Text(ctx, 'Video import')
    reaper.ImGui_Separator(ctx)

    local rv
    rv, opts.audio_from_video = reaper.ImGui_Checkbox(ctx, 'Audio from video', opts.audio_from_video)
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Décocher = équivalent à 'Disable Audio' sur la vidéo")
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

  if open then
    reaper.defer(Main)
  end
end

Main()

