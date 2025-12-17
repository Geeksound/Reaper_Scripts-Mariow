--[[
@description Import Video like Pro Tools (ImGui)
@version 1.0
@author Mariow
@changelog
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
  
  A REAPER utility script to import a video item in a Pro Tools–like workflow.
  
  Features:
  - Optionally extracts audio from the video and renames track to 'ST-Mov'
  - Automatically locks video items if desired
  - Groups video and audio items like Pro Tools
  - Placement choice: Start of project or current edit cursor
  - Ensures video window is visible
  - Opens the Item Properties window for the imported video item
  
  Ideal for fast video/audio workflows, dialogue spotting, SFX or music sessions.
--]]


local ctx = reaper.ImGui_CreateContext('Import Video (Pro Tools style)')

local opts = {
  import_audio = true,
  lock_video = false,
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
    reaper.Main_OnCommand(40042, 0) -- Go to start of project
  end

  -- Create VIDEO track
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_CREATETRK1'), 0)
  local video_track = reaper.GetSelectedTrack(0, 0)
  if video_track then
    reaper.GetSetMediaTrackInfo_String(video_track, 'P_NAME', 'VIDEO', true)
  end

  -- Insert video
  reaper.Main_OnCommand(40018, 0)

  reaper.PreventUIRefresh(-1)
  EnsureVideoWindowOpen()
  reaper.PreventUIRefresh(1)

  local audio_track

  -- Extract audio
  if opts.import_audio then
    reaper.Main_OnCommand(40062, 0) -- Duplicate track

    audio_track = reaper.GetSelectedTrack(0, 0)
    if audio_track then
      reaper.GetSetMediaTrackInfo_String(audio_track, 'P_NAME', 'ST-Mov', true)
    end

    local startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if startOut == endOut then
      reaper.Main_OnCommand(40421, 0)
    else
      reaper.Main_OnCommand(40717, 0)
    end
  end

  -- Lock video items
  if opts.lock_video then
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_SEL_ALL_ITEMS_VIDEO'), 0)
    reaper.Main_OnCommand(40569, 0)
  end

  --------------------------------------------------
  -- GROUP VIDEO & AUDIO ITEMS (PT-like)
  --------------------------------------------------
  local video_item, audio_item

  if video_track then
    local vc = reaper.CountTrackMediaItems(video_track)
    if vc > 0 then
      video_item = reaper.GetTrackMediaItem(video_track, vc - 1)
    end
  end

  if audio_track then
    local ac = reaper.CountTrackMediaItems(audio_track)
    if ac > 0 then
      audio_item = reaper.GetTrackMediaItem(audio_track, ac - 1)
    end
  end

  if video_item and audio_item then
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.SetMediaItemSelected(video_item, true)
    reaper.SetMediaItemSelected(audio_item, true)
    reaper.Main_OnCommand(40032, 0) -- Item: Group items
  end

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Import Video like Pro Tools', -1)

  -- Notify user
  reaper.ShowMessageBox(
    "To deactivate Audio from the Video Item, choose:\nItem Properties > Audio > Disable Audio.",
    "Info",
    0
  )

  -- Open Item Properties for the TRUE video item
  if video_item then
    reaper.Main_OnCommand(40289, 0)
    reaper.SetMediaItemSelected(video_item, true)
    reaper.Main_OnCommand(40011, 0) -- Item Properties
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
    rv, opts.lock_video   = reaper.ImGui_Checkbox(ctx, 'Lock video item', opts.lock_video)

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, 'Placement')
    if reaper.ImGui_RadioButton(ctx, 'Start of project', opts.place_mode == 1) then
      opts.place_mode = 1
    end
    if reaper.ImGui_RadioButton(ctx, 'Edit cursor', opts.place_mode == 2) then
      opts.place_mode = 2
    end

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

