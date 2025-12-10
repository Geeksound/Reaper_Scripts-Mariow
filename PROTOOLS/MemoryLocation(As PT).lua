--[[
@description Jump to marker by number or name (PT like)
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-10)
  - Initial release
  - Minimal ImGui window with auto-focus
  - Jump to marker by number or by name
  - Press Enter to validate and auto-close the window
@provides
  [main] PROTOOLS/MemoryLocation(as PT).lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags markers, navigation, workflow, gui, imgui
@about
  # Marker Jump Minimal (ImGui)
  A minimal and discrete ImGui-based utility that allows jumping to any REAPER
  marker by typing either its number or its name.  
  Press **Enter** to validate and the window closes automatically.
  
  Features:
  - Super minimal ImGui interface (no title, auto-resize)
  - Auto-focus in the input field
  - Jump to marker by number or by exact name
  - Window closes automatically once Enter is pressed
  
  Ideal for fast workflows where precise marker navigation is required.
--]]



local ctx = reaper.ImGui_CreateContext('Marker Jump Minimal')
local input = ""
local window_open = true

function loop()
    if not window_open then return end

    reaper.ImGui_SetNextWindowSize(ctx, 70, 60, reaper.ImGui_Cond_Once())

    local flags = reaper.ImGui_WindowFlags_AlwaysAutoResize()
        | reaper.ImGui_WindowFlags_NoTitleBar()
        | reaper.ImGui_WindowFlags_NoCollapse()

    local visible, open = reaper.ImGui_Begin(ctx, '##Marker_window', true, flags)

    if visible then
        
        -- Autofocus du champ texte
        reaper.ImGui_SetKeyboardFocusHere(ctx)

        -- Input avec validation par ENTER
        local input_flags = reaper.ImGui_InputTextFlags_EnterReturnsTrue()
        local enter_pressed, new_val =
            reaper.ImGui_InputText(ctx, "N° or Name then Press Enter", input, input_flags)
        input = new_val

        -- ENTER ↓↓↓
        if enter_pressed then
            gotoMarker(input)
            window_open = false  -- ferme après validation
        end

        reaper.ImGui_End(ctx)
    end

    if window_open then
        reaper.defer(loop)
    end
end


function gotoMarker(val)
    local num = tonumber(val)

    if num then
        reaper.GoToMarker(reaper.GetCurrentProjectInLoadSave(), num, false)
        return
    end

    local i = 0
    while true do
        local ret, isrgn, pos, rgnend, name, markid = reaper.EnumProjectMarkers(i)
        if ret == 0 then break end
        
        if name == val then
            reaper.GoToMarker(reaper.GetCurrentProjectInLoadSave(), markid, false)
            break
        end
        
        i = i + 1
    end
end

reaper.defer(loop)

