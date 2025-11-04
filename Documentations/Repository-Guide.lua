--[[
@description Repository-Guide of Scripts by Mariow in Geeksound hosted by GitHub.com
@version 1.2
@author Mariow
@changelog
    V1.2 (2025-11-04)
    - Color change over a button
    v1.1 (2025-06-10)
    - Ajout d'un bouton pour accéder au guide audio_conforming_guide.md
    v1.0 (2025-06-09)
    - Initial release
@provides
    [main] Documentations/Repository-Guide.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags Scripts, Guide
@about
    # Repository-Guide
    Script with links Buttons to my repository guide and instructions in Reaper 7.0.
    This script was developed with the help of GitHub Copilot.
--]]

local url_pdf = "https://github.com/Geeksound/Reaper_Scripts-Mariow/raw/main/mariow.pdf"
local url_repo = "https://github.com/Geeksound/Reaper_Scripts-Mariow"
local url_audio_guide = "https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Documentations/audio_conforming_guide.md"
local title = "Mariow Guide and Repository"
local btn1_txt = "📄 Download PDF Repository-Guide"
local btn2_txt = "🌐 Open Geeksound GitHub"
local btn3_txt = "🎵 Audio Conforming Guide"

local was_mouse_down = false

function CenterWindow(w, h)
    local screen_w, screen_h = 1280, 720
    gfx.init(title, w, h, 0, (screen_w - w)/2, (screen_h - h)/2)
end

function DrawButton(x, y, w, h, txt, hover, btn_id)
    if hover then
        -- Couleur au survol selon le bouton
        if btn_id == 1 then
            gfx.set(1, 0.4, 0.2, 1)  -- bouton PDF : orange
        elseif btn_id == 2 then
            gfx.set(0.2, 1, 0.3, 1)  -- bouton GitHub : vert
        elseif btn_id == 3 then
            gfx.set(0.9, 0.1, 0.9, 1) -- bouton Audio Guide : violet
        end
    else
        gfx.set(0.2, 0.6, 0.9, 1) -- couleur normale (bleu)
    end

    gfx.roundrect(x, y, w, h, 12, 1)
    gfx.setfont(1, "Arial", 18, 'b', 0)
    gfx.set(1,1,1,1)
    local tw = gfx.measurestr(txt)
    gfx.x = x + (w - tw)/2
    gfx.y = y + (h - 20)/2
    gfx.drawstr(txt)
end

function Main()
    gfx.set(0.18, 0.22, 0.34, 1)
    gfx.rect(0, 0, gfx.w, gfx.h, 1)

    -- Title
    gfx.set(1, 1, 1, 1)
    gfx.setfont(1, "Arial", 22, 'b', 0)
    local wt = gfx.measurestr(title)
    gfx.x = (gfx.w - wt) / 2
    gfx.y = 32
    gfx.drawstr(title)

    -- Buttons
    local btn_w, btn_h = 300, 44
    local spacing = 18
    local btn1_x = (gfx.w - btn_w) / 2
    local btn1_y = gfx.h / 2 - btn_h - spacing
    local btn2_x = btn1_x
    local btn2_y = gfx.h / 2
    local btn3_x = btn1_x
    local btn3_y = gfx.h / 2 + btn_h + spacing

    local mx, my = gfx.mouse_x, gfx.mouse_y
    local hover1 = mx > btn1_x and mx < btn1_x + btn_w and my > btn1_y and my < btn1_y + btn_h
    local hover2 = mx > btn2_x and mx < btn2_x + btn_w and my > btn2_y and my < btn2_y + btn_h
    local hover3 = mx > btn3_x and mx < btn3_x + btn_w and my > btn3_y and my < btn3_y + btn_h

    DrawButton(btn1_x, btn1_y, btn_w, btn_h, btn1_txt, hover1, 1)
    DrawButton(btn2_x, btn2_y, btn_w, btn_h, btn2_txt, hover2, 2)
    DrawButton(btn3_x, btn3_y, btn_w, btn_h, btn3_txt, hover3, 3)

    -- Click detection (triggers only on press, not hold)
    local mouse_down = gfx.mouse_cap & 1 == 1
    if mouse_down and not was_mouse_down then
        if hover1 then
            reaper.CF_ShellExecute(url_pdf)
        elseif hover2 then
            reaper.CF_ShellExecute(url_repo)
        elseif hover3 then
            reaper.CF_ShellExecute(url_audio_guide)
        end
    end
    was_mouse_down = mouse_down

    -- Info
    local info = "(Click a button to download the PDF guide, open the GitHub repository, or read the Audio Conforming Guide)"
    gfx.setfont(1, "Arial", 13)
    local wi = gfx.measurestr(info)
    gfx.x = (gfx.w - wi) / 2
    gfx.y = gfx.h - 48
    gfx.set(1,1,1,1)
    gfx.drawstr(info)

    if gfx.getchar() >= 0 then reaper.defer(Main) end
end

CenterWindow(520, 380)
Main()

