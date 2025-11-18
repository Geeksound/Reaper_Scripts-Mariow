--[[
@description ProTools TAB - Manual & Help (ImGui)
@version 1.1
@author Mariow
@changelog
    v1.1 (2025-06-09)
    - Added System Check tab
    - Added GitHub button
    - Added "Open Scripts Folder" button
    v1.0 (2025-06-08)
    - Initial release
@provides
    [main] ProTools_TAB/(Protools)TAB-Instructions.lua
@tags protools, tab, manual, doc, help, imgui
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@about
    # ProTools TAB – Manual & Help
    
    This script provides the complete installation guide, usage instructions,
    and system diagnostics for the “ProTools-like TAB system for REAPER”.
--]]

------------------------------------------------------------
-- IMGUI INIT
------------------------------------------------------------
local ctx = reaper.ImGui_CreateContext("ProTools TAB - Manual")
local FONT = reaper.ImGui_CreateFont("sans-serif", 14)
reaper.ImGui_Attach(ctx, FONT)

local function Heading(text)
    reaper.ImGui_PushFont(ctx, FONT, 12)
    reaper.ImGui_TextColored(ctx, 0xFFA500FF, text)
    reaper.ImGui_PopFont(ctx)
end

local function SectionTitle(text)
    reaper.ImGui_TextColored(ctx, 0xFFFF00FF, text)
end

local function Pad()
    reaper.ImGui_Dummy(ctx, 0, 6)
end

------------------------------------------------------------
-- TAB: INSTALLATION
------------------------------------------------------------
local function Tab_Installation()
    Heading("Installation – ProTools TAB Pack")
    Pad()

    SectionTitle("1. Install the Pack into REAPER")
    reaper.ImGui_TextWrapped(ctx, [[
Place the `ProTools_TAB` folder into:
    • Scripts/
    • or REAPER Resource Folder/User Scripts/

The pack contains:
    - The main ImGui TAB interface
    - Keyboard shortcut scripts
    - Toolbar button scripts
]])
    Pad()

    SectionTitle("2. Import via ReaPack (optional)")
    reaper.ImGui_TextWrapped(ctx, [[
The system is fully ReaPack-compatible.

You may:
    - Install automatically using your own ReaPack index
    - Or import the scripts manually through the Action List
]])
    Pad()

    SectionTitle("3. Add toolbar buttons")
    reaper.ImGui_TextWrapped(ctx, [[
Add these scripts to a toolbar:
    ✔ TAB-FadeToggleToolbarID
    ✔ TAB-TransientToggleToolbarID

They become two synchronized toggle buttons:
    - Fade
    - TabToTransient
    
IMPORTANT:
Do NOT place the main ImGui script in the toolbar (it should run separately).
]])
    Pad()

    SectionTitle("4. Assign keyboard shortcuts (optional)")
    reaper.ImGui_TextWrapped(ctx, [[
You may assign shortcuts to:
    • TAB-FadeToggleShortcut
    • TAB-TransientToggleShortcut

Shortcuts remain synchronized with:
    - Toolbar buttons
    - ImGui interface
    - External scripts (ALT click)
]])
end

------------------------------------------------------------
-- TAB: USAGE
------------------------------------------------------------
local function Tab_Usage()
    Heading("Using the ProTools TAB System")
    Pad()

    SectionTitle("1. The Main Script")
    reaper.ImGui_TextWrapped(ctx, [[
The "(Protools)TAB(imgui)" script shows:
    - Fade state
    - TabToTransient state
    - Available interactions: Click / ALT / SHIFT

The window may remain open or docked.

It continuously synchronizes the global states via ExtState.
]])
    Pad()

    SectionTitle("2. ImGui Button Behavior")
    reaper.ImGui_TextWrapped(ctx, [[
• Normal Click:
        → Toggles Fade
        → Disables TabToTransient

• ALT + Click:
        → Enables TabToTransient
        → Disables Fade (Pro Tools behavior)

• SHIFT + Click:
        → Opens REAPER’s built-in "Transient Detection" window
]])
    Pad()

    SectionTitle("3. Toolbar Buttons")
    reaper.ImGui_TextWrapped(ctx, [[
The two toolbar buttons:
    - Fade
    - TabToTransient

are always synchronized with:
    ✔ The ImGui script  
    ✔ Keyboard shortcuts  
    ✔ ExtState values  
]])
    Pad()

    SectionTitle("4. Keyboard Shortcuts")
    reaper.ImGui_TextWrapped(ctx, [[
Shortcut scripts behave exactly like toolbar buttons:

    - FadeToggleShortcut → toggles Fade
    - TransientToggleShortcut → toggles TabToTransient (and adjusts Fade)
]])
end

