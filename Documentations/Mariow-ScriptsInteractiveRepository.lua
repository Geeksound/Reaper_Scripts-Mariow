--[[
@description Mariow Scripts – Interactive Repository Visualizer & Launcher
@version 1.1.4
@author Mariow
@changelog
    v1.1.4 (2026-02-24)
    -Add Rating Clips and Copy/Paste(PTlike)
    v1.1.3 (2026-02-16)
    -Add RazorUP and RazorDOWN
    v1.1.2 (2026-02-02)
    -Add SlipContentOfItems
    v1.1.1 (2026-01-08)
    -Add DualTrimSlider-EvenOddItems.lua
    v1.1 (2025-12-XX)
    - New Scripts
    v1.0 (2025-12-15)
    - Initial Release
@provides
    [main] Documentations/Mariow-ScriptsInteractiveRepository.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags ImGui, Launcher, ProTools, Repository, Workflow
@about
    # Mariow Scripts – Interactive Repository

    This script is a central **ImGui-based launcher and visual browser**
    for the entire Mariow Scripts repository in REAPER.

    It provides:
    - Categorized tabs with automatic color assignment
    - Colored buttons for instant script launching
    - Contextual help tooltips describing each script’s purpose
    - A visual, Pro Tools–inspired workflow hub

    Designed as a **navigation and discovery tool**, it allows users to
    explore, understand, and execute Mariow’s scripts efficiently from
    a single interactive interface.

    Developed for REAPER 7+ using ReaImGui.
--]]


-- IMGUI INIT
local ctx = reaper.ImGui_CreateContext("Mariow's Repository visualizer and launcher")
local font_size = tonumber(reaper.GetExtState("ProTools_Launcher", "FontSize")) or 20
local FONT = reaper.ImGui_CreateFont("sans-serif", font_size)
reaper.ImGui_Attach(ctx, FONT)

local function ImGui_HelpMarker(ctx, desc)
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_BeginTooltip(ctx)
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35)
        reaper.ImGui_Text(ctx, desc)
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end


local function Pad()
    reaper.ImGui_Dummy(ctx, 0, 6)
end

-- Launch script by full path
local function LaunchScript(script_path)
    local full_path = reaper.GetResourcePath() .. "/Scripts/Mariow Scripts/" .. script_path
    local f, err = loadfile(full_path)
    if f then f() else reaper.ShowMessageBox("Failed to load script:\n"..full_path.."\nError: "..err, "Error", 0) end
end

-- Button helper with color
local function ColoredButton(ctx, label, color, w, h)
    local r,g,b,a = table.unpack(color)
    local normal  = reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a)
    local hovered = reaper.ImGui_ColorConvertDouble4ToU32(math.min(r+0.2,1.0), math.min(g+0.2,1.0), math.min(b+0.2,1.0), a)
    local active  = reaper.ImGui_ColorConvertDouble4ToU32(math.min(r+0.1,1.0), math.min(g+0.1,1.0), math.min(b+0.1,1.0), a)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), normal)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), hovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), active)
    local clicked = reaper.ImGui_Button(ctx, label, w, h)
    reaper.ImGui_PopStyleColor(ctx, 3)
    return clicked
end

