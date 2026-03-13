--[[
@description PasteToFill
@version 1.0
@author Mariow/Benmrx
@changelog
  v1.0 (2025-11-12)
  - Initial release
  - Creates Razor Edits from the Time Selection on selected tracks
  - Executes full MRX "Paste To Fill" logic within a single Undo Block
  - Simplified, organized, and commented version based on MRX PasteToFill v1.1 (Ben Kersten)
@provides
  [main] PROTOOLS/Paste-ToFill.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags razor, paste, fill, editing, items, envelopes
@about
  # Time Selection → Razor Edits → MRX Paste To Fill
  Reproduces the behavior of Pro Tools' "Paste to Fill" feature inside REAPER.
  The script creates Razor Edits matching the current Time Selection on all
  selected tracks, then runs the full MRX Paste To Fill process in one step.
  Designed for fast, precise editing workflows.
--]]

-- Robustly get time selection start/end (avoid nil issues)
local function get_time_selection()
  local a,b,c,d,e = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local ts_start, ts_end
  local candidates = {a,b,c,d,e}
  for i=1,#candidates do
    if type(candidates[i]) == "number" then
      if not ts_start then ts_start = candidates[i]
      elseif not ts_end then ts_end = candidates[i]; break
      end
    end
  end
  return ts_start, ts_end
end

local ts_start, ts_end = get_time_selection()
if not ts_start or not ts_end or ts_end <= ts_start then
  reaper.ShowMessageBox("Invalid time selection.\nPlease make a valid time selection (start < end) and try again.", "Error", 0)
  return
end

local selTrCount = reaper.CountSelectedTracks(0)
if selTrCount == 0 then
  reaper.ShowMessageBox("No track selected.\nPlease select the tracks to fill and try again.", "Error", 0)
  return
end

-- Create razor edits on selected tracks corresponding to time selection
local function create_razor_edits_on_selected_tracks(startt, endt)
  for i = 0, selTrCount - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    local retval, area = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", "", false)
    local add = string.format(' %.20f %.20f ""', startt, endt)
    local newarea
    if area == nil or area == "" then
      newarea = string.format('%.20f %.20f ""', startt, endt)
    else
      newarea = area .. add
    end
    reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", newarea, true)
  end
end

-- Now the MRX --- Paste To Fill script (embedded)
-- Version/credits: v1.1 (05/23/21) benmrx (Ben Kersten) — full script follows
-- User options (same as original MRX script)
local leaveCursorLocation = 0
local fadeLength = 0.1
local useDefaultFadeLength = false
local adjustFillFadeBy = 0
local preserveFades = false
local addFadeToAreaBoundry = true
local randomSlipAmount = 0
local preventSmallItems = true
local restoreRazorEdits = true

-- MRX internal vars
local itemStartExistingFade = false
local itemEndExistingFade = false
local isMIDI = false
local storedItemSelections = {}
local storedTrackSelections = {}
local razorEditsToProcess = {}

-- Helper: check for any razor edits
function RazorEditSelectionExists()
  for i=0, reaper.CountTracks(0)-1 do
    local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)
    if x ~= "" then return true end
  end
  return false
end

-- Get razor edits (parse P_RAZOREDITS)
function GetRazorEdits()
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        if area ~= '' then
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
            local j = 1
            while j <= #str do
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j+1])
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
                local envelopeName, envelope
                if isEnvelope then
                  envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                  local ret, envName = reaper.GetEnvelopeName(envelope)
                  envelopeName = envName
                end
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    track = track,
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                }
                table.insert(areaMap, areaData)
                j = j + 3
            end
        end
    end
    return areaMap
end

-- Get info for first razor edit (used by MRX)
function GetRazorEditInfo()
    local razorEdits = GetRazorEdits()
    for r=1, #razorEdits do
      local data = razorEdits[r]
      local razorStart = data.areaStart
      local razorEnd = data.areaEnd
      local razorTrack = data.track
      if razorStart == nil or razorEnd == nil or razorTrack == nil then return -1, -1, -1 end
      local razorLength = math.abs(razorEnd - razorStart)
      return razorStart, razorLength, razorTrack, razorEnd
    end
end

