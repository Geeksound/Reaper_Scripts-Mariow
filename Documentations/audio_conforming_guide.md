# 🎧 Audio Conforming Guide In REAPER

# 1. General Definition

**Audio conforming** is a key step in audio post-production that involves **retrieving and organizing the original sound files recorded on set**, ensuring they are correctly placed and clearly structured for editing and mixing.

It consists of **replacing the lower-quality or proxy audio used during picture editing** (typically from camera sound or editorial AAFs) with the **original multi-track audio recordings** captured by professional recorders (Sound Devices, Cantar, Zaxcom, etc.).

Despite being positioned as an industry standard, AAF remains tightly controlled by Avid through **Protools**, creating a classic case of AAF lock-in. This proprietary stranglehold limits interoperability, forcing post-production workflows to conform to Avid’s ecosystem and making true software neutrality nearly impossible.
_By the way, there is a new format called OpenTimelineIO that seems to be very good. Davinci Resolve is the first to add support for OTIO. However both Avid and Adobe have said that it is coming to their NLEs too.
So AAF may not be necessary soon.
The next release of vordio will have OTIO input from Resolve and so far in testing seems reliable._

In the meantime, we have to work with **AAF** to make the **conformation**, so the steps and the tools will be described in this document :through the use of innovative scripts, we aim to bypass **the exclusive link between Media Composer and Pro Tools**, making it possible to handle the conform process entirely within **REAPER**.

<p style="margin-top: 60px;"></p>


# 2. Purpose of Conforming

- **Retrieve the original WAV files** delivered by the production sound team.
- **Precisely sync the audio files to the edited picture timeline**.
- **Reorganize tracks** following a clear, consistent layout (booms first, then lavs, etc.).
- **Prepare tracks for editing, cleanup, and mixing**, ensuring readability and efficiency.

<p style="margin-top: 60px;"></p>


# 3. Conforming Workflow
This workflow is naturally optimized for **Pro Tools**, which is tightly integrated with Avid's ecosystem and can **directly interpret and extract these metadata fields** from the AAF
    Metadata related to the audio clips (such as **`SCENE`**, **`Take`**, **`TRACKNAMES`**) is often **not embedded directly into the WAV files**. Instead, it is stored in a **separate sidecar file** or within the AAF structure itself that only PROOTOOLS can find and analyse.
However, when importing the same AAF into **REAPER** using tools like **Vordio**, this metadata is **not automatically mapped to the media items**. Instead, **Vordio** places the raw metadata into the **Notes field** of each Item (accessible via the item’s properties). This means that in REAPER, users must **manually parse or script-read these Notes fields** to retrieve valuable metadata such as `Scene`, `Take`, or `TRACKNAME`.

> 🔍 In short: 
> - **Pro Tools** can natively read AAF metadata due to its Avid compatibility. 
> - **REAPER** requires additional steps to access that metadata, typically using scripts to extract it from the **Notes** field populated by **Vordio**.

## 3.1 HOW-TO conform in DAWs
### Checking the Metadatas of the .wav files in AAF session
_**Protools** can retrieve the **Scene** name, the **TakeN°**, and read the **Timecode** with ease._

- Using **REAPER** check if you can find the `Scene/take` and `originationTC` of each .wav in the Item's Name and/or Source Properties.
-  if yes , let's consider **Case A**,*(it is often the case with **DaVinci** export)*
-  if not, **Case B**.*(it is often the case with **Avid Media composer** export)*

**Case A** is the best for conformation because Metadatas can be easily be read by DAWs  

**CaseB**  
In **REAPER**, the **`Scene&Take`** information may be found in the **_Item-Notes_**_(if AAF is created by VORDIO)_, while the **Timecode** is found in the **source properties**.  
So to ensure that the **`Scene/Take`** can be interpreted;  
there are **2** possible approaches:  
**1_Either**  
We rename the item based on `this information`, allowing a **subsequent algorithm** to analyze it.  
**2_Or**   
we **reinject** the `dSCENE/dTake` **metadata** into the `iXML` tags of each item using an algorithm combined with batch rendering.
We therefore propose these two workarounds.

<p style="margin-top: 60px;"></p>

### 3.1.1 Case A ----------------------------------
### Importing Original Audio from available's Data
- Import the AAF files: using **Vordio** to convert the AAF into a REAPER session (.RPP)
- Then use "**FieldrecorderTrackMatching.lua**" with the metadatas available like 
`(SCENE/TAKE + Origination Date)`setting to Match&Import the RAW Files from Fieldrecorder  
  **OR YOU CAN USE APPROPRIATE PRESET** _of this advanced Script_

### 3.1.2 Case B ----------------------------------

       B1 _we use a special algorithm that read Item-Notes to retrieve the RAW Files.