-- Scripts table (extrait pour l'exemple, ajoute tous les scripts comme dans ton original)
local scripts = {
    -- Documentations
    { category="Documentations", name="Repository Guide", path="Documentations/Repository-Guide.lua", color={0.6,0.6,0.6,0.5}, same_line=true },

    { category = "Documentations", name = "(Protools) TAB Instructions", path = "ProTools_TAB/(Protools)TAB-Instructions.lua", color={0.6,0.6,0.6,0.5}},
    

    -- SEPARATOR
    { category = "", name = " ", path = nil, color={0.0,0.0,0.0,1} },    

    -- Editing
    { category = "Editing", name = "Track Manager", path = "Editing/TrackManager.lua" , color={0.6,0.3,0.2,1}, same_line=true,
    help="Provides a Pro Tools–style Track Manager for REAPER. Visualize, organize, and control track states,"..
    "offering a clear, palette-based overview of your session for fast and efficient track management."},
    { category = "Editing", name = "Track Manager Expanded", path = "Editing/TrackManager-Expanded.lua" , color={0.6,0.3,0.2,1},
    help="Provides a Pro Tools–style Track Manager for REAPER. Visualize, organize, and control track states,"..
    "offering a clear, palette-based overview of your session for fast and efficient track management."},
    { category="Editing", name="Item Control Board", path="Editing/ItemControlBoard.lua", color={0.2,0.4,0.8,1}, same_line=true,
    help="Provides an interactive control board for media items in REAPER. Adjust trims, fades, pitch, gain, and colors,"..
    "offering a fast, palette-based editing workflow inspired by Pro Tools."},
    { category = "Editing", name = "Time Shift", path = "Editing/TimeShift.lua" , color={0.2,0.4,0.8,1} ,
    help="Texte1 en attente\nPassage  a la ligne"},
    { category="Editing", name="Move Item To Track Above", path="Editing/MoveItemToTrackAbove.lua", color={0.6,0.3,0.2,1}, same_line=true ,
    help="Moves the selected item to the track above in REAPER. Quickly rearrange items between adjacent tracks,"..
    "streamlining your editing workflow with one simple action."},
    { category="Editing", name="Move Item To Track Below", path="Editing/MoveItemToTrackBelow.lua", color={0.7,0.4,0.3,1},
    help="Moves the selected item to the track below in REAPER. Quickly rearrange items between adjacent tracks,"..
    "streamlining your editing workflow with one simple action."},

    { category = "Editing", name = "ReaPlace Clip", path = "Editing/ReaPlaceClip.lua" , color={0.6,0.3,0.2,1},
    help="Provides a Pro Tools–style Replace Clip workflow in REAPER. Replace all occurrences of a source clip at once,"..
    "making global audio updates fast and reliable for post-production and sound design."},
    { category = "Editing", name = "Remove Takes By Choices", path = "Editing/RemoveTakesByChoices.lua" , color={0.6,0.3,0.2,1},
    help="Provides a simple take-cleanup tool for REAPER. Select and delete specific takes across items,"..
    "making it easy to remove unwanted takes and keep sessions clean."},
    { category = "Editing", name = "Shuffle Items", path = "Editing/ShuffleItems.lua" , color={0.6,0.3,0.2,1} , same_line=true,
    help="Rearranges items on a track using Pro Tools–style Shuffle mode. Removes gaps and overlaps,"..
    "allowing clean, contiguous item layouts with a single action"},
    { category = "Editing", name = "Swap Items Positions On Same Tracks", path = "Editing/Swap-ItemsPositionsOnSameTracks.lua" , color={0.6,0.3,0.2,1},
    help="Swaps the positions of two selected items in REAPER. Ideal for quick A/B comparisons,"..
    "allowing instant evaluation of edits without manual repositioning"},
    
    
    -- Editing TRIM
    { category = "Editing TRIM", name = "UnTrim Start To Prev", path = "Editing_TRIM/UnTrimStartToPrev.lua" , color={0.6,0.3,0.2,1} , same_line=true,
    help="Trims the left edge of the selected item to the end of the previous item on the same track,"..
    "ensuring clean, gap-free edits without altering already aligned items"},
    { category = "Editing TRIM", name = "UnTrim End To Next", path = "Editing_TRIM/UnTrimEndToNext.lua" , color={0.6,0.3,0.2,1}, same_line=true,
    help="Trims the right edge of the selected item to the start of the next item on the same track,"..
    "ensuring clean, gap-free edits without altering already aligned items"},
    { category = "Editing TRIM", name = "UnTrim Between Items", path = "Editing_TRIM/UnTrimBetweenItems.lua" , color={0.6,0.3,0.2,1} ,
    help="Trims the left and right edges of the selected item to adjacent items on the same track,"..
    "creating clean, tightly spaced edits without overlaps or gaps"},
    { category = "Editing TRIM", name = "Trim Left/Right @range", path = "Editing_TRIM/Trim-LeftRight@range.lua" , color={0.6,0.3,0.2,1},
    help="Trims the left and right edges of selected items using adjustable sliders,"..
    "offering precise control over item duration (1s to 10s) with smooth frame-based adjustments"},
    { category = "Editing TRIM", name = "DualTrimSlider-EvenOddItems", path = "Editing_TRIM/DualTrimSlider-EvenOddItems.lua" , color={0.6,0.3,0.2,1},
    help="Trims the left and right edges of selected odd&Even items using adjustable sliders,"..
    "offering precise control over item duration (1s to 10s) with smooth frame-based adjustments"},
    { category = "Editing TRIM", name = "Auto-Split Overlapping Items (Keep Top Item)", path = "Editing_TRIM/Auto-Split Overlapping Items (Keep Top Item)" , color={0.6,0.3,0.2,1},
    help="Automatically splits overlapping items on the same track, keeping the top item intact,"..
    "and removing only the covered portions below for clean, organized edits"},
    
    -- SEPARATOR
    { category = " ", name = " ", path = nil, color={0.0,0.0,0.0,1} },
    
    -- Field Recorder Workflow
    { category = "Field Recorder Workflow", name = "Field Recorder Track Matching", path = "Field-Recorder_Workflow/FieldrecorderTrack-Matching.lua" , color={0.2,0.4,0.8,1}, same_line=true ,
    help="Field Recorder track matching for dialogue workflows.\n\nAfter importing an AAF (ideally via Vordio), the script searches a folder for original field recorder files,"..
    "then imports and places multichannel polyphonic takes beneath the AAF clips.\n\nRecreates a Pro Tools–style Field Recorder Track workflow for fast dialogue conformation."},
    { category = "Field Recorder Workflow", name = "Field Recorder Track Matching AUTO Lite", path = "Field-Recorder_Workflow/FieldrecorderTrack-Matching_AUTO-Lite.lua" , color={0.2,0.4,0.8,1}, same_line=true,
    help="Field Recorder track matching (automatic, lightweight version) for dialogue workflows.\n\nAfter importing an AAF (ideally via Vordio), the script automatically searches a folder for original field recorder files,"..
    "then imports and places multichannel polyphonic items beneath the AAF clips.\n\nProvides a fast Pro Tools–style workflow for dialogue track conformation."},
    { category = "Field Recorder Workflow", name = "Field Recording Sound Report", path = "Field-Recorder_Workflow/FieldrecordingSound-Report.lua" , color={0.18,0.54,0.18,1},
    help="Fieldrecording Sound Report for dialogue workflows.\n\nDuring field recording, the script lets you record production sound via Dante from Cantar or Scorpio,"..
    "add notes to describe recorded items, then select all items and launch the script to generate a sound report.\n\nThe report can be completed and exported as CSV for post-production, reading iXML/BWF metadata and item properties."},
    
    
    { category = "Field Recorder Workflow", name = "   ", path = nil, color={0.0,0.0,0.0,0} , same_line=true,},
    
    { category = "Field Recorder Workflow", name = "Set Item For IXML Rendering", path = "Field-Recorder_Workflow/Set-ItemFor-IXMLRendering.lua" , color={0.2,0.4,0.8,1},
    help="Prepares items for iXML rendering in dialogue workflows.\n\nAfter importing an AAF (ideally via Vordio), the script updates item names and notes to include SCENE, TAKE, and TRACKNAME information,"..
    "readying them for rendering with iXML metadata injection.\n\nEnhances field recorder track matching and organization, Pro Tools–style."},
    
    { category = "Field Recorder Workflow", name = " ", path = nil, color={0.0,0.0,0.0,0} , same_line=true,},
    
    { category = "Field Recorder Workflow", name = "Dial Edit Conform", path = "Field-Recorder_Workflow/Dial-EditConform.lua" , color={0.2,0.4,0.8,1},
    help="Automates dialogue audio conforming after FieldrecorderTrackMatching.\n\nCreates tracks from iXML/BWF metadata, explodes multichannel items into mono tracks,"..
    "renames items by source and metadata, moves items to correct tracks based on take names, and deletes empty or 'DISARMED' tracks.\n\nEnds by deselecting all items and tracks for a clean workflow."},
    
                   -- Dummy buttons / separation
    { category = "Field Recorder Workflow", name = "  ", path = nil, color={0.0,0.0,0.0,0} },
    
    
    { category = "Field Recorder Workflow", name = "Detect/Delete Empty Items", path = "Field-Recorder_Workflow/Detect-DeleteEmpty-Items.lua" , color={0.2,0.4,0.8,1} , same_line=true,
    help="Texte1 en attente\nPassage  a la ligne"},
    { category = "Field Recorder Workflow", name = "Detect Empty Items", path = "Field-Recorder_Workflow/DetectEmpty-Items.lua" , color={0.2,0.4,0.8,1} , same_line=true ,
    help="Texte1 en attente\nPassage  a la ligne"},
    { category = "Field Recorder Workflow", name = "Remove Duplicate Items", path = "Field-Recorder_Workflow/Remove-DuplicateItems.lua" , color={0.2,0.4,0.8,1},
    help="Texte1 en attente\nPassage  a la ligne"},
    { category = "Field Recorder Workflow", name = "Item Names To Track Names", path = "Field-Recorder_Workflow/ItemNames-To-TrackNames.lua" , color={0.6,0.3,0.2,1} , same_line=true,
    help="Texte1 en attente\nPassage  a la ligne"},
    { category = "Field Recorder Workflow", name = "Rename Item From Shooting Slate", path = "Field-Recorder_Workflow/RenameItemFrom-ShootingSlate.lua" , color={0.6,0.3,0.2,1} , same_line=true,
    help="Texte1 en attente\nPassage  a la ligne"},
    { category = "Field Recorder Workflow", name = "Select DISARMED item From CANTAR Monofiles", path = "Field-Recorder_Workflow/SelectDISARMEDitemFromCANTARMonofiles.lua" , color={0.2,0.6,0.2,0.5},
    help="Texte1 en attente\nPassage  a la ligne"},
    
    -- Metadatasæ
    { category = "Metadatas", name = "View Field Recorder Metadatas", path = "Metadatas/View-FieldRecorder-Metadatas.lua" , color={0.2,0.4,0.8,1} , same_line=true,
    help="Displays field recorder metadata stored in audio files.\n\nSelect an item and run the script to view BWF and iXML metadata written during shooting,"..
    "including scene, take, notes, timecode, track activation status, and field recorder track names.\n\nUseful for inspecting dialogue metadata from Cantar, Scorpio, or similar field recorders."},
    { category = "Metadatas", name = "View File Field Recorder Metadatas", path = "Metadatas/ViewFile-FieldRecorder-Metadatas.lua", color={0.2,0.4,0.8,1},
    help="Displays field recorder metadata from the source audio file.\n\nSelect an item to view its underlying BWF and iXML metadata,"..
    "showing scene, take, timecode, and track-related information directly from the media source.\n\nProvides a contextual metadata inspection tool for REAPER 7 workflows."},


    -- SEPARATOR
    { category = "  ", name = " ", path = nil, color={0.0,0.0,0.0,1} },

    -- PROTOOLS
    { category = "PROTOOLS", name = "Revert To Saved", path = "PROTOOLS/Revert-ToSaved.lua"  , color={0.7,0.18,0.18,0.5} , same_line=true,
    help="Reverts the current project to its last saved state.\n\nCloses the active project (prompting to save if needed) and reopens the last saved version,"..
    "emulating Pro Tools' 'Revert to Saved' behavior inside REAPER.\n\nUseful for quickly discarding all unsaved changes."},
    { category = "PROTOOLS", name = "Save Session Copy In", path = "PROTOOLS/Save-Session-Copy-In.lua"  , color={0.7,0.18,0.18,1}, same_line=true ,
    help="Creates a full 'Save Session Copy In' workflow for REAPER.\n\nScans all media referenced by the current project, lets you choose which files to include,"..
    "then duplicates the project with copied media and updated paths inside the new .RPP file.\n\nEmulates Pro Tools' 'Save Session Copy In' with live progress feedback."},
    { category = "PROTOOLS", name = "Save Session Copy In Folders", path = "PROTOOLS/SaveSessionCopyInFolders.lua"  , color={0.7,0.18,0.18,1},
    help="Advanced 'Save Session Copy In' with media routing matrix.\n\nScans all media in the current project and displays an interactive 4-folder matrix to route each file,"..
    "allowing custom folder naming, safe media copying, and automatic path remapping in the duplicated .RPP.\n\nProvides a powerful Pro Tools–style session copy workflow with advanced media organization."},
    { category = "PROTOOLS", name = "Link/Unlink Timeline AND Edit Sel", path = "PROTOOLS/LinkUnlink-TimelineANDEdit-Sel.lua"  , color={0.2,0.4,0.8,1}  , same_line=true ,
    help="Toggles link or unlink between Timeline and Edit Selection.\n\nSwitches the linkage between time selection, loop points, and edit cursor,"..
    "emulating Pro Tools' 'Link Timeline and Edit Selection' behavior.\n\nIdeal for quickly changing selection behavior during editing."},
    { category = "PROTOOLS", name = "Link/Unlink Timeline AND Edit Sel One KNOB", path = "PROTOOLS/LinkUnlink-TimelineANDEdit-SelOneKNOB.lua"  , color={0.2,0.4,0.8,1},
    help="Displays and toggles Timeline and Edit Selection link state.\n\nOpens a small floating ImGui window with a single button showing whether selections are linked or unlinked,"..
    "emulating Pro Tools' Timeline/Edit Selection link behavior.\n\nUseful for visually monitoring and toggling selection states during editing."},
    { category = "PROTOOLS", name = "Memory Location (as PT)", path = "PROTOOLS/MemoryLocation(as PT).lua"  , color={0.2,0.2,0.2,1},
    help="Jump to markers by number or name (Pro Tools–style).\n\nOpens a minimal ImGui input allowing you to type a marker number or exact name,"..
    "then press Enter to instantly jump to it and auto-close the window.\n\nIdeal for fast and precise marker navigation workflows."},
    { category = "PROTOOLS", name = "Paste To Fill", path = "PROTOOLS/Paste-ToFill.lua"  , color={0.2,0.4,0.8,1},
    help="Paste to Fill workflow based on Time Selection.\n\nCreates Razor Edits from the current Time Selection on selected tracks,"..
    "then executes the full MRX Paste To Fill process in a single undo step.\n\nReproduces Pro Tools' 'Paste to Fill' behavior for fast and precise editing."},
    
    { category = "PROTOOLS", name = "Copy(Pt-like)", path = "PROTOOLS/Copy(Pt-like).lua"  , color={0.2,0.4,0.8,1},same_line=true ,
    help="Copy(Pt-like) paste Razor area or Item copied depending on context"},
    { category = "PROTOOLS", name = "Paste(Pt-like)", path = "PROTOOLS/Paste(Pt-like).lua"  , color={0.2,0.4,0.8,1},
    help="Paste(Pt-like) paste Razor area or Item copied depending on context"},
    
    { category = "PROTOOLS", name = "Play Loop", path = "PROTOOLS/PlayLoop.lua"  , color={0.18,0.54,0.18,1}, same_line=true,
    help="Plays from Loop Start without losing Edit Cursor position.\n\nDisables preroll, jumps to the start of the current Loop selection, and starts playback,"..
    "then automatically restores the original Edit Cursor position when playback stops.\n\nMimics Pro Tools behavior when working with Loop Points independently from the Edit Cursor."},
    { category = "PROTOOLS", name = "Play Time Selection", path = "PROTOOLS/PlayTimeSelection.lua"  , color={0.18,0.54,0.18,1},
    help="Plays from the start of the Time Selection without losing Edit Cursor position.\n\nDisables preroll, jumps to the Time Selection start if defined, or plays from the Edit Cursor,"..
    "then automatically restores the original Edit Cursor position when playback stops.\n\nMimics Pro Tools behavior for independent playback from Time Selection or Edit Cursor."},
    { category = "PROTOOLS", name = "Sync Point To Edit Cursor", path = "PROTOOLS/SyncPoint-ToEditCursor.lua"  , color={0.2,0.4,0.8,1},
    help="Plays from the start of the Time Selection without losing Edit Cursor position.\n\nDisables preroll, jumps to the Time Selection start if defined, or plays from the Edit Cursor,"..
    "then automatically restores the original Edit Cursor position when playback stops.\n\nMimics Pro Tools behavior for independent playback from Time Selection or Edit Cursor."},
    { category = "PROTOOLS", name = "Zoom Sel (PT Alt F)", path = "PROTOOLS/ZoomSel-(PT Alt F).lua"  , color={0.6,0.3,0.2,1},
    help="Zooms to selected items or Time Selection (Pro Tools–style).\n\nIf items are selected, the arrange view zooms to them; otherwise, it zooms to the current Time Selection,"..
    "mimicking Pro Tools' clip zoom behavior."},
    
    
                   -- Dummy buttons / separation
    { category = "PROTOOLS", name = "    ", path = nil, color={0.0,0.0,0.0,0} },
    { category = "PROTOOLS", name = "ViewVideo", path = "PROTOOLS/ViewVideo.lua"  , color={0.2,0.2,0.2,1},
    help="Open Window Video "},
    { category = "PROTOOLS", name = "ImportVideo(PT-like)", path = "PROTOOLS/ImportVideo(PT-like).lua"  , color={0.2,0.2,0.2,1},
    help="Import Video (PT like) "},
  
    
    -- ProTools Essentials#1
    { category="ProTools Essentials#1",name= "Restore Last Selection", path = "ProTools_Essentials/RestoreLastSelection.lua" , color={0.3,0.7,0.3,1} , same_line=true,
    help="Restores the last stored Time Selection.\n\nRecalls the previously saved Time Selection in the project,"..
    "emulating Pro Tools behavior for restoring edit ranges.\n\nRequires TimeSelectionWatcher.lua to be running to track and store selections."},
    { category="ProTools Essentials#1",name= "Time Selection Watcher", path = "ProTools_Essentials/TimeSelectionWatcher.lua" , color={0.3,0.7,0.3,0.5} ,
    help="Watches and stores the last valid Time Selection.\n\nContinuously monitors Time Selection changes and saves the last non-empty selection,"..
    "allowing it to be restored later by RestoreLastSelection.lua.\n\nDesigned to run in Startup Actions for Pro Tools–like behavior."},
    { category="ProTools Essentials#1",name= "Scroll To Track (Altcmd F)", path = "ProTools_Essentials/Scroll-To-Track(Altcmd F).lua" , color={0.3,0.7,0.3,1} ,
    help="Scrolls to a track by name (Pro Tools–style).\n\nOpens a filterable track list and scrolls the arrange view to the selected track,"..
    "emulating Pro Tools' Alt+Cmd+F track navigation behavior."},
    { category="ProTools Essentials#1",name="Strip Silence (PT-Cmd U)", path = "ProTools_Essentials/Strip-Silence (PT-Cmd U).lua" , color={0.3,0.7,0.3,1},
    help="Executes Strip Silence on selected items (Pro Tools–style).\n\nRuns REAPER's native Strip Silence command,"..
    "mimicking Pro Tools' Cmd+U workflow for fast dialogue cleanup."},
    { category="ProTools Essentials#1",name = "View Name Envelope (Imgui)", path = "ProTools_Essentials/ViewNameEnvelope(imGui).lua" , color={0.3,0.7,0.3,1} ,
    help="Displays the selected envelope or track name in a small ImGui window.\n\nShows the active envelope name when one is selected,"..
    "or falls back to the selected track name.\n\nUseful as visual feedback when working with Pro Tools–style envelope workflows."},
    { category="ProTools Essentials#1", name="Cycle Envelope", path="ProTools_Essentials/CycleEnvelope.lua", color={0.2,0.4,0.8,1}, same_line=true,
    help="Cycles track envelope display: Volume, Mute, Pan, then Hide.\n\nReproduces a Pro Tools–style shortcut to cycle through track envelopes,"..
    "storing the current state between actions.\n\nControls envelope visibility without displaying any UI."},
    { category="ProTools Essentials#1", name="Cycle Envelope Rev", path="ProTools_Essentials/CycleEnvelopeRev.lua", color={0.2,0.4,0.8,1},
    help="Cycles track envelope display in reverse order.\n\nCycles through Hide, Pan, Mute, and Volume envelopes,"..
    "mirroring a Pro Tools–style reverse cycling shortcut.\n\nShares state with the forward cycling script to stay synchronized."},
    
    { category="ProTools Essentials#1", name = "PRE-Post-ROLL (Imgui)", path = "ProTools_Essentials/PRE-Post-ROLL(Imgui).lua" , color={0.3,0.7,0.3,0.7},
    help="Sets global Pre-Roll, Post-Roll, and Nudge values for Pro Tools–style scripts.\n\nProvides a central configuration for playback and navigation tools,"..
    "ensuring consistent transport and nudge behavior across the entire ProTools_Essentials suite.\n\nRun this script to adjust roll and nudge settings globally."},
    { category="ProTools Essentials#1", name="Extend Razor TCui", path="ProTools_Essentials/ExtendRazor-TCui.lua", color={0.3,0.7,0.3,0.7}, same_line=true,
    help="Extends Razor Areas using a shared timecode value.\n\nExtends existing Razor Areas by a duration read from the PRE/POST-ROLL + Timecode ImGui panel,"..
    "or converts the current Time Selection into a Razor Area if none exist.\n\nPart of the Pro Tools–style unified editing and navigation workflow."},
   -- { category="ProTools Essentials#1", name="Extend Razor TCui Rev", path="ProTools_Essentials/ExtendRazor-TCuiRev.lua", color={0.2,0.4,0.8,1} , same_line=true },
    { category = "ProTools Essentials#1", name = "Shrink Razor TCui", path = "ProTools_Essentials/ShrinkRazor-TCui.lua" , color={0.3,0.7,0.3,1} , same_line=true,
    help="Reduces Razor Areas using a shared timecode nudge value.\n\nMoves the left edge forward and the right edge backward by the duration defined in the Timecode UI,"..
    "or converts the current Time Selection into Razor Areas if none exist.\n\nDesigned for Pro Tools–style nudge-based editing workflows."},
    --Script: Mariow ExtendTimeSelection.lua
    { category = "ProTools Essentials#1", name = "Extend Time Selection", path = "ProTools_Essentials/ExtendTimeSelection-TCui.lua" , color={0.3,0.7,0.3,0.7} , same_line=true,
    help="Extends the current Time Selection by a duration defined in the shared Timecode UI.\n\nMoves the left edge backward"..
    "and the right edge forward,\nallowing precise Pro Tools–style time selection adjustments."},
    { category = "ProTools Essentials#1", name = "Shrink Time Selection TCui", path = "ProTools_Essentials/ShrinkTimeSelection-TCui.lua" , color={0.3,0.7,0.3,1},
    help="Reduces the current Time Selection by the nudge value defined in the shared Timecode UI.\n\nMoves the left edge forward and the right edge backward,"..
    "allowing precise Pro Tools–style time selection contraction."},
    
    
    { category = "ProTools Essentials#1", name = "Grow Left Edge TCui", path = "ProTools_Essentials/GrowLeftEdge-TCui.lua" , color={0.6,0.3,0.2,1} , same_line=true ,
    help="Moves the left edge of selected items backward by the nudge value from the shared Timecode UI, untrimming them in a Pro Tools–style workflow."},
    { category = "ProTools Essentials#1", name = "Grow Right Edge TCui", path = "ProTools_Essentials/GrowRightEdge-TCui.lua" , color={0.6,0.3,0.2,1}, same_line=true,
    help="Moves the right edge of selected items forward by the nudge value from the shared Timecode UI, untrimming/extending them in a Pro Tools–style workflow."},
    { category = "ProTools Essentials#1", name = "Shrink Left Edge TCui", path = "ProTools_Essentials/ShrinkLeftEdge-TCui.lua" , color={0.6,0.3,0.2,1} , same_line=true ,
    help="Trims the left edge of selected items by the nudge value from the shared Timecode UI, emulating Pro Tools–style item trimming."},
    { category = "ProTools Essentials#1", name = "Shrink Right Edge TCui", path = "ProTools_Essentials/ShrinkRightEdge-TCui.lua" , color={0.6,0.3,0.2,1} ,
    help="Trims the right edge of selected items by the nudge value from the shared Timecode UI, emulating Pro Tools–style item trimming."},
    { category = "ProTools Essentials#1", name = "Move Razor Area Backward TCui", path = "ProTools_Essentials/MoveRazorAreaBackward-TCui.lua" , color={0.3,0.7,0.3,1} , same_line=true,
    help="Moves all Razor Areas backward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style.",},
    { category = "ProTools Essentials#1", name = "Move Razor Area Forward TCui", path = "ProTools_Essentials/MoveRazorAreaForward-TCui.lua" , color={0.3,0.7,0.3,1}, same_line=true,
    help="Moves all Razor Areas forward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Razor Left Backward TCui", path = "ProTools_Essentials/MoveRazorLeftBackward-TCui.lua" , color={0.3,0.7,0.3,1}, same_line=true,
    help="Moves the LEFT edge of all Razor Areas backward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Razor Left Forward TCui", path = "ProTools_Essentials/MoveRazorLeftForward-TCui.lua", color={0.3,0.7,0.3,1} ,
    help="Moves the LEFT edge of all Razor Areas forward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Razor Right Backward TCui", path = "ProTools_Essentials/MoveRazorRightBackward-TCui.lua" , color={0.3,0.7,0.3,0.5} , same_line=true,
    help="Moves the RIGHT edge of all Razor Areas backward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Razor Right Forward TCui", path = "ProTools_Essentials/MoveRazorRightForward-TCui.lua" , color={0.3,0.7,0.3,0.5} , same_line=true,
     help="Moves the RIGHT edge of all Razor Areas forward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "RazorUp(Pt-P)", path = "ProTools_Essentials/RazorUp(Pt-P).lua" , color={0.2,0.4,0.8,1} , same_line=true,
    help="Moves the RIGHT edge of all Razor Areas backward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "RazorDown(Pt-M).lua", path = "ProTools_Essentials/RazorDown(Pt-M).lua" , color={0.2,0.4,0.8,1} ,
    help="Moves the RIGHT edge of all Razor Areas forward by the nudge value from the shared Timecode UI, creating Razor Areas from the Time Selection if none exist, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "SlipClipContentBackward-TCui", path = "ProTools_Essentials/SlipClipContentBackward-TCui.lua" , color={0.6,0.3,0.2,1}, same_line=true, 
    help="Slip content of Item Backward by the nudge value from the shared Timecode UI, emulating Pro Tools shortcut CTRL(-)"}, same_line=true,
    { category = "ProTools Essentials#1", name = "SlipClipContentForward-TCui", path = "ProTools_Essentials/SlipClipContentForward-TCui.lua" , color={0.6,0.3,0.2,1} ,
    help="Slip content of Item Forward by the nudge value from the shared Timecode UI, emulating Pro Tools shortcut CTRL(+)"},
    { category = "ProTools Essentials#1", name = "Move Time Selection Start Backward TCui", path = "ProTools_Essentials/MoveTimeSelectionStartBackward-TCui.lua" , color={0.3,0.3,0.3,1}, same_line=true,
    help="Moves the START of the current Time Selection Backward by the nudge value from the shared Timecode UI, ensuring it doesn’t pass the end, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Time Selection Start Forward TCui", path = "ProTools_Essentials/MoveTimeSelectionStartForward-TCui.lua" , color={0.3,0.3,0.3,1}  , same_line=true,
    help="Moves the START of the current Time Selection forward by the nudge value from the shared Timecode UI, ensuring it doesn’t pass the end, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Time Selection End Backward TCui", path = "ProTools_Essentials/MoveTimeSelEndBackward-TCui.lua" , color={0.3,0.3,0.3,0.5}, same_line=true,
    help="Moves the END of the current Time Selection backward by the nudge value from the shared Timecode UI, ensuring it doesn’t pass the start, Pro Tools–style."},
    { category = "ProTools Essentials#1", name = "Move Time Selection End Forward TCui", path = "ProTools_Essentials/MoveTimeSelEndForward-TCui.lua" , color={0.3,0.3,0.3,0.5},
    help="Moves the END of the current Time Selection forward by the nudge value from the shared Timecode UI, ensuring it doesn’t pass the start, Pro Tools–style."},

    
    -- ProTools Essentials#2
    { category = "ProTools Essentials#2", name = "Zoom Presets (PT-like)", path = "ProTools_Essentials/ZoomPresets(PT-like).lua" , color={0.3,0.7,0.3,0.5} , same_line=true,
    help="Provides a dockable Pro Tools–style panel with 4 horizontal+vertical zoom presets; ALT+Click saves the current zoom, click recalls it."},
    { category="ProTools Essentials#2", name="Zoom In", path="ProTools_Essentials/ZoomInHorizontal(PT-T).lua", color={0.3,0.7,0.3,1}, same_line=true,
    help="Zooms in horizontally centered on the cursor.\nEmulates Pro Tools' T shortcut."},
    { category="ProTools Essentials#2", name="Zoom Out", path="ProTools_Essentials/ZoomOutHorizontal(PT-R).lua", color={0.3,0.7,0.3,1}, 
    help="Zooms out horizontally in the Arrange view.\nEmulates Pro Tools' R shortcut."},
    

    { category = "ProTools Essentials#2", name = "Nudge Backward", path = "ProTools_Essentials/NudgeBackward.lua" , color={0.3,0.7,0.3,1} , same_line=true,
     help="Moves the edit cursor or selected items backward by a duration defined in the companion Unified PRE-POST-ROLL + Timecode UI (ImGui) panel."},
    { category = "ProTools Essentials#2", name = "Nudge Forward", path = "ProTools_Essentials/NudgeForward.lua" , color={0.3,0.7,0.3,1},
       help="Moves the edit cursor or selected items forward by a duration defined in the companion Unified PRE-POST-ROLL + Timecode UI (ImGui) panel."},
    { category = "ProTools Essentials#2", name = "Nudge Backward x10", path = "ProTools_Essentials/NudgeBackwardx10.lua" , color={0.3,0.7,0.3,1} , same_line=true,
       help="Moves the edit cursor or selected items backward by a duration derived from the companion Unified PRE-POST-ROLL + Timecode UI (ImGui) panel, scaled by ×10 for faster navigation."},
    { category = "ProTools Essentials#2", name = "Nudge Forward x10", path = "ProTools_Essentials/NudgeForwardx10.lua" , color={0.3,0.7,0.3,1},
     help="Moves the edit cursor or selected items forkward by a duration derived from the companion Unified PRE-POST-ROLL + Timecode UI (ImGui) panel, scaled by ×10 for faster navigation."},
    
    { category = "ProTools Essentials#2", name = "Play To Start", path = "ProTools_Essentials/PlayToStart.lua", color={0.3,0.7,0.3,1} , same_line=true ,
     help="Plays from a pre-roll point up to the start of the current Time Selection, emulating Pro Tools’ 'Play to In' function, automatically stopping at the In point."},
    { category = "ProTools Essentials#2", name = "Play From Start", path = "ProTools_Essentials/PlayFromStart.lua" , color={0.3,0.7,0.3,1} , same_line=true,
    help="Plays from the start of the current Time Selection and continues through the defined post-roll, exactly emulating Pro Tools’ 'Play From In' function, automatically stopping after the post-roll."},
    { category = "ProTools Essentials#2", name = "Play Thru Start", path = "ProTools_Essentials/PlayThruStart.lua" , color={0.3,0.7,0.3,1},
    help="Plays from a pre-roll, passes through the start of the Time Selection, and continues into post-roll, emulating Pro Tools’ 'Play Thru In' behavior."},
    
    { category = "ProTools Essentials#2", name = "Play To End", path = "ProTools_Essentials/PlayToEnd.lua", color={0.3,0.7,0.3,1} , same_line=true,
    help="Plays from a pre-roll and automatically stops at the end of the current Time Selection, emulating Pro Tools’ 'Play To Out' behavior."},
    { category = "ProTools Essentials#2", name = "Play From End", path = "ProTools_Essentials/PlayFromEnd.lua" , color={0.3,0.7,0.3,1} , same_line=true,
    help="Plays from the end of the Time Selection and continues into post-roll, emulating Pro Tools’ 'Play From Out' behavior with automatic stop."},
    { category = "ProTools Essentials#2", name = "Play Thru End", path = "ProTools_Essentials/PlayThruEnd.lua" , color={0.3,0.7,0.3,1},
    help="Plays from pre-roll through the end of the Time Selection and into post-roll, emulating Pro Tools’ 'Play Thru Out' behavior." },
    
                   -- Dummy buttons / separation
    { category = "PROTOOLS", name = "    ", path = nil, color={0.0,0.0,0.0,0} },
    
    { category = "ProTools Essentials#2", name = "RatingClip-Bad", path = "ProTools_Essentials/RatingClip-Bad.lua" , color={0.3,0.3,0.3,1}, same_line=true,
    help="Bad Take"},
    { category = "ProTools Essentials#2", name = "RatingClip-Ok", path = "ProTools_Essentials/RatingClip-Ok.lua" , color={0.3,0.3,0.3,1}  , same_line=true,
    help="Rating OK on the Item/clip *"},
    { category = "ProTools Essentials#2", name = "RatingClip-Good", path = "ProTools_Essentials/RatingClip-Good.lua" , color={0.3,0.3,0.3,0.5}, same_line=true,
    help="Good rating on the Item/clip **"},
    { category = "ProTools Essentials#2", name = "RatingClip-Best", path = "ProTools_Essentials/RatingClip-Best.lua" , color={0.3,0.3,0.3,0.5},
    help="Best rating on the Item/clip ***"},
    { category = "ProTools Essentials#2", name = "RatingClip-Reset", path = "ProTools_Essentials/RatingClip-Reset.lua" , color={0.3,0.3,0.3,0.5},
    help="Reset the rating on the Item/clip"},
    
  

    -- ProTools TAB
    { category = "ProTools TAB", name = "TAB   >⎮", path = "ProTools_TAB/(Protools)TAB.lua", color={0.18,0.54,0.18,1} , same_line=true,
    help="Brings Pro Tools–style TAB navigation to REAPER. Jump between item edges, fades, or transients depending on mode,"..
    "allowing fast, precise editing that mirrors the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "⎮<   TAB alt", path = "ProTools_TAB/(Protools)TAB(alt).lua", color={0.2,0.6,0.2,1},
    help="Brings Pro Tools–style reverse TAB navigation to REAPER. Jump backward through item edges, fades, or transients depending on mode,"..
    "allowing fast, precise reverse navigation that mirrors the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "[-ITEM-]>    (TAB Ctrl)", path = "ProTools_TAB/(ProTools)TAB-Ctrl.lua", color={0.45,0.27,0.63,1}, same_line=true,
    help="Brings Pro Tools–style Ctrl+TAB item selection to REAPER. Select the next item on a track quickly,"..
    "allowing fast, precise keyboard-driven navigation that mirrors the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "<[-ITEM-]    (TAB Ctrl(Alt))", path = "ProTools_TAB/(ProTools)TAB-Ctrl(Alt).lua", color={0.5,0.3,0.7,1},
    help="Brings Pro Tools–style Ctrl/Alt+TAB item selection to REAPER. Select the previous item on a track quickly,"..
    "allowing fast, precise reverse navigation that mirrors the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "(ProTools) TAB Shift", path = "ProTools_TAB/(ProTools)TAB-Shift.lua", color={0.7,0.18,0.18,1}, same_line=true,
    help="Brings Pro Tools–style Shift+TAB selection to REAPER. Extend item or time selection to fades, transients, or next item,"..
    "allowing fast, precise selection extensions that mirror the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "(ProTools) TAB AltShift", path = "ProTools_TAB/(ProTools)TAB-AltShift.lua", color={0.8,0.2,0.2,1},
    help="Brings Pro Tools–style Alt+Shift+TAB selection to REAPER. Extend item or time selection to the left, fades, or previous transients,"..
    "allowing fast, precise reverse selection that mirrors the familiar Pro Tools workflow."},
    { category = "ProTools TAB", name = "(Protools) TAB imgui", path = "ProTools_TAB/(Protools)TAB(imgui).lua", color={0.5,0.3,0.7,1},
    help="Acts as the main ImGui controller for the ProTools TAB system in REAPER. Display and manage Fade and TabToTransient states,"..
    "keeping all TAB actions synchronized and Pro Tools–like for a seamless workflow."},
                   -- Dummy buttons / separation
    { category = "ProTools TAB", name = "Call these 2 Scripts from a Toolbar in Reaper", path = nil, color={0.0,0.0,0.0,0} },

    
    { category = "ProTools TAB", name = "(Protools) TAB Fade Toggle ToolbarID", path = "ProTools_TAB/(Protools)TAB-FadeToggleToolbarID.lua", color={0.5,0.3,0.7,1}, same_line=true,
    help="Provides a toolbar button to toggle Fade mode in the ProTools TAB system. Quickly enable or disable fades,"..
    "keeping toolbar, ImGui, and keyboard shortcuts fully synchronized."},
    { category = "ProTools TAB", name = "(Protools) TAB Transient Toggle ToolbarID", path = "ProTools_TAB/(Protools)TAB-TransientToggleToolbarID.lua", color={0.5,0.3,0.7,1},
    help="Provides a toolbar button to toggle TabToTransient mode in the ProTools TAB system. Enables transient navigation,"..
    "while automatically disabling Fade and keeping toolbar, ImGui, and shortcuts synchronized."},
    { category = "ProTools TAB", name = "Shortcuts Scripts to activate buttons in Toolbars", path = nil, color={0.0,0.0,0.0,0}},

    { category = "ProTools TAB", name = "(Protools) TAB Fade Toggle Shortcut", path = "ProTools_TAB/(Protools)TAB-FadeToggleShortcut.lua", color={0.5,0.3,0.7,1}, same_line=true,
    help="Provides a keyboard shortcut to toggle Fade mode in the ProTools TAB system. Quickly enable or disable fades,"..
    "while keeping toolbar, ImGui, and ExtState fully synchronized for a Pro Tools–like workflow."},
    { category = "ProTools TAB", name = "(Protools) TAB Transient Toggle Shortcut", path = "ProTools_TAB/(Protools)TAB-TransientToggleShortcut.lua", color={0.5,0.3,0.7,1},
    help="Provides a keyboard shortcut to toggle TabToTransient mode in the ProTools TAB system. Enable transient navigation,"..
    "automatically disabling Fade and keeping toolbar, ImGui, and ExtState fully synchronized."},
    
    -- Protools Track
    { category = "Protools Track", name = "Insert New Track (PT)", path = "Protools_Track/InsertNewTrack(PT).lua" , color={0.2,0.4,0.8,1} , same_line=true,
    help="Inserts a new track in REAPER Pro Tools–style. Sets track height and opens the rename dialog,"..
    "allowing fast, streamlined track creation like in Pro Tools."},
    { category = "Protools Track", name = "Delete Track (As PT)", path = "Protools_Track/DelTrack(AsPT).lua" , color={0.2,0.4,0.8,1},
    help="Deletes selected tracks in REAPER Pro Tools–style. Empty tracks are removed immediately,"..
    "while tracks with items prompt for confirmation, ensuring safe deletion."},
    
    { category = "Protools Track", name = "Monos Tracks To ST", path = "Protools_Track/MonosTracks-ToST.lua" , color={0.2,0.4,0.8,1} , same_line=true ,
    help="Converts multiple mono items on a track into a stereo take structure Pro Tools–style,"..
    "preserving names and colors while streamlining the workflow for consolidated stereo takes."},
    { category = "Protools Track", name = "ST Tracks To Mono", path = "Protools_Track/STTracks-ToMono.lua" , color={0.2,0.4,0.8,1},
    help="Splits a stereo item into two mono items Pro Tools–style. Handles temporary tracks and folder states,"..
    "allowing precise and clean stereo-to-mono conversion workflows."},
    { category = "Protools Track", name = "Group Tracks (PT-CmdG)", path = "Protools_Track/GroupTracks(PT-CmdG).lua" , color={0.2,0.4,0.8,1},
    help="Groups selected tracks in REAPER Pro Tools–style. Emulates the Cmd+G behavior,"..
    "allowing fast, keyboard-driven track grouping like in Pro Tools."},
    
}

-- Palette de couleurs pour onglets (RGB)
local tab_palette = {
    {0.4,0.1,0.7},-- Documentations
    {0.0,0.0,0.0},--Speparator
    {0.8,0.3,0.3},-- Editing
    {0.7,0.2,0.2},-- Editing_Trim
    {0.0,0.0,0.0},--Separator
    {0.5,0.5,0.1},-- Field Recorder Workflow
    {0.5,0.5,0.1},-- Metadatas
    {0.0,0.0,0.0},--Separator
    {0.2,0.7,0.7},-- PROTOOLS
    {0.1,0.6,0.7},-- PROTOOLS Essentials#1
    {0.1,0.6,0.7},-- PROTOOLS Essentials#2
    {0.2,0.2,0.7},--Protools TAB
    {0.3,0.3,0.7},-- Protools Tracks
}

-- Organize scripts by category et assigner couleur aux onglets
local categories = {}
local cat_order = {}
local tab_colors = {}
local palette_index = 1

for _, s in ipairs(scripts) do
    if not categories[s.category] then
        categories[s.category] = {}
        table.insert(cat_order, s.category)
        tab_colors[s.category] = tab_palette[palette_index]
        palette_index = palette_index + 1
        if palette_index > #tab_palette then palette_index = 1 end
    end
    table.insert(categories[s.category], s)
end

-- MAIN LOOP
local function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 600, 450, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, "Mariow's Repository visualizer and launcher", true)

    if visible then
        if reaper.ImGui_BeginTabBar(ctx, "Categories") then
            for _, cat_name in ipairs(cat_order) do
                local scripts_in_cat = categories[cat_name]
                local color = tab_colors[cat_name] or {0.5,0.5,0.5,1}

                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),
                    reaper.ImGui_ColorConvertDouble4ToU32(color[1], color[2], color[3], 1))
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(),
                    reaper.ImGui_ColorConvertDouble4ToU32(
                        math.min(color[1]+0.2,1),
                        math.min(color[2]+0.2,1),
                        math.min(color[3]+0.2,1), 1))

                local opened = reaper.ImGui_BeginTabItem(ctx, cat_name)
                if opened then
                    for _, s in ipairs(scripts_in_cat) do
                        local clicked = ColoredButton(ctx, s.name, s.color, 280, 28)

                        -- ▶️ Help marker (?)
                        if s.help then
                            reaper.ImGui_SameLine(ctx)
                            ImGui_HelpMarker(ctx, s.help)
                        end

                        if clicked and s.path then
                            LaunchScript(s.path)
                        end

                        if s.same_line then
                            reaper.ImGui_SameLine(ctx)
                        else
                            Pad()
                        end
                    end

                    -- TEXTE EXPLICATIF pour Documentations
                    if cat_name == "Documentations" then
                        reaper.ImGui_PushFont(ctx, BIG_FONT, 30)
                        reaper.ImGui_TextWrapped(ctx,
                            "Thanks to these pages, you can browse and launch Mariow’s scripts,\n" ..
                            "better understand their purpose and features,\n" ..
                            "and explore an interactive representation of the repository.\n\nEnjoy!"
                        )
                        reaper.ImGui_PopFont(ctx)
                    end

                    reaper.ImGui_EndTabItem(ctx)
                end

                reaper.ImGui_PopStyleColor(ctx, 2)
            end
            reaper.ImGui_EndTabBar(ctx)
        end
        reaper.ImGui_End(ctx)
    end

    if open then reaper.defer(loop) end
end

loop()