-- Set track razor edit (append or clearSelection behavior)
function SetTrackRazorEdit(track, areaStart, areaEnd, clearSelection)
    if clearSelection == nil then clearSelection = false end
    if clearSelection then
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        local str = {}
        for j in string.gmatch(area, "%S+") do
            table.insert(str, j)
        end
        local j = 1
        while j <= #str do
            local GUID = str[j+2]
            if GUID == '""' then 
                str[j] = ''
                str[j+1] = ''
                str[j+2] = ''
            end
            j = j + 3
        end
        local REstr = tostring(areaStart) .. ' ' .. tostring(areaEnd) .. ' ""'
        table.insert(str, REstr)
        local finalStr = ''
        for i = 1, #str do
            local space = i == 1 and '' or ' '
            finalStr = finalStr .. space .. str[i]
        end
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', finalStr, true)
        return ret
    else
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        local str = area ~= nil and area .. ' ' or ''
        str = str .. tostring(areaStart) .. ' ' .. tostring(areaEnd) .. '  ""'
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', str, true)
        return ret
    end
end

-- Unselect all items and return last item end
function UnselectAllItems(razorStart, razorLength)
    local lastItemEnd = 0
    local items = reaper.CountMediaItems(0)
    for i=0, items -1 do
      local item = reaper.GetMediaItem(0, i)
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
      local itemEnd = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if itemEnd > lastItemEnd then lastItemEnd = itemEnd end
    end
    if razorStart ~= nil and razorLength ~= nil then
      if lastItemEnd < razorStart + razorLength then lastItemEnd = razorStart + razorLength end
    end
    return lastItemEnd
end

-- Unselect all tracks
function UnselectAllTracks()
    local tracks = reaper.CountTracks(0)
    for i=0, tracks -1 do
      local track = reaper.GetTrack(0, i)
      reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
    end
end

-- Handle random slip option
function HandleRandomSlip()
    if randomSlipAmount <= 0 then return end
    local slipAmount = randomSlipAmount
    local PosNeg = math.random()
    slipAmount = slipAmount * PosNeg
    if PosNeg < 0.5 then slipAmount = slipAmount * -1 end
    reaper.ApplyNudge(0, 0, 4, 0, slipAmount * 1000, false, 0)
end

-- Duplicate to fill
function DuplicateToFill(itemLength, razorLength, razorTrack, initialItem, takeOffset)
    local totalLength = itemLength
    local previousItem = nil
    while razorLength > totalLength do
      reaper.Main_OnCommand(41295, 0) -- Item: Duplicate items
      local item = reaper.GetSelectedMediaItem(0,0)
      if item == nil then return end
      local take = reaper.GetActiveTake(item)
      reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", takeOffset)
      HandleRandomSlip()
      local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if totalLength + itemLength < razorLength then previousItem = item end
      totalLength = totalLength + itemLength
    end
    if totalLength > razorLength then
      local item = reaper.GetSelectedMediaItem(0,0)
      if item == nil then return end
      local trimAmount = math.abs(totalLength - razorLength)
      if previousItem == nil then previousItem = initialItem end
      if preventSmallItems and previousItem ~= nil and reaper.GetMediaItemInfo_Value(item, "D_LENGTH") - trimAmount < (fadeLength + adjustFillFadeBy) * 2 then
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        trimAmount = itemLength - trimAmount
        reaper.DeleteTrackMediaItem(razorTrack, item)
        reaper.SetMediaItemInfo_Value(previousItem, "B_UISEL", 1)
        reaper.ApplyNudge(0, 0, 3, 0, trimAmount * 1000, false, 0)
        return
      end
      reaper.ApplyNudge(0, 0, 3, 0, trimAmount * 1000, true, 0)
    end
end

