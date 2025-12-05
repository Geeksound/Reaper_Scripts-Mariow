--[[
@description Empty Item Creator
@version 1.0
@author Mariow
@changelog
  v1.0 (2025-12-05)
  - Initial release: ImGui V2 tool to create and customize Empty Items
@provides
  [main] Utility/Create-CueItem.lua
@link https://github.com/Geeksound/Reaper_Scripts-Mariow
@repository https://github.com/Geeksound/Reaper_Scripts-Mariow
@tags item, utility, ImGui, creation, color
@about
  # Empty Item Creator (ImGui V2)
  A lightweight ReaImGui-based utility to quickly create Empty Items in REAPER
  with custom name, note and color.

  ## Features
  - Instant creation of an Empty Item
  - Auto-focus on the Name field
  - Name → Note shortcut button
  - Multi-line Note input
  - Color palette with active selection highlight
  - Colors stored in REAPER’s native BGR format
  - Window position saved between sessions
  - Press Enter to validate anywhere in the window

  Ideal for workflow optimization when creating markers, labels,
  regions or organizational items inside REAPER.
--]]

local reaper = reaper

----------------------------------------
-- 🎨 PALETTE COULEUR (RGB)
----------------------------------------
local palette_gui = {
    {0.05, 0.15, 0.75},  -- Bleu foncé
    {0.25, 0.50, 0.95},  -- Bleu Moyen
    {0.30, 0.95, 1.00},  -- Bleu Turquoise
    {0.05, 0.45, 0.20},  -- Vert foncé
    {0.50, 0.55, 0.10},  -- Vert Crote
    {0.15, 0.15, 0.15},  -- Noir
    {1.00, 0.45, 0.00},  -- Orange foncé
    {1.00, 0.15, 0.15},  -- Rouge
    {0.45, 0.15, 0.55},  -- Violet foncé
    {0.45, 0.25, 0.15},  -- Marron foncé
    
}

----------------------------------------
-- POSITION
----------------------------------------
local SCRIPT_ID = "ChatGPT_Empty_Item_Creator_V2"
local pos_x = tonumber(reaper.GetExtState(SCRIPT_ID, "pos_x")) or 300
local pos_y = tonumber(reaper.GetExtState(SCRIPT_ID, "pos_y")) or 300

----------------------------------------
-- VARIABLES GUI
----------------------------------------
local ctx
local window_open = true
local first_focus = true
local item_name = ""
local item_note = ""
local chosen_color = palette_gui[1]
local created_item, created_take

----------------------------------------
-- RGB → U32 (ImGui)
----------------------------------------
local function rgb_to_u32(r, g, b)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, 1)
end

----------------------------------------
-- RGB → color item Reaper (BGR)
----------------------------------------
local function rgb_to_native(r, g, b)
    local R = math.floor(r * 255 + 0.5)
    local G = math.floor(g * 255 + 0.5)
    local B = math.floor(b * 255 + 0.5)
    return (B << 16) | (G << 8) | R | 0x1000000
end

----------------------------------------
-- CREATION EMPTY ITEM
----------------------------------------
local function CreateEmptyItem()
    reaper.Main_OnCommand(40142, 0)
    created_item = reaper.GetSelectedMediaItem(0, 0)
    if not created_item then
        reaper.MB("Échec création empty item", "Erreur", 0)
        return false
    end

    created_take = reaper.GetActiveTake(created_item)
    if not created_take then
        created_take = reaper.AddTakeToMediaItem(created_item)
        reaper.SetActiveTake(created_take)
    end

    return true
end

----------------------------------------
--  NAME + NOTE + COULEUR
----------------------------------------
local function ApplyData()
    reaper.GetSetMediaItemTakeInfo_String(created_take, "P_NAME", item_name, true)
    reaper.ULT_SetMediaItemNote(created_item, item_note)

    -- BGR comme ton autre script
    local col_native = rgb_to_native(
        chosen_color[3], -- B
        chosen_color[2], -- G
        chosen_color[1]  -- R
    )

    reaper.SetMediaItemInfo_Value(created_item, "I_CUSTOMCOLOR", col_native)
    reaper.UpdateArrange()
    -- 🔹 Désélectionner tous les items
    reaper.Main_OnCommand(40289, 0)
