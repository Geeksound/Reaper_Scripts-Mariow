<h2 align="center"><em>What if REAPER had the tools of Pro Tools?</em></h2>

<p align="center">
<img src="PICTURES/Ultimate.png" alt="Ultimate Banner" width="600"/>
</p>
<h3 align="center"><em>"Reapers" by Muse is a reference among all</em></h3>
<p align="center">
<img src="PICTURES/ProfilGitHubMariow.png" alt="Mariow Logo" width="100"/>
</p>

# Scripts Reaper inspired from Protools and more - by Mariow
## Installation via ReaPack

Add this URL to your Reapack repositories (Reapack>Manage Repositories... import/export) to install these Scripts  
https://github.com/Geeksound/Reaper_Scripts-Mariow/raw/main/index.xml

## D O C U M E N T A T I O N
`- Documentations/---------`
## **Docs&RepositoryGuide**
Special Script to see and Download Guide for my Repository and Scripts
<p align="center">
  <img src="PICTURES/Repository-Guide.png" alt="Repository-Guide" width="400"/>
</p>

## Directory Structure
<h3><em>- 'DOCUMENTATIONS'</em></h3>
For better knowledge of Scripts &  
RECORDING-TRACK GUIDE "as in PROTOOLS"

- `Editing/`: Scripts for editing
- `Field-Recorder_Workflow/`:  
Exclusive Scripts for Dialogue  
editing&conformation Inspired  
by "PT' Field-recorder Track
- `Metadatas/`: Scripts related to metadata
- `Utility/`: Utility scripts
- `View/`: Scripts related to display
<p align="center">
  <img src="PICTURES/Tree-Github.png" alt="Tree-Github" width="400"/>
</p>

-------------------------------------------------
`- Editing/---------`

## 1. **TimeShift** "PROTOOLS Edit/Shift in better" :)
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Editing/TimeShift.lua)  
Precise Time Shifting (ReaImGui)
ReaImGui script for REAPER that allows precise shifting of items, time selection, or the edit cursor using a user-defined value in various formats.
This script is inspired by the Edit/Shift function in PROTOOLS, with added improvements.

<!-- ancienne version non centree pour reference
### Overview of 'TimeShift'
![Aperçu de TimeShift](PICTURES/TimeShift.png) -->
<p align="center">
  <img src="PICTURES/TimeShift1.4.2.png" alt="Overview of 'TimeShift'">
</p>   

## FEATURES
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



---
## 2. **Swap-ItemsPositionsOnSameTracks**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Editing/Swap-ItemsPositionsOnSameTracks.lua)  
Swap 2 Items on a Track for listening and editing purpose

<!--### Overview of 'Swap-ItemsPositionsOnSameTracks'
![Aperçu de TimeShift](PICTURES/Swap2Items.png)-->
<p align="center">
  <img src="PICTURES/Swap2Items.png" alt="Overview of 'Swap2Items'">
</p>   

## FEATURES
- **Quick comparative listening between 2 items
- **Particularly useful during sound editing for picture

## How to use
1. Select the 2 items you wish to swap positions.
2. Run the Script


---
## 3. **SelNoNamed-Tracks**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Utility/SelNoNamed-Tracks.lua)  
Select Tracks without Names or unnamed

<p align="center">
  <img src="PICTURES/SelNoNamed-Tracks.png" alt="Overview of 'SelNoNamed-Tracks'"width="400" />
</p>   

## 3. **TRACKMANAGER**
###  Two versions of TRACKMANAGER

### FEATURES
TRACKMANAGER provides harmonious color palettes and advanced tools to **visualize, organize, and manage** your REAPER session.

It includes an ImGui-based graphical interface that introduces a dedicated guide track named **“TRACKS”**.  
This special track acts as a **visual map** of your project: each real track is represented by a **colored item** inside the “TRACKS” track.  
Through this system, you can:

- Apply consistent and **harmonious colors** to tracks and items (2x18 color grid)  
- **Easily create, delete, or reorganize** tracks and visual spacers  
- Maintain a **two-way synchronization** between the “TRACKS” representation and the real tracks in your session  
- Build or reconstruct a full project structure directly from the visual “TRACKS” template

---

(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Editing/TRACKMANAGER.lua)  
<p align="center">
  <img src="PICTURES/TRACKMANAGER.png" alt="Overview of 'TRACKMANAGER'" width="800" />
</p>

(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Editing/TRACKMANAGERexpanded.lua)  
<p align="center">
  <img src="PICTURES/TRACKMANAGERexpanded.png" alt="Overview of 'TRACKMANAGERexpanded'" width="800" />
</p>

