--[[
@description ItemControlBoard - Interactive Media Item Palette
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-11-11)
  - Fixed window close safety on ReaImGui
  - Improved color palette preview
  - Optimized repeat button behavior
@provides
  [main] Editing/ItemControlBoard.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags item, editing, gui, color, palette, tool
@about
  # ItemControlBoard

  Interactive control panel for selected items in REAPER.

  Features:
  - Move, trim (Left/Right/Both), pitch, timestretch, gain, color, fades
  - ALT reverses the function of each action for better ergonomics
  - Momentary/Latching button modes – holding a button keeps the action repeating
  - Built-in color palette system (Color Item button + preview square)
  
  Developed with the help of GitHub Copilot and ChatGPT.
--]]

local ctx = reaper.ImGui_CreateContext("ItemControlBoard (by Mariow)")

--========================================
-- 🔹 GitHub Thumbnail
--========================================
local github_link = "https://github.com/Geeksound/Reaper_Scripts-Mariow"
-- 🔹 GitHub Thumbnail (optional image)
local vignette_path = reaper.GetResourcePath() .. '/Scripts/vignette.png'
local vignette_image = nil
if reaper.file_exists and reaper.file_exists(vignette_path) then
    vignette_image = reaper.ImGui_CreateImage(vignette_path)
end


local function open_github_link()
    if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(github_link)
    else
        reaper.ShowMessageBox("⚠️ Unable to open the link.\nSWS extension is required.", "Error", 0)
    end
end

-- keep window-open flag so ImGui can signal closure
local open = true

-- Repeat button system
local repeatTimers = {}
local function repeatButton(ctx, key, label, func, initDelay, repeatInterval)
    initDelay = initDelay or 0.1
    repeatInterval = repeatInterval or 0.05
    reaper.ImGui_Button(ctx, label)
    local down = reaper.ImGui_IsItemActive(ctx)
    local t = reaper.time_precise()
    if not repeatTimers[key] then repeatTimers[key] = {lastTime=0, pressed=false} end
    local state = repeatTimers[key]

    if down then
        if not state.pressed then
            func()
            state.lastTime = t
            state.pressed = true
        elseif t - state.lastTime >= initDelay then
            if t - state.lastTime >= repeatInterval then
                func()
                state.lastTime = t
            end
        end
    else
        state.pressed = false
    end
end

-- Utility function
local function getItem() return reaper.GetSelectedMediaItem(0,0) end

-- Move vertically (tracks)
local function moveVertically(item, up)
    if not item then return end
    local track = reaper.GetMediaItem_Track(item)
    if not track then return end
    local idx = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")-1
    local targetTrack = reaper.GetTrack(0, idx + (up and -1 or 1))
    if targetTrack then
        reaper.MoveMediaItemToTrack(item,targetTrack)
        reaper.UpdateArrange()
    end
end


-- Pitch (take pitch)
local function changePitch(item,up)
    if not item then return end
    local take = reaper.GetActiveTake(item)
    if take then
        local cur = reaper.GetMediaItemTakeInfo_Value(take,"D_PITCH")
        reaper.SetMediaItemTakeInfo_Value(take,"D_PITCH",cur + (up and 1 or -1))
    end
end

-- Stretch (scale length)
local function stretchItem(item,up)
    if not item then return end
    local len = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
    if len and len > 0 then
        reaper.SetMediaItemInfo_Value(item,"D_LENGTH",len * (up and 1.05 or 0.95))
    end
end

-- Gain (take volume)
local function changeGain(item,up)
    if not item then return end
    local take = reaper.GetActiveTake(item)
    if take then
        local cur = reaper.GetMediaItemTakeInfo_Value(take,"D_VOL")
        local db = 0.1
        reaper.SetMediaItemTakeInfo_Value(take,"D_VOL",cur * 10^((up and 1 or -1)*db/20))
    end
end