-- Paste item(s) from clipboard to temporary area and validate
function PasteItem(razorStart, razorLength, razorTrack, lastItemEnd)
    reaper.SetMediaTrackInfo_Value(razorTrack, "I_SELECTED", 1)
    reaper.Main_OnCommand(40914, 0) -- Track: Set first selected track as last touched track
    reaper.SetEditCurPos(lastItemEnd + 10, false, false)
    reaper.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
    reaper.Main_OnCommand(42406, 0) -- Razor edit: Clear all areas
    local item = reaper.GetSelectedMediaItem(0,0)
    if item == nil then 
      SetTrackRazorEdit(razorTrack, lastItemEnd + 9, lastItemEnd + 11 + razorLength, clearSelection)
      reaper.Main_OnCommand(40697, 0) -- Remove items/tracks/envelope points
      reaper.ShowMessageBox("ERROR: Nothing in clipboard", "Paste To Fill", 0)
      return
    end
    local selItemCount = reaper.CountSelectedMediaItems(0)
    if selItemCount <= 0 or selItemCount > 1 then
      SetTrackRazorEdit(razorTrack, lastItemEnd + 9, lastItemEnd + 11 + razorLength, clearSelection)
      reaper.Main_OnCommand(40697, 0)
      reaper.ShowMessageBox("ERROR: Only one item can be in the clipboard", "Paste To Fill", 0)
      return
    end
    local take = reaper.GetActiveTake(item)
    isMIDI = reaper.TakeIsMIDI(take)
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    if itemLength <= fadeLength + adjustFillFadeBy then 
      local userInput = reaper.ShowMessageBox("Fade Length is larger than content in clipboard\nThis can cause undesirable crossfades", "Paste To Fill", 1)
      if userInput == 2 then
        reaper.Main_OnCommand(40059, 0) -- Cut
        itemLength = nil
        return
      end
    end
    local take = reaper.GetActiveTake(item) 
    local takeOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    HandleRandomSlip()
    if itemLength > razorLength then
      reaper.SetMediaItemInfo_Value(item, "D_LENGTH", razorLength)
      return itemLength
    end
    DuplicateToFill(itemLength, razorLength, razorTrack, item, takeOffset)
    return itemLength
end

-- Move content to destination
function MoveContentToDestination(lastItemEnd, razorStart)
    local items = reaper.CountMediaItems(0)
    for i=0, items -1 do
      local item = reaper.GetMediaItem(0, i)
      local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if itemPos > lastItemEnd then 
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) 
      end
    end
    reaper.Main_OnCommand(40057, 0) -- Copy ignoring time selection
    reaper.SetEditCurPos(razorStart, false, false)
    reaper.Main_OnCommand(42398, 0) -- Paste
end

-- Fill table of selected items for fading steps
function FillTable(itemsToFade)
    local selItems = reaper.CountSelectedMediaItems(0)
    for i=0, selItems -1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      table.insert(itemsToFade, item)
    end
end

-- Get items before and after area
function GetStartEndItemReference(itemsToFade, razorStart, razorEnd)
    UnselectAllItems()
    local startItem = nil
    local endItem = nil
    for i=1, #itemsToFade do
      if i == 1 then
        local items = reaper.CountMediaItems(0)
        for j=0, items - 1 do
          local item = reaper.GetMediaItem(0, j)
          if item == itemsToFade[i] then 
            startItem = reaper.GetMediaItem(0, j-1)
          end
        end
      end
      if i == #itemsToFade then
        local items = reaper.CountMediaItems(0)
        for j=0, items - 1 do
          local item = reaper.GetMediaItem(0, j)
          if item == itemsToFade[i] then 
            endItem = reaper.GetMediaItem(0, j+1)
          end
        end
      end
    end
    return startItem, endItem
end