------------------------------------------------------------
-- TAB: ADVANCED (DEV INFO)
------------------------------------------------------------
local function Tab_Advanced()
    Heading("Internal Logic (for developers)")
    Pad()

    SectionTitle("ExtStates used")
    reaper.ImGui_TextWrapped(ctx, [[
Namespace: "ProTools_TAB"

Keys:
    - Fade = "0" / "1"
    - TabToTransient = "0" / "1"
    - ALT_CLICK_REQUESTED = "0" / "1" (external Alt-click trigger)
]])
    Pad()

    SectionTitle("Synchronization Mechanism")
    reaper.ImGui_TextWrapped(ctx, [[
The ImGui script re-reads ExtStates every cycle.

Other scripts:
    - write updated values to ExtState
    - update toolbar states using SetToggleCommandState()
    - refresh toolbars visually through RefreshToolbar2()
]])
    Pad()

    SectionTitle("ALT_CLICK_REQUESTED")
    reaper.ImGui_TextWrapped(ctx, [[
Allows external scripts to trigger TabToTransient without user interaction.

Usage:
    • Write ALT_CLICK_REQUESTED = "1"
    • The ImGui script detects this flag
    • It activates TabToTransient and resets the flag
]])
end

------------------------------------------------------------
-- TAB: SYSTEM CHECK
------------------------------------------------------------
local function Tab_SystemCheck()
    Heading("System Check – Installation Status")
    Pad()

    -- Updated path for your structure:
    local script_path = reaper.GetResourcePath() .. "/Scripts/Mariow Scripts/ProTools_TAB/"

    local files = {
        { name = "Main ImGui Script", file = "(Protools)TAB(imgui).lua" },
        { name = "Fade Shortcut", file = "(Protools)TAB-FadeToggleShortcut.lua" },
        { name = "Transient Shortcut", file = "(Protools)TAB-TransientToggleShortcut.lua" },
        { name = "Fade Toolbar Button", file = "(Protools)TAB-FadeToggleToolbarID.lua" },
        { name = "Transient Toolbar Button", file = "(Protools)TAB-TransientToggleToolbarID.lua" },
    }

    SectionTitle("Checking files in: Scripts/Mariow Scripts/ProTools_TAB/")
    Pad()

    for _, s in ipairs(files) do
        local f = io.open(script_path .. s.file, "r")
        if f then
            io.close(f)
            reaper.ImGui_TextColored(ctx, 0x00FF00FF, "✔  " .. s.name .. " — Found")
        else
            reaper.ImGui_TextColored(ctx, 0xFF0000FF,
                "❌  " .. s.name .. " — Missing (" .. s.file .. ")")
        end
    end

    Pad()
    SectionTitle("If files are missing:")
    reaper.ImGui_TextWrapped(ctx, [[
Ensure your structure looks like this:

REAPER Resource Path/
  └── Scripts/
        └── Mariow Scripts/
              └── ProTools_TAB/
                    • (Protools)TAB(imgui).lua
                    • (Protools)TAB-FadeToggleToolbarID.lua
                    • (Protools)TAB-TransientToggleToolbarID.lua
                    • (Protools)TAB-FadeToggleShortcut.lua
                    • (Protools)TAB-TransientToggleShortcut.lua
]])

    Pad()
    if reaper.ImGui_Button(ctx, "Open Scripts Folder", 180, 28) then
        reaper.CF_ShellExecute(reaper.GetResourcePath() .. "/Scripts/Mariow Scripts/")
    end
end


------------------------------------------------------------
-- TAB: ABOUT
------------------------------------------------------------
local function Tab_About()
    Heading("About the ProTools TAB Pack")
    Pad()

    reaper.ImGui_TextWrapped(ctx, [[
Created by: Mariow  
Year: 2025  
Repository: GitHub – Geeksound/Reaper_Scripts-Mariow

This system faithfully recreates Pro Tools-style TAB behavior:
    - Fade mode
    - Tab to Transient
    - ALT / SHIFT logic
    - Full synchronization between Toolbar, Shortcuts and ImGui

Fully non-destructive and 100% ReaScript.
]])

    Pad()
    if reaper.ImGui_Button(ctx, "Open GitHub Repository", 220, 28) then
        reaper.CF_ShellExecute("https://github.com/Geeksound/Reaper_Scripts-Mariow")
    end
end

------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------
local function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 650, 520, reaper.ImGui_Cond_FirstUseEver())
    local visible, open = reaper.ImGui_Begin(ctx, "ProTools TAB – Documentation", true)

    if visible then
        if reaper.ImGui_BeginTabBar(ctx, "tabs") then

            if reaper.ImGui_BeginTabItem(ctx, "Installation") then
                Tab_Installation()
                reaper.ImGui_EndTabItem(ctx)
            end

            if reaper.ImGui_BeginTabItem(ctx, "Usage") then
                Tab_Usage()
                reaper.ImGui_EndTabItem(ctx)
            end

            if reaper.ImGui_BeginTabItem(ctx, "Advanced") then
                Tab_Advanced()
                reaper.ImGui_EndTabItem(ctx)
            end

            if reaper.ImGui_BeginTabItem(ctx, "System Check") then
                Tab_SystemCheck()
                reaper.ImGui_EndTabItem(ctx)
            end

            if reaper.ImGui_BeginTabItem(ctx, "About") then
                Tab_About()
                reaper.ImGui_EndTabItem(ctx)
            end

            reaper.ImGui_EndTabBar(ctx)
        end

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(loop)
    end
end

loop()