-- Color lighten/darken (use ColorFromNative to extract components)
local function changeColor(item,lighten)
    if not item then return end
    local col = reaper.GetMediaItemInfo_Value(item,"I_CUSTOMCOLOR") or 0
    local r,g,b
    if col == 0 then
        r,g,b = 1,1,1
    else
        local rr,gg,bb = reaper.ColorFromNative and reaper.ColorFromNative(col) or nil
        if rr and gg and bb then
            r,g,b = rr,gg,bb
        else
            local raw = col & 0xFFFFFF
            r = ((raw >> 16) & 255) / 255
            g = ((raw >> 8) & 255) / 255
            b = (raw & 255) / 255
        end
    end
    local delta = (lighten and 0.05) or -0.05
    r = math.min(1, math.max(0, r + delta))
    g = math.min(1, math.max(0, g + delta))
    b = math.min(1, math.max(0, b + delta))
    local rr = math.floor(r * 255 + 0.5)
    local gg = math.floor(g * 255 + 0.5)
    local bb = math.floor(b * 255 + 0.5)
    local newCol = reaper.ColorToNative(rr, gg, bb) | 0x1000000
    reaper.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR", newCol)
    reaper.UpdateArrange()
end

-- Change fade lengths (fadeIn = true => D_FADEINLEN, else D_FADEOUTLEN)
local function changeFade(item, delta, fadeIn)
    if not item then return end
    local key = fadeIn and "D_FADEINLEN" or "D_FADEOUTLEN"
    local cur = reaper.GetMediaItemInfo_Value(item, key) or 0
    local new = math.max(0, cur + delta)
    reaper.SetMediaItemInfo_Value(item, key, new)
    reaper.UpdateArrange()
end

-- 🎨 PALETTE GUI
local palette_gui = {
  {0.05,0.15,0.75},{0.10,0.20,0.80},{0.15,0.30,0.85},{0.20,0.40,0.90},{0.25,0.50,0.95},
  {0.00,0.55,1.00},{0.10,0.65,0.95},{0.20,0.75,0.90},{0.25,0.85,0.95},{0.30,0.95,1.00},
  {0.00,0.45,0.20},{0.10,0.55,0.25},{0.20,0.65,0.30},{0.30,0.75,0.35},{0.40,0.85,0.40},
  {0.50,0.95,0.45},{0.55,0.85,0.35},{0.60,0.75,0.25},{0.55,0.65,0.20},{0.50,0.55,0.10},
  {1.00,1.00,0.30},{1.00,0.95,0.20},{1.00,0.90,0.10},{1.00,0.85,0.00},{1.00,0.75,0.00},
  {1.00,0.65,0.00},{1.00,0.55,0.00},{1.00,0.45,0.00},{1.00,0.35,0.00},{1.00,0.25,0.00},
  {1.00,0.15,0.15},{1.00,0.25,0.30},{1.00,0.35,0.45},{1.00,0.45,0.60},{1.00,0.55,0.70},
  {1.00,0.65,0.80},{1.00,0.70,0.85},{0.95,0.60,0.90},{0.90,0.50,0.95},{0.85,0.40,1.00},
  {0.75,0.30,0.85},{0.65,0.25,0.75},{0.55,0.20,0.65},{0.45,0.15,0.55},{0.35,0.10,0.45},
  {0.45,0.25,0.25},{0.50,0.30,0.20},{0.45,0.25,0.15},{0.40,0.20,0.10},{0.30,0.15,0.05},
  {0.00,0.00,0.00},{1.00,1.00,1.00}
}

local paletteIndex = 1

local function setColorFromPalette(item, idx)
    if not item then return end
    local c = palette_gui[idx]
    if not c then return end
    local r = math.floor(c[1] * 255 + 0.5)
    local g = math.floor(c[2] * 255 + 0.5)
    local b = math.floor(c[3] * 255 + 0.5)
    local color = reaper.ColorToNative(r, g, b) | 0x1000000
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
    reaper.UpdateArrange()
end