-- Trim item for fades
function TrimItem(item, trimSide, areaSide) 
    if item == nil then return end
    local trimAmount = fadeLength / 2
    if preserveFades then  
      if areaSide == nil and trimSide == -1 then
          local existingFadeLength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
          local existingAutoFadeLength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
          if existingFadeLength > 0 or existingAutoFadeLength > 0 then itemEndExistingFade = true return end
      end
      if areaSide == nil and trimSide == 1 then
        local existingFadeLength = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
        local existingAutoFadeLength = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
        if existingFadeLength > 0 or existingAutoFadeLength > 0 then itemStartExistingFade = true return end
      end
      if areaSide == -1 then
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) 
        reaper.ApplyNudge(0, 0, 3, 0, (trimAmount + adjustFillFadeBy) * 1000, false, 0)
        if not itemStartExistingFade then reaper.ApplyNudge(0, 0, 1, 0, (trimAmount) * 1000, true, 0) end
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0) 
        if addFadeToAreaBoundry then reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", trimAmount * 2) end
        return
      end
      if areaSide == 1 then
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) 
        reaper.ApplyNudge(0, 0, 1, 0, (trimAmount + adjustFillFadeBy) * 1000, true, 0)
        if not itemEndExistingFade then reaper.ApplyNudge(0, 0, 3, 0, (trimAmount) * 1000, false, 0) end
        reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0) 
        if addFadeToAreaBoundry then reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", trimAmount * 2) end
        return
      end
    end
    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) 
    if trimSide == -1 then
      reaper.ApplyNudge(0, 0, 1, 0, trimAmount * 1000, true, 0)
    elseif trimSide == 0 then
      if adjustFillFadeBy == 0 then
        reaper.ApplyNudge(0, 0, 1, 0, (trimAmount + adjustFillFadeBy) * 1000, true, 0)
        reaper.ApplyNudge(0, 0, 3, 0, (trimAmount + adjustFillFadeBy) * 1000, false, 0)
      else
        if areaSide == -1 then
          reaper.ApplyNudge(0, 0, 1, 0, trimAmount * 1000, true, 0) 
          reaper.ApplyNudge(0, 0, 3, 0, (trimAmount + adjustFillFadeBy) * 1000, false, 0)
        end
        if areaSide == 0 then
          reaper.ApplyNudge(0, 0, 1, 0, (trimAmount + adjustFillFadeBy) * 1000, true, 0)
          reaper.ApplyNudge(0, 0, 3, 0, (trimAmount + adjustFillFadeBy) * 1000, false, 0)
        end
        if areaSide == 1 then
          reaper.ApplyNudge(0, 0, 1, 0, (trimAmount + adjustFillFadeBy) * 1000, true, 0)
          reaper.ApplyNudge(0, 0, 3, 0, trimAmount * 1000, false, 0)
        end
      end
    elseif trimSide == 1 then
      reaper.ApplyNudge(0, 0, 3, 0, trimAmount * 1000, false, 0)
    end
    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
end

-- Set fade length to default preference if requested
function SetFadeLength()
    if useDefaultFadeLength then 
      local value = reaper.SNM_GetDoubleConfigVar("deffadelen", -1)
      if value > 0 then fadeLength = value end
    end
end

-- Handle crossfades for items to fade
function HandleCrossFades(itemsToFade, startItem, endItem)
    if isMIDI then return end
    TrimItem(startItem, 1)
    TrimItem(endItem, -1)
    if #itemsToFade == 1 then TrimItem(itemsToFade[1], 0) return end
    local areaStartItem = itemsToFade[1]
    TrimItem(areaStartItem, 0, -1)
    local areaEndItem = itemsToFade[#itemsToFade]
    TrimItem(areaEndItem, 0, 1)
    for i=1, #itemsToFade do
      if i ~= 1 and i ~= #itemsToFade then
        local middleItem = itemsToFade[i]
        TrimItem(middleItem, 0, 0)
      end
    end
end

-- Cleanup pasted/temp data
function CleanUp(initialCursorPos, lastItemEnd, razorTrack, itemLength)
    local cleanUpAreaStart = 0
    local cleanUpAreaEnd = 0
    local items = reaper.CountMediaItems(0)
    local haveClipBoardItem = false
    for i=0, items -1 do
      local item = reaper.GetMediaItem(0, i)
      local itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if itemPos > lastItemEnd then 
        if not haveClipBoardItem then 
          reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1) 
          reaper.SetMediaItemInfo_Value(item, "D_LENGTH", itemLength)
          haveClipBoardItem = true 
          cleanUpAreaStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
        else
          cleanUpAreaEnd = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        end
      end
    end
    reaper.Main_OnCommand(40059, 0) -- Cut
    if cleanUpAreaEnd == 0 then cleanUpAreaEnd = cleanUpAreaStart + itemLength end
    SetTrackRazorEdit(razorTrack, cleanUpAreaStart - 10, cleanUpAreaEnd + itemLength, true)
    reaper.Main_OnCommand(40697, 0) -- Remove
    reaper.Main_OnCommand(42406, 0) -- Clear razor edits
