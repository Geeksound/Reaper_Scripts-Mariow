--[[
@description Set Pre-Roll, Post-Roll and Nudge values for ProTools-like scripts
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-06-07)
  - Initial release
@provides
  [main] ProTools_Essentials/Set_Rolls_And_Nudge_Settings.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags settings, editing, transport, nudge, (protools-like)
@about
  # Set_Rolls_And_Nudge_Settings (ProTools-like)
  
  Central configuration script for setting **Pre-Roll**, **Post-Roll** and **Nudge**
  values used across the entire ProTools-like script suite.
  
  ## 🟦 Pre-Roll / Post-Roll
  The values you configure here are automatically used by all playback-related
  scripts in the collection, including:
  
  - PlayFromStart  
  - PlayFromEnd  
  - PlayThruStart  
  - PlayThruEnd  
  - PlayToStart  
  - PlayToEnd  
  
  This ensures consistent, Pro Tools–style transport behavior across the whole workflow.
  
  ## 🟩 Nudge Value
  The configured **Nudge amount** is also used by the companion scripts:
  
  - Nudge Forward  
  - Nudge Backward  
  
  allowing uniform movement amounts across all ProTools-like navigation tools.
  
  ## 📝 Notes
  This script should be run whenever you want to adjust Pre-Roll, Post-Roll,
  or Nudge settings globally for the entire ProTools_Essentials suite.
--]]


------------------------------------------------------------
-- 🔧 CONTEXT & WINDOW SETTINGS
------------------------------------------------------------
local ctx = reaper.ImGui_CreateContext('RS Unified Panel')

local green = 0x00FF00FF
local orange = 0xFF8800FF
local grey   = 0x555555FF

local win_flags = reaper.ImGui_WindowFlags_AlwaysAutoResize()
                + reaper.ImGui_WindowFlags_NoTitleBar()
                + reaper.ImGui_WindowFlags_NoCollapse()


------------------------------------------------------------
-- 🔧 LOAD STORED VALUES
------------------------------------------------------------
-- Pre/Post Roll
local RS_PreRoll      = tonumber(reaper.GetExtState("RS_PrePostRoll", "PreRoll")) or 2.0
local RS_PostRoll     = tonumber(reaper.GetExtState("RS_PrePostRoll", "PostRoll")) or 2.0
local RS_EnablePreRoll  = reaper.GetExtState("RS_PrePostRoll", "EnablePreRoll")  == "true"
local RS_EnablePostRoll = reaper.GetExtState("RS_PrePostRoll", "EnablePostRoll") == "true"

local bufPre  = tostring(RS_PreRoll)
local bufPost = tostring(RS_PostRoll)

-- Timecode
local tc = reaper.GetExtState("TimecodeUI", "tc")
if tc == nil or tc == "" then tc = "00:00:00:00" end


------------------------------------------------------------
-- 🔧 SAVE FUNCTIONS
------------------------------------------------------------
local function save_prepost()
    reaper.SetExtState("RS_PrePostRoll", "PreRoll", bufPre, true)
    reaper.SetExtState("RS_PrePostRoll", "PostRoll", bufPost, true)
    reaper.SetExtState("RS_PrePostRoll", "EnablePreRoll", RS_EnablePreRoll and "true" or "false", true)
    reaper.SetExtState("RS_PrePostRoll", "EnablePostRoll", RS_EnablePostRoll and "true" or "false", true)
end

local function save_tc()
    reaper.SetExtState("TimecodeUI", "tc", tc, true)
end



------------------------------------------------------------
-- 🚀 MAIN GUI LOOP
------------------------------------------------------------
local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, "##UnifiedPanel", true, win_flags)

    if visible then

        ------------------------------------------------------------
        -- SECTION 1 — PRE/POST ROLL
        ------------------------------------------------------------
       --reaper.ImGui_Text(ctx, " Pre / Post Roll")
       --reaper.ImGui_Separator(ctx)

        -- === Pre-Roll Input ===
        reaper.ImGui_SetNextItemWidth(ctx, 30)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), green)
        local changed_pre
        changed_pre, bufPre = reaper.ImGui_InputText(ctx, "##PreRoll", bufPre, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
        reaper.ImGui_PopStyleColor(ctx)

        if changed_pre then
            bufPre = tostring(tonumber(bufPre) or RS_PreRoll)
            save_prepost()
        end

        reaper.ImGui_SameLine(ctx)

        -- === Toggle Pre ===
        local col_pre = RS_EnablePreRoll and orange or grey
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), col_pre)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), col_pre)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  col_pre)
        local click_pre = reaper.ImGui_Button(ctx, "PRE", 35, 20)
        reaper.ImGui_PopStyleColor(ctx, 3)

        if click_pre then
            RS_EnablePreRoll = not RS_EnablePreRoll
            save_prepost()
        end

        reaper.ImGui_SameLine(ctx)

        -- === Toggle Post ===
        local col_post = RS_EnablePostRoll and orange or grey
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), col_post)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), col_post)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  col_post)
        local click_post = reaper.ImGui_Button(ctx, "POST", 35,20)
        reaper.ImGui_PopStyleColor(ctx, 3)

        if click_post then
            RS_EnablePostRoll = not RS_EnablePostRoll
            save_prepost()
        end

        reaper.ImGui_SameLine(ctx)

        -- === Post-Roll Input ===
        reaper.ImGui_SetNextItemWidth(ctx, 30)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), green)
        local changed_post
        changed_post, bufPost = reaper.ImGui_InputText(ctx, "##PostRoll", bufPost, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
        reaper.ImGui_PopStyleColor(ctx)

        if changed_post then
            bufPost = tostring(tonumber(bufPost) or RS_PostRoll)
            save_prepost()
        end


        ------------------------------------------------------------
        -- SECTION 2 — TIMECODE
        ------------------------------------------------------------
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Separator(ctx)
        --reaper.ImGui_Text(ctx, " Nudge Cursor&Item(focus)")
        
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), green)
        reaper.ImGui_SetNextItemWidth(ctx, 150)

        local changed_tc
        --changed_tc, tc = reaper.ImGui_InputText(ctx,"##tc_input", tc, 32)
        reaper.ImGui_SetNextItemWidth(ctx, 150) -- largeur du champ
        
        local win_w = reaper.ImGui_GetWindowWidth(ctx)
        local item_w = 150
        local cursor_x = (win_w - item_w) * 0.5
        
        reaper.ImGui_SetCursorPosX(ctx, cursor_x)
        
        local changed_tc
        changed_tc, tc = reaper.ImGui_InputText(ctx, "##tc_input", tc, 32)
        

        if changed_tc then save_tc() end

        reaper.ImGui_PopStyleColor(ctx)

        ------------------------------------------------------------
        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    else
        save_prepost()
        save_tc()
        reaper.ImGui_DestroyContext(ctx)
    end
end

reaper.defer(loop)