-- Main GUI loop
local function loop()
    reaper.ImGui_SetNextWindowSize(ctx,320,620,reaper.ImGui_Cond_FirstUseEver())
    local visible, new_open = reaper.ImGui_Begin(ctx,"ItemControlBoard (by Mariow)", open)
    if new_open ~= nil then open = new_open end

    if visible then
        local item = getItem()
        local mods = reaper.ImGui_GetKeyMods(ctx)
        local isAlt = (mods & reaper.ImGui_Mod_Alt()) ~= 0

        if item then
            -- MOVE
            reaper.ImGui_Text(ctx,"Move")
            repeatButton(ctx,"moveVert", isAlt and "⬇ Dwn Track" or "⬆ Up Track", function() moveVertically(item, not isAlt) end)
            repeatButton(ctx,"move-Hor", isAlt and "Move Right" or "Move Left", function()
                local cmd = isAlt and 40119 or 40120
                reaper.Main_OnCommand(cmd, 0)
            end)

            -- TRIM (native REAPER commands)
            reaper.ImGui_Text(ctx,"Trim")
            repeatButton(ctx,"trimLeft", isAlt and "Shrink Left" or "Grow   Left", function()
                local cmd = isAlt and 40226 or 40225
                reaper.Main_OnCommand(cmd, 0)
            end)
            repeatButton(ctx,"trimRight", isAlt and "Shrink Right" or "Grow Right", function()
                local cmd = isAlt and 40227 or 40228
                reaper.Main_OnCommand(cmd, 0)
            end)
            repeatButton(ctx,"trimBoth", isAlt and "Shrink Both" or "Grow  Both", function()
                local cmdLeft = isAlt and 40226 or 40225
                local cmdRight = isAlt and 40227 or 40228
                reaper.Main_OnCommand(cmdLeft, 0)
                reaper.Main_OnCommand(cmdRight, 0)
            end)

            -- PITCH / STRETCH
            reaper.ImGui_Text(ctx,"Pitch / Stretch")
            repeatButton(ctx,"pitch", isAlt and "🎶 Pitch Down" or "🎵 Pitch  Up", function() changePitch(item, not isAlt) end)
            repeatButton(ctx,"stretch", isAlt and "📐 Compress" or "📏 T.Stretch", function() stretchItem(item, not isAlt) end)

            -- GAIN
            reaper.ImGui_Text(ctx,"Gain")
            repeatButton(ctx,"gain", isAlt and "🔇 Lower Gain" or "🔊 Raise Gain", function() changeGain(item, not isAlt) end)
            
            -- FADES
            reaper.ImGui_Text(ctx,"Fades")
            repeatButton(ctx,"fadeIn", isAlt and "🔽 FadeIn -" or "🔼 FadeIn +", function()
                changeFade(item, isAlt and -0.01 or 0.01, true)
            end)
            repeatButton(ctx,"fadeOut", isAlt and "🔼 FadeOut -" or "🔽 FadeOut +", function()
                changeFade(item, isAlt and -0.01 or 0.01, false)
            end)
            repeatButton(ctx,"cycleFade", isAlt and "Cycle  F.out" or "Cycle F.in", function()
                local cmd = isAlt and 41527 or 41520
                reaper.Main_OnCommand(cmd, 0)
            end)
            
            
            reaper.ImGui_Separator(ctx)
            
            reaper.ImGui_Separator(ctx)
            -- COLOR PALETTE
            reaper.ImGui_Text(ctx,"")
            local c = palette_gui[paletteIndex]
            if c then
                local cu = reaper.ImGui_ColorConvertDouble4ToU32(c[1], c[2], c[3], 1.0)
                reaper.ImGui_SameLine(ctx, 0,30)
                reaper.ImGui_ColorButton(ctx, "##colorPreview", cu)
            end
            if reaper.ImGui_Button(ctx, isAlt and "⬅ Prev Color" or "➡ Next Color") then
                if isAlt then
                    paletteIndex = (paletteIndex - 2) % #palette_gui + 1
                else
                    paletteIndex = (paletteIndex % #palette_gui) + 1
                end
                setColorFromPalette(item, paletteIndex)
            end
            
            repeatButton(ctx,"color", isAlt and "🌑 Darken Color" or "🌕 Light Color", function() changeColor(item, not isAlt) end)
            
            reaper.ImGui_Separator(ctx)
            -------------------------------------------
        else
            reaper.ImGui_Text(ctx,"No item selected")
        end
            if vignette_image then
               -- ✅ Si la vignette existe, on affiche le bouton image
              if reaper.ImGui_ImageButton(ctx, 'vignette_github_btn', vignette_image, 70, 70) then
                open_github_link()
              end
            else
            --  Si la vignette est absente, on affiche un bouton "Open"
              if reaper.ImGui_Button(ctx, "Open", 50, 24) then
                open_github_link()
               end
            end
        reaper.ImGui_End(ctx)
    else
        -- still call End to keep ImGui state consistent
        reaper.ImGui_End(ctx)
    end

    -- Si l'utilisateur a cliqué sur la croix, on arrête la boucle.
    if open then
        reaper.defer(loop)
    else
        -- Appeler la fonction de destruction seulement si elle existe dans cette version de ReaImGui
        if reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        elseif reaper.ImGui_Destroy then
            -- Certaines versions exposent un nom différent
            reaper.ImGui_Destroy(ctx)
        end
        ctx = nil
    end
end

loop()