end

-- Remove envelope data leftovers
function RemoveEnvelopeData(razorTrack, cleanUpAreaStart, cleanUpAreaEnd, itemLength)
    SetTrackRazorEdit(razorTrack, cleanUpAreaStart - 10, cleanUpAreaEnd + itemLength, true)
    reaper.Main_OnCommand(40697, 0)
    reaper.Main_OnCommand(42406, 0)
end

-- Return edit cursor according to user option
function ReturnEditCursor(initialCursorPos, areaStart, areaEnd)
    if leaveCursorLocation == 0 then reaper.SetEditCurPos(initialCursorPos, false, false) return end
    if leaveCursorLocation == 1 then reaper.SetEditCurPos(areaStart, false, false) return end
    if leaveCursorLocation == 2 then reaper.SetEditCurPos(areaEnd, false, false) return end
    reaper.SetEditCurPos(initialCursorPos, false, false)
end

-- Get/Set preferences (autoxfade/trim) and return previous states
function GetSetPrefs()
    local initialTrimState = -1
    local trimState = reaper.SNM_GetIntConfigVar("autoxfade", -1)
    if trimState&2 == 0 then initialTrimState = 0 end
    if trimState&2 == 2 then initialTrimState = 1 end
    reaper.Main_OnCommand(41121, 0) -- Disable trim content behind media items when editing
    local initialAutoFadeState = -1
    local autoFadeState = reaper.SNM_GetIntConfigVar("autoxfade", -1) 
    if autoFadeState&1 == 0 then initialAutoFadeState = 0 end
    if autoFadeState&1 == 1 then initialAutoFadeState = 1 end
    reaper.Main_OnCommand(41118, 0) -- Enable auto-crossfades
    return initialTrimState, initialAutoFadeState
end

-- Reset preferences to previous states
function ResetPrefs(initialTrimState, initialAutoFadeState)
    if initialTrimState == 1 then reaper.Main_OnCommand(41120, 0) end
    if initialAutoFadeState == 0 then reaper.Main_OnCommand(41119, 0) end
end

-- Create temporary left boundary item if needed
function TempLeftBoundry(razorStart, razorTrack)
    local items = reaper.GetTrackNumMediaItems(razorTrack)
    local closestEdge = 0
    for i=0, items -1 do
      local item = reaper.GetTrackMediaItem(razorTrack, i)
      local itemEnd = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if itemEnd > closestEdge and itemEnd < razorStart + 0.001 then closestEdge = itemEnd end
    end
    local distance = razorStart - closestEdge
    if distance > fadeLength / 2 then 
      local tempItem = reaper.AddMediaItemToTrack(razorTrack)
      local tempItemStart = razorStart - fadeLength 
      reaper.SetMediaItemInfo_Value(tempItem, "D_POSITION", tempItemStart)
      local tempILength = razorStart - tempItemStart
      reaper.SetMediaItemInfo_Value(tempItem, "D_LENGTH", tempILength)
      return tempItem
    end
end

-- Create temporary right boundary item if needed
function TempRightBoundry(razorEnd, razorTrack)
    local items = reaper.GetTrackNumMediaItems(razorTrack)
    local closestEdge = math.huge
    for i=0, items -1 do
      local item = reaper.GetTrackMediaItem(razorTrack, i)
      local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      if itemStart < closestEdge and itemStart > razorEnd - 0.001 then closestEdge = itemStart end
    end
    local distance = closestEdge - razorEnd
    if distance > fadeLength  / 2 then 
      local tempItem = reaper.AddMediaItemToTrack(razorTrack)
      local tempItemStart = razorEnd
      reaper.SetMediaItemInfo_Value(tempItem, "D_POSITION", tempItemStart)
      local tempILength = fadeLength
      reaper.SetMediaItemInfo_Value(tempItem, "D_LENGTH", tempILength)
      return tempItem
    end
end