end

----------------------------------------
--  COULORS + SURlIGNAGE
----------------------------------------
local function DrawColorButton(col, label)
    local colU32 = rgb_to_u32(col[1], col[2], col[3])

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), colU32)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), colU32)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), colU32)

    local clicked = reaper.ImGui_Button(ctx, label, 24, 24)

    reaper.ImGui_PopStyleColor(ctx, 3)

    -- Surbrillance si sélectionnée
    if col == chosen_color then
        local dl = reaper.ImGui_GetWindowDrawList(ctx)
        local x1, y1 = reaper.ImGui_GetItemRectMin(ctx)
        local x2, y2 = reaper.ImGui_GetItemRectMax(ctx)
        reaper.ImGui_DrawList_AddRect(dl, x1-2, y1-2, x2+2, y2+2, 0xFFFFFFFF, 0, 3)
    end

    if clicked then chosen_color = col end
end

----------------------------------------
-- IMGUI LOOP
----------------------------------------
function MainLoop()
    if not window_open then return end

    reaper.ImGui_SetNextWindowPos(ctx, pos_x, pos_y, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowSize(ctx, 380, 270, reaper.ImGui_Cond_FirstUseEver())

    local visible, open = reaper.ImGui_Begin(ctx, "Create Empty Item (by Mariow)", true)

    if visible then

        -- Validation globale par Entrée
        if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
            ApplyData()
            window_open = false
        end

        --------------------------------
        -- NOM
        --------------------------------
        if first_focus then
            reaper.ImGui_SetKeyboardFocusHere(ctx)
            first_focus = false
        end

        local changed
        changed, item_name = reaper.ImGui_InputText(ctx, "Name", item_name)

        if reaper.ImGui_IsItemActive(ctx)
        and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
            ApplyData()
            window_open = false
        end

        --------------------------------
        -- NOTE
        --------------------------------
        changed, item_note = reaper.ImGui_InputTextMultiline(ctx, "Note", item_note, 248, 60)

        --------------------------------
        -- BOUTON Nom → Note
        --------------------------------
        if reaper.ImGui_Button(ctx, "Name → Note", 110, 25) then
            item_note = item_name
        end

        reaper.ImGui_Separator(ctx)

        --------------------------------
        -- PALETTE COULOR
        --------------------------------
        reaper.ImGui_Text(ctx, "Color :")

        -- Palette automatique
        for i, col in ipairs(palette_gui) do
            if i > 1 then reaper.ImGui_SameLine(ctx) end
              DrawColorButton(col, "##col"..i)
          end


        reaper.ImGui_Separator(ctx)

        --------------------------------
        -- VALIDATION 
        --------------------------------
        if reaper.ImGui_Button(ctx, "OK", 150, 30) then
            ApplyData()
            window_open = false
        end

        reaper.ImGui_SameLine(ctx)

        if reaper.ImGui_Button(ctx, "Cancel", 150, 30) then
            window_open = false
        end

        --------------------------------
        -- MEMORISATION Window
        --------------------------------
        pos_x, pos_y = reaper.ImGui_GetWindowPos(ctx)
        reaper.SetExtState(SCRIPT_ID, "pos_x", tostring(pos_x), true)
        reaper.SetExtState(SCRIPT_ID, "pos_y", tostring(pos_y), true)

        reaper.ImGui_End(ctx)
    end

    if open and window_open then
        reaper.defer(MainLoop)
    end
end

----------------------------------------
-- LANCEMENT
----------------------------------------
if CreateEmptyItem() then
    ctx = reaper.ImGui_CreateContext("Empty Item Creator UI")
    MainLoop()
end