## How to use
1. Put it in your Global Startup if needed  
2. Colorize / View / Manage tracks by items in “TRACKS” and vice versa  
3. Create new tracks in your session directly from organized items in “TRACKS”  
4. Use the two advanced “search” modes to retrieve Tracks-by-Type and Take Markers efficiently



-------------------------------------------------
`- Field-Recorder_Workflow/-------`

# Fieldrecorder-Track (like in Protools but better). 2 versions.

##  A.Full version with innovative Presets
##  B.Auto-mode version that will work on its own in most cases
ReaImGui scripts for REAPER that may be executed after an AAF import and match these .wav files imported with the Original RAW Files from the ****Fieldrecorder**

<p align="center">
  <img src="PICTURES/CONFORMATION-SUITE.png" alt="Overview of 'Conformation-suite'" width="800" />
</p> 

### A. **FieldrecorderTrack-Matching_AUTO-Lite** "PROTOOLS Fieldrecorder Track" with an **AUTOMATIC-MODE!**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/mainField-Recorder_Workflow/FieldrecorderTrack-Matching_AUTO-Lite.lua)  

### B. **FieldrecorderTrack-Matching** "PROTOOLS Fieldrecorder Track" with some presets accorded to  **Fieldrecorders**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/mainField-Recorder_Workflow/FieldrecorderTrack-Matching.lua)  

<p align="center">
  <img src="PICTURES/Fieldrecorder-Tracks.png" alt="Overview of 'Fieldrecorder-Tracks'" width="800" />
</p> 

## 2. **Dial-EditConform** 
### (comes after RAW Files Matching to explode and organize Items in Tracks by Name)
– Automate and organize your dialogue workflow in Reaper: create tracks from metadata, split multichannel audio, rename and move items, and clean up unused tracks—all in one go. 
Perfect for fast, metadata-driven dialogue conforming.
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/mainField-Recorder_Workflow/Dial-EditConform.lua)  

<p align="center">
  <img src="PICTURES/Dial-EditConform.png" alt="Overview of 'Dial-EditConform'" width="800" />
</p> 

## 3. **FieldrecordingSound-Report** 
###Description:
This script streamlines the field recording workflow in Reaper by generating a detailed Sound Report for dialogue or production recordings.
Record the Dialog Lines on SHOOTING film via Dantefrom Field-Recorders like ****Cantar** or **Sound Devices** and edit a Sound-Report for Post-Production.
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/mainField-Recorder_Workflow/FieldrecordingSound-Report.lua)  

<p align="center">
  <img src="PICTURES/FieldrecordingSound-Report.png" alt="Overview of 'FieldrecordingSound-Report'" width="800" />
</p> 

## Utilities
## 1. **RenameItemFrom-ShootingSlate**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Field-Recorder_Workflow/RenameItemFrom-ShootingSlate.lua)  
This script Rename Items with the SCENE/Take and/or TRACK NAME edited during Shooting on the FIELD RECORDER 
May be useful for Post-production editing Dialogues

<p align="center">
  <img src="PICTURES/RenameItemFrom-ShootingSlate.png" alt="Overview of 'RenameItemFrom-ShootingSlate'" width="500" />
</p> 


## 2. **ItemNames-To-TrackNames**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Field-Recorder_Workflow/ItemNames-To-TrackNames.lua)  
This script Rename the Track from item selected.
May be useful for Post-production editing tasks and other.

<p align="center">
  <img src="PICTURES/ItemNames-to-TrackNames.png" alt="Overview of 'ItemNames-to-TrackNames'" width="500" />
</p> 

## 3. **Remove-DuplicatesItems**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Field-Recorder_Workflow/Remove-DuplicateItems.lua)   
This script delete the unnecessary duplicates Items that are imported  
when Matching Raw Files with AAFs during conformation.  
Very useful when editing dialog.
<p align="center">
  <img src="PICTURES/Remove-DuplicatesItems.png" alt="Overview of 'Remove-DuplicatesItems'" width="500" />
</p> 

## 4. **Detect-DeleteEmpty-Items**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Field-Recorder_Workflow/Detect-DeleteEmpty-Items.lua)   
This script delete the empty Items that sometimes are recorded  
on a Field Recorder when track as no input but is ARMED.
-- Dont't worry , ROOM TONES won't be deleted :) ! --

## 4. **Set-ItemFor-IXMLRendering**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Field-Recorder_Workflow/Set-ItemFor-IXMLRendering.lua)   
This script may be used if..., Metadata related to SCENE/Take in AAF .wavs files are missing.
So when translating AAF>RPP with Vordio, we can retrieve these informations in the Notes of each Items
One strategy could be to Rename each Item by "**SCENE**" and leave the Notes with only **Take**
Then Reaper can Re-render each Items and re-inject missing Metadata in tags **iXML** with Wildcard used as shown below.
<p align="center">
  <img src="PICTURES/Set-ItemFor-IXMLRendering.png" alt="Overview of 'Set-ItemFor-IXMLRendering'" width="800" />