-- Clear temp boundary item and apply fades if needed
function ClearTempItem(tempItem, track, itemsToFade, isStart)
  if tempItem == nil then return end
  local targetFound = false
  local items = reaper.CountTrackMediaItems(track)
  for i=0, items -1 do
    local target = reaper.GetTrackMediaItem(track, i)
    if target == tempItem then targetFound = true end
  end
  if not targetFound then return end
  reaper.DeleteTrackMediaItem(track, tempItem)
  local edgeItem = nil
  if isMIDI then return end
  if isStart then edgeItem = itemsToFade[1] else edgeItem = itemsToFade[#itemsToFade] end
  if edgeItem ~= nil then 
    reaper.SetMediaItemInfo_Value(edgeItem, "B_UISEL", 1) 
    if isStart then
      reaper.ApplyNudge(0, 0, 1, 0, (fadeLength / 2) * 1000, false, 0)
      if addFadeToAreaBoundry then
        reaper.SetMediaItemInfo_Value(edgeItem, "D_FADEINLEN", fadeLength)
      end
    else
      reaper.ApplyNudge(0, 0, 3, 0, (fadeLength / 2) * 1000, true, 0)
      if addFadeToAreaBoundry then
        reaper.SetMediaItemInfo_Value(edgeItem, "D_FADEOUTLEN", fadeLength)
      end
    end
    reaper.SetMediaItemInfo_Value(edgeItem, "B_UISEL", 0)
  end
end

-- Item paste to fill flow
function ItemPasteToFill(initialCursorPos)
    local itemsToFade = {}
    UnselectAllTracks()
    SetFadeLength()
    local razorStart, razorLength, razorTrack, razorEnd = GetRazorEditInfo()
    local lastItemEnd = UnselectAllItems(razorStart, razorLength)
    local tempLeft = TempLeftBoundry(razorStart, razorTrack)
    local tempRight = TempRightBoundry(razorEnd, razorTrack)
    if razorStart == -1 then reaper.SetEditCurPos(initialCursorPos, false, false) return false end
    local itemLength = PasteItem(razorStart, razorLength, razorTrack, lastItemEnd)
    if itemLength == nil then 
        reaper.SetEditCurPos(initialCursorPos, false, false) 
        ClearTempItem(tempLeft, razorTrack, itemsToFade, true)
        ClearTempItem(tempRight, razorTrack, itemsToFade, false)
        return false
    end
    MoveContentToDestination(lastItemEnd, razorStart)
    FillTable(itemsToFade)
    local startItem, endItem = GetStartEndItemReference(itemsToFade, razorStart, razorEnd)
    local initialTrimState, initialAutoFadeStae = GetSetPrefs()
    HandleCrossFades(itemsToFade, startItem, endItem)
    CleanUp(initialCursorPos, lastItemEnd, razorTrack, itemLength)
    ClearTempItem(tempLeft, razorTrack, itemsToFade, true)
    ClearTempItem(tempRight, razorTrack, itemsToFade, false)
    ResetPrefs(initialTrimState, initialAutoFadeStae)
    ReturnEditCursor(initialCursorPos, razorStart, razorEnd)
    return true
end

-- Envelope helper: set envelope razor edit on track
function SetEnvelopeRazorEdit(envelope, track, areaStart, areaEnd)
    local retval, guid = reaper.GetSetEnvelopeInfo_String(envelope, "GUID", "", false)
    local razorArea = string.format([[ %.20f %.20f "%s"]], areaStart, areaEnd, guid)
    reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", razorArea, true)
end

function CleanUpEnvelopePoints(envelope)
    reaper.Main_OnCommand(40697, 0)
end

function PasteEnvelope(lastItemEnd, razorLength, razorTrack, envelope)
    reaper.SetEditCurPos(lastItemEnd + 10, false, false)
    reaper.Main_OnCommand(42398, 0) -- Paste
    local pasteStart, pasteLength, pasteTrack, pasteEnd = GetRazorEditInfo()
    local totalLength = pasteLength
    if totalLength == nil or razorLength == nil then 
      CleanUpEnvelopePoints(envelope) 
      reaper.ShowMessageBox("ERROR: Envelope points must be copied with a razor edit. Selecting points alone will not work", "Paste To Fill", 0) 
      return -1, -1, false 
    end
    local item = reaper.GetSelectedMediaItem(0,0)
    if item == nil then
      while totalLength < razorLength do
        reaper.Main_OnCommand(41295, 0) -- Duplicate
        totalLength = totalLength + pasteLength
      end
      SetEnvelopeRazorEdit(envelope, razorTrack, lastItemEnd + 10, lastItemEnd + 10 + razorLength) 
      reaper.Main_OnCommand(40057, 0) -- Copy ignoring time selection
      isValid = true
    else
      SetTrackRazorEdit(razorTrack, lastItemEnd + 9, lastItemEnd + 11 + pasteLength, true)
      reaper.Main_OnCommand(40697, 0)
      isValid = false
    end
    return totalLength, pasteLength, isValid
end

function MoveEnvelopeToDestination(razorStart)
    reaper.SetEditCurPos(razorStart, false, false)
    reaper.Main_OnCommand(42398, 0)
end

function CleanUpEnvelope(lastItemEnd, totalLength, pasteLength, envelope, razorTrack)
    SetEnvelopeRazorEdit(envelope, razorTrack, lastItemEnd + 10, lastItemEnd + 10 + pasteLength) 
    reaper.Main_OnCommand(40057, 0)
    SetEnvelopeRazorEdit(envelope, razorTrack, lastItemEnd + 9, lastItemEnd + 11 + totalLength) 
    reaper.Main_OnCommand(40697, 0)
end

function EnvelopePasteToFill(envelope, initialCursorPos)
    UnselectAllTracks()
    reaper.Main_OnCommand(40331, 0) -- Envelope: Unselect all points
    local razorStart, razorLength, razorTrack, razorEnd = GetRazorEditInfo()
    local lastItemEnd = UnselectAllItems(razorStart, razorLength)
    if razorStart == -1 then reaper.SetEditCurPos(initialCursorPos, false, false) return false end
    local totalLength, pasteLength, isValid = PasteEnvelope(lastItemEnd, razorLength, razorTrack, envelope)
    if not isValid then reaper.SetEditCurPos(initialCursorPos, false, false) return false end 
    MoveEnvelopeToDestination(razorStart)
    CleanUpEnvelope(lastItemEnd, totalLength, pasteLength, envelope, razorTrack)
    ReturnEditCursor(initialCursorPos, razorStart, razorEnd)
    return true
end

function DecidePasteToFill()
    local razorInfo = GetRazorEdits()
    if razorInfo[1].isEnvelope then 
      local envelope = razorInfo[1].envelope
      return envelope
    end
end

function StoreItemSelections()
    for i=0, reaper.CountSelectedMediaItems(0) -1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        table.insert(storedItemSelections, item)
    end
end

function StoreTrackSelections()
    for i=0, reaper.CountSelectedTracks(0) -1 do
        local track = reaper.GetSelectedTrack(0,i)
        table.insert(storedTrackSelections, track)
    end
end

function RestoreRazorEditsInEnvLanes()
    local envTracks = {}
    local prevTrack = nil
    for i=1, #razorEditsToProcess do
        local data = razorEditsToProcess[i]
        local startProcess = data.processStart
        local endProcess = data.processEnd
        local trackToProcess = data.processTrack
        local envToProcess = data.processEnv
        local retval, guid = reaper.GetSetEnvelopeInfo_String(envToProcess, "GUID", "", false)
        local razorArea = string.format([[ %.20f %.20f "%s"]], startProcess, endProcess, guid)
        if trackToProcess ~= prevTrack then
            envTracks[trackToProcess] = razorArea
        else
            local prevArea = envTracks[trackToProcess]
            local newArea = prevArea .. razorArea
            envTracks[trackToProcess] = newArea
        end
        prevTrack = trackToProcess
    end
    for k, v in pairs(envTracks) do
        reaper.GetSetMediaTrackInfo_String(k, "P_RAZOREDITS", v, true)
    end
end

function RestoreSelections()
    reaper.Main_OnCommand(40289, 0) -- Unselect all items
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    for i=1, #storedItemSelections do
        local item = storedItemSelections[i]
        if item ~= nil then
            reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
        end
    end
    for t=1, #storedTrackSelections do
        local track = storedTrackSelections[t]
        reaper.SetTrackSelected(track, true)
    end
    if not restoreRazorEdits then return end
    for i=1, #razorEditsToProcess do
        local data = razorEditsToProcess[i]
        local startProcess = data.processStart
        local endProcess = data.processEnd
        local trackToProcess = data.processTrack
        local envToProcess = data.processEnv
        if envToProcess == nil then 
            SetTrackRazorEdit(trackToProcess, startProcess, endProcess, false)
        else
            RestoreRazorEditsInEnvLanes()
            break
        end
    end
end

function StoreRazorEdits()
    local razorEdits = GetRazorEdits()
    local processEnvelopes = false
    local razorMisMatch = false
    for i=1, #razorEdits do
        local data = razorEdits[i]
        local s = data.areaStart
        local e = data.areaEnd
        local t = data.track
        local env = nil
        if razorEdits[1].isEnvelope then env = razorEdits[i].envelope processEnvelopes = true end
        local razorEditToProcess = {processStart = s, processEnd = e, processTrack = t, processEnv = env}
        table.insert(razorEditsToProcess, razorEditToProcess)
        if processEnvelopes then 
            local value = razorEdits[i].isEnvelope
            if value == false then razorMisMatch = true end
        end
    end
    reaper.Main_OnCommand(42406, 0) -- Clear all razor edits
    return razorMisMatch
end

-- Main MRX logic (very slightly adapted naming scope)
function MRX_Main()
    if not RazorEditSelectionExists() then return end
    local arrangeViewStart, arrangeViewEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
    local initialCursorPos = reaper.GetCursorPosition()
    initialContext = reaper.GetCursorContext2(true)
    StoreItemSelections()
    StoreTrackSelections()
    local razorMisMatch = StoreRazorEdits()
    if razorMisMatch then 
        reaper.ShowMessageBox("ERROR:\n\nWhen pasting to Envelope Lanes\nOnly Envelope Lanes can contain Razor Edits", "Paste To Fill", 0)
        reaper.SetCursorContext(initialContext, envelope)
        RestoreSelections()
        reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeViewStart, arrangeViewEnd)
        return
    end
    local prevStart = -1
    local prevEnd = -1
    local prevTrack = nil
    for i=1, #razorEditsToProcess do
        local data = razorEditsToProcess[i]
        local startProcess = data.processStart
        local endProcess = data.processEnd
        local trackToProcess = data.processTrack
        local envToProcess = data.processEnv
        if startProcess ~= prevStart and endProcess ~= prevEnd then 
            if envToProcess == nil then 
                SetTrackRazorEdit(trackToProcess, startProcess, endProcess, true)
                reaper.Main_OnCommand(40697, 0) -- Remove
                SetTrackRazorEdit(trackToProcess, startProcess, endProcess, true)
            else
                SetEnvelopeRazorEdit(envToProcess, trackToProcess, startProcess, endProcess)
            end
            local envelope = DecidePasteToFill()
            if envelope ~= nil then 
              reaper.SetCursorContext(2, envelope)
              local isValid = EnvelopePasteToFill(envelope, initialCursorPos) 
              if not isValid then return end
            else 
              reaper.SetCursorContext(1)
              local isValid = ItemPasteToFill(initialCursorPos)
              if not isValid then return end
            end
            if prevTrack == trackToProcess then
                prevStart = startProcess
                prevEnd = endProcess
            else
                prevStart = -1
                prevEnd = -1
            end
            itemStartExistingFade = false
            itemEndExistingFade = false
            isMIDI = false
            reaper.Main_OnCommand(42406, 0) -- Clear all razor edits
        end
    end
    reaper.SetCursorContext(initialContext, envelope)
    RestoreSelections()
    reaper.GetSet_ArrangeView2(0, true, 0, 0, arrangeViewStart, arrangeViewEnd)
end

-- Execute: single undo block that creates razor edits then runs MRX_Main
reaper.Undo_BeginBlock()
create_razor_edits_on_selected_tracks(ts_start, ts_end)
MRX_Main()
reaper.UpdateTimeline()
reaper.UpdateArrange()
reaper.Main_OnCommand(42406, 0)
reaper.Undo_EndBlock("TimeSel → RazorEdits → MRX Paste To Fill", -1)