- Use 🔍`FieldrecorderTrackMatchinglight.lua` with it automatic Algorythm
- Or use "**`FieldrecorderTrackMatching.lua`**" with the  
`Match By Name (SCENE/TAKE)` and other `criteria°°` to Match&Import the Raw Files more accurately if needed  
  _°°we can add Origination Date and/or Start TC Offset for more accurate Matching_

<p style="margin-top: 40px;"></p>

       B2 _Reconstruct Metadatas (this case may be use exceptionally)
-The strategy is to use the `Scene&Take` information in Item-note to Rename Items by `SCENE` and leave the Item-note just with `TakeN°` and then do a rendering of Items in REAPER to re-inject these in `iXMLtags`
- Use 🔍`Set-ItemFor-IXMLRendering.lua` to Rename Items with **SCENE** and leave the Notes with **Take**
- Render with the proper Wildcards to Re-inject dSCENE & dTAKE in the iXML Tags
- Do the conformation as illustrated below (CASE A)

<p style="margin-top: 60px;"></p>


## 3.2. Other considerations about conformation
- The **originatortimecode** is used to automatically align the RAW Audio Files with .wavs from the AAF
- The Timecode of the files recorded day after day can be the same, so in order for conformation to select the correct original file, an additional criteria must be added — such as the shooting date or, more precisely, the scene and take numbers.
- If timecode is unavailable, the only matching criteria that may be used are Scene/Take or TapeID (Camroll).
- My Field-Recorder-Track Scripts are optimized and written to work with all possible scenarios.  
🔍`FieldrecorderTrackMatchingLight.lua` has an **automatic-mode**

## 3.3. Track Organization
Re-order the audio tracks using a standard logic, such as:
- **Track 1: Main boom mic**
- **Track 2: Second boom**
- **Tracks 3–n: Lavalier mics (wireless mics)**, named after characters or actors (e.g., Alice, Bob).
- **Additional tracks: Room mics, ambience, etc.**  
The general rule is to organize tracks **from most general (booms) to most specific (lavs)**.  
🔍` Dial-EditConform` is a special Script that organize Items & Tracks automatically

> 🔍 In short: CONFORMATION
> - Open .RPP session converted by **VORDIO** from the AAF 
> - Check an Item-Note to see if it contains informations about `SHOOTING METADATAS`
> - Launch 🔍`FieldrecorderTrackMatchingLight.lua` to Reconform RAW Files & aaf.wavs
> - Launch 🔍`FieldrecorderTrackMatching.lua` for more accurate Conformation
> - Exceptionally, you could use 🔍`Set-ItemFor-IXMLRendering` which is a special Script that is made for prepare **Item-Names & Item-Notes** to an `Items Rendering` in **REAPER** for iXMLtags re-injection as shown below

> 🔍 In short: TRACK ORGANISATION
> - After **CONFORMATION**, .wav Mono Files may be replaced by RAW Polys Files from the Folder selected during **MATCHING** process
> - Then 🔍`Dial-EditConform.lua`may be used to **AUTOMATICALLY**:
> - Explode Polys in Mono Files
> - Rename Items by SCENE/Take-TRACKNAMES
> - Place and organize Items in Track named by TRACKNAMES

<p style="margin-top: 60px;"></p>

## 3.4. Technical Cleanup
- Remove unnecessary silence, slate beeps, or off-camera noises.
- Delete unused or empty channels (e.g., disarmed tracks).
- Add fades where needed to ease editing and preview.

## 3.5. Prepping for Sound Editing and Mixing
- Make sure **track names are clear and consistent**, using metadata tags like `TRACK_NAME`, `SCENE`, `TAKE`.
- Color-code or group tracks to improve session readability.
- Export the conformed session in a format compatible with the next workflow stage (REAPER, Pro Tools, etc.).

<p style="margin-top: 60px;"></p>

# 4. Tools & Best Practices general considerations

- **Recommended DAWs**: REAPER, Pro Tools, Pyramix, etc.
- **Useful utilities**:
  - MediaInfo (to inspect metadata)
  - BWF MetaEdit (to edit BWF metadata)
  - Vordio, AATranslator (for session conversion)
- **Structure your session early** to save time later.
- Always **check metadata and timecode integrity** before moving forward.

<p style="margin-top: 60px;"></p>

#  😀 😎 🎧 Conclusion 🎧 😎 😀

Audio conforming is a technical but vital stage: it allows you to **recover the full quality and structure of the original recordings**, while **preparing a clean, logical session for future sound work**. A well-conformed session means faster editing, easier mixing, and a clearer understanding of the film’s sound narrative.

`Pro Tools was, until now, the only one capable of performing conforming. Thanks to this suite of innovative plugins I’m offering, **i hope that Reaper** will be very much in the game.`