</p> 



-------------------------------------------------
`- Metadatas/---------`

## 1. **View-FieldRecorder-Metadatas**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Metadatas/View-FieldRecorder-Metadatas.lua)  
This script allows you to read and analyze the metadatas of the selected item through its source file in a window. 
The metadatas being examined are that entered by Sound Recorders in Film Sound Recording, such as the Scorpio or Cantar,
in order to answer questions in this type of workflow.

## 2. **ViewFile-FieldRecorder-Metadatas**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Metadatas/ViewFile-FieldRecorder-Metadatas.lua)  
This script allows you to read and analyze the metadata of an audiofile in the browser.  
It may be useful for Conformation and Dialogue Editing duties.

<p align="center">
  <img src="PICTURES/ViewFile-FieldRecorder-Metadatas.png?cb=1" alt="Overview of 'ViewFile-FieldRecorder-Metadatas'"width="500" />
</p>   


-------------------------------------------------
`- Utility/---------`

## 1. **CreateTracksFromText**
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Utility/CreateTracksFromText.lua)  
 Type a text and convert it in Reaper Session
 

<!--### Overview of 'CreateTracksFrom-Text'
![Aperçu de CreateTracksFromText](PICTURES/TextToTracksDef.png)-->
<p align="center">
  <img src="PICTURES/TextToTracksDef.png" alt="Overview of 'TextToTracks'">
</p>   

## FEATURES
 Write your Templates as a Text and transform this in a Reaper session as a Template would do

## How to use
 1. Write the appropriate form of Text and save the file
 2. Open the Script and Browse to your Text file and select it
 3. Your Tracks in Reaper are created

## CARE
 TEXT must be in PLAIN TEXT  
 SHIFT(Cmd+T) in TextEdit or  
 click on Format,then Make Plain Text.

---
## 2. **prefix-to-name**
 (https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Utility/prefix-to-name.lua)  
 Add a prefix to Name of Selected Items to improve sorting and organisation

<p align="center">
  <img src="PICTURES/prefix-to-name.png" alt="Overview of 'prefix-to-name'" width="500" />
</p>   

## FEATURES
Batch Re-naming selected Items with a prefix for a better Workflow and sorting
 
 ## How to use
 1 Select Items
 2 Action list / prefix-to-name
 3 Choose a prefix
  
  ---
  ## 3. **ReplaceXthCharacter-inName**
  (https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/Utility/ReplaceXthCharacter-inName.lua)  
  Replace a /suit of Chararacter(s) in a Name
  
  <p align="center">
    <img src="PICTURES/ReplaceXthCharacter.png" alt="Overview of 'ReplaceXthCharacter'" width="800" />
  </p>   
  
  ## FEATURES
  Replace a/suit of character(s) in a Name for special Worflows and convention
  
  ## How to use
  1 Select Items  
  2 Action list / ReplaceXthCharacter  
  3 Enter Character to replace  
  4 Enter New Character  
 

-------------------------------------------------
`- View/---------`

## 1. **Interactive-TC-Display** (ReaImGui)
(https://github.com/Geeksound/Reaper_Scripts-Mariow/blob/main/View/Interactive-TC-Display.lua)  
Displays either the Timecode or the selected item's name dynamically, based on context.
Designed for precise visual feedback in post-production or recording workflows.

<!--### Overview of the 'TimeCode' field depending on the context
![Aperçu de Dynamic Timecode Display](PICTURES/DynamicTcDisplay.png)-->
<p align="center">
  <img src="PICTURES/DynamicTcDisplay.png" alt="Overview of 'DynamicTcDisplay'"width="500" />
</p>   

ReaImGui script for REAPER that displays contextual time information in a clean and readable floating window.

### FEATURES
- **Displays the name and timecode** of selected Items (hh:mm:ss:ff)
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

### Dependancy

This script requires [ReaImGui](https://github.com/cfillion/reaimgui)

-------------------------------------------------
____________________________
<p align="center">😀 😎 🎧 About the Author 🎧 😎 😀</p>
<p align="center">
  <strong><a href="https://github.com/Geeksound">Geeksound</a></strong>
</p>

`Sound engineer, professor, eternal student, and workflow "designer".`   
`Working in Film Sound Recording and Post-Production,with a passion for developing innovative workflows.`  
`Wish the best for Reaper, its collaborators and community.`
