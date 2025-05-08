# Scripts Reaper - par Mariow

## Affichage Timecode Dynamique (ReaImGui)

Script ReaImGui pour REAPER affichant des informations temporelles contextuelles dans une fenêtre élégante et lisible.

### Fonctionnalités

- **Affiche le nom et le timecode** des items sélectionnés (hh:mm:ss:ff)
- **Affiche la durée** de la time selection (si aucun item n’est sélectionné)
- **Affiche la position du curseur** ou de la lecture avec une grosse police
- **Affichage dynamique** :
- `Play` lorsque Reaper est en lecture
- `REC` lorsqu’un enregistrement est en cours
- `Position` lorsqu’arrêté
- **Fond coloré** :
- Noir par défaut
- Vert lors de la lecture
- Rouge lorsqu’on enregistre
- **Typographie personnalisée** : Comic Sans MS pour une touche originale

### Dépendance

Ce script nécessite [ReaImGui](https://github.com/cfillion/reaimgui).

### Installation via ReaPack

Ajoutez ce dépôt à votre ReaPack :

# TimeShift - Déplacement temporel précis (ReaImGui)

Script ReaImGui pour REAPER permettant de déplacer précisément des items, une sélection temporelle, ou le curseur de position, à l’aide d’une valeur saisie dans différents formats.
Ce Script est inspiré de la fonction Edit/Shift dans PROTOOLS , et y apporte des améliorations.
GB (This Script is the same as Edit/SHIFT in PROTOOLS , but with more possibilities)

## Fonctionnalités

- **Déplacement rapide** des items sélectionnés ou de la time selection
- **Entrée au choix** :
- **Timecode** (hh:mm:ss:ff)
- **Millisecondes**
- **Samples**
- **Conversion automatique** entre les formats
- **Interface interactive** avec ReaImGui
- **Déplacement directionnel** : en avant ou en arrière
- **Boutons d’action** pour appliquer instantanément

## Utilisation

1. Choisissez de deplacer l'Item Selectionné, ou la TimeSelection, ou le Curseur de position
2. Entrez la valeur de décalage souhaitée (ex : `00:00:02:15` ou `1500 ms` ou `44100 samples`).
3. Cliquez sur le bouton pour appliquer le décalage en Avant ou en Arrière

## Dépendance

- [ReaImGui](https://github.com/cfillion/reaimgui) (à installer via ReaPack)

## Installation via ReaPack

Ajoutez ce dépôt à vos sources ReaPack :

## CreateTracksFromText

Script permettant de convertir un simple texte en Session Reaper
Type a text and convert it in Reaper Session

## Fonctionnalités
Vous pouvez ainsi écrire vos Templates de pistes et les conserver dans un "Livre"
GB (Write your Templates as a Text and transform this in a Reaper session as a Template would do)

## CARE
TEXT must be in PLAIN TEXT (SHIFT Cmd ) +T  in TextEdit
