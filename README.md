<p align="center">
<img src="ProfilGitHubMariow.png" alt="Mariow Logo" width="200"/>
</p>

# Scripts Reaper - par Mariow

## Dynamic Timecode Display (ReaImGui)

ReaImGui script for REAPER that displays contextual time information in a clean and readable floating window.

### Features

- **Dysplays the name and timecode** of selected Items (hh:mm:ss:ff)
- **Displays the duration** of the timeselection (if no item is selected)
- **Shows the play cursor or playback position** with large text
- **Dynamic display** :
- `Play` when Reaper is playing
- `REC` when Recording
- `Position` when stopped
- **Colored background** :
- Black by default
- Green during playback
- Red while recording
- **custom typography** : Comic Sans MS for a playful touch
### Dépendance

This script requires [ReaImGui](https://github.com/cfillion/reaimgui).

### Installation via ReaPack

Add this repository to your ReaPack:

-------------------------------------------------

# TimeShift - Precise Time Shifting (ReaImGui)

ReaImGui script for REAPER that allows precise shifting of items, time selection, or the edit cursor using a user-defined value in various formats.
This script is inspired by the Edit/Shift function in PROTOOLS, with added improvements.

## Features

- **Quick shifting** of selected items or time selection
- **Flexible input options** :
- **Timecode** (hh:mm:ss:ff)
- **Milliseconds**
- **Samples**
- **Automatic conversion** between formats
- **Interactive interface** using ReaImGui
- **Directional shifting** : forward or backward
- **Action buttons**  for instant application

## How to use

1. Choose whether to shift the Selected Item, the Time Selection, or the Edit Cursor. 
2. Enter the desired offset value (e.g. 00:00:02:15, 1500 ms, or 44100 samples). 
3. Click the appropriate button to shift forward or backward.

## Dependancy

- [ReaImGui](https://github.com/cfillion/reaimgui) (install via ReaPack)

## Installation via ReaPack

Add this repository to your ReaPack sources:

-------------------------------------------------

## CreateTracksFromText

Type a text and convert it in Reaper Session

## Features
Write your Templates as a Text and transform this in a Reaper session as a Template would do

## CARE
TEXT must be in PLAIN TEXT (SHIFT Cmd )+T  in TextEdit
