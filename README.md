<div align="center">

<img src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/positioner_top_banner.svg" alt="Positioner header logo" height=300/>

### TOOL FOR SAVING, RESTORING AND MANAGING DESKTOP ICONS

![shield-downloads-count]
![](https://img.shields.io/github/v/release/s0d3s/Positioner?include_prereleases)
![shield-windows-only]

[About](#why-positioner) ● 
[Features](#-----features--) ● 
[Installation](#-installation) ● 
[Article](https://medium.com/@s0d3s/how-to-save-the-position-of-icons-on-the-desktop-and-what-is-positioner-app-f564cde01360)
  
[![shield-download]](../../releases/latest)
</div>

## Why Positioner?

<img align="right" src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/main_presentation.gif" width="250" height="300"/>
<div align="left">
  
Has it ever happened in your life, that you finally put your legion of desktop icons onto their positions, sorted them by meaning/color, **BUT** at the next start, Windows treacherously mixed your icons with quantum wind?

It happened to me. This was the initial reason for the development.

`Positioner` - will help not only restore the same layout, but also create several `snapshots` of the desktop, with your settings, and switch between them.
</div>


<div>
  <a href="https://medium.com/@s0d3s/how-to-save-the-position-of-icons-on-the-desktop-and-what-is-positioner-app-f564cde01360"> 
     <img align="right" src="https://img.shields.io/badge/Read_on_Medium-12100E?style=for-the-badge&logo=medium&logoColor=white"/>
  </a>
  
  <h2 align="left">
    ✨ Features
  </h2>
</div> 

> ⚠ Positioner is now at the alpha-stage, so exist some nuances.<br>
> For example, the next few releases will work in single-threaded mode, in order<br>to facilitate testing (that is, when executing a command, the GUI will freeze)

* Save/restore icons position

  <img height="200" width="500" align="center" src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/exmp_save_restore.gif"/>
  
* Attach `snapshots` to quick slots

  <img height="200" width="500" align="center" src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/exmp_attach_to_slot.gif"/>
  
* Change desktop view(`flags`)

  <img height="200" width="500" align="center" src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/exmp_desktop_flags.gif"/>
  
* Quick button for hide\show icons

  <img height="200" width="500" align="center" src="https://github.com/s0d3s/Positioner/blob/media_storage/distribution/main/exmp_hide_show.gif"/>
  
* Restore icons position on OS startup

* Set custom `snapshot` name
  
* Create & use your own transition(the logic by which the icons move from point to point)
  > Now this feature is available, but only in manual mode (it is not displayed in the GUI).<br>
  > To create your own transition, modify the file `src/movement_transitions/default_transition.py`.<br>
  > You can do this before "compiling" or after installation.

## 💽 Installation

You can use `Positioner` in two ways:
 - Install and use as a standalone programm
 - Download source code, install dependencies and run as python script

> ❗ NOTE:
>   If you have too many icons on your desktop, then the transition may not be smooth.<br>
>   This is a Windows bug (which cannot be bypassed at the Positioner level), however,<br>
>   this process can be facilitated by turning off the flag responsible for displaying file names.


### Standalone Installation

 - Download installer from [latest release page](../../releases/latest)
 - Run and install
   > ~~⚠ If installed in Program Files, you will need administrator rights to run `Positioner`~~

 - Use `Positioner`!

### &lt;As Script&gt; Installation

 - [Download and install python 3.9+](https://www.python.org/)
 - Download sorce code from [latest release](../../releases/latest)
 - Unpack sorce code to some folder, and run here command line
 - Install all requirements:
   ```bash
   pip install -r requirements.txt
   ```
 - For start, run:
   ```bash
   python main.py
   ```

  

[cat]: https://cataas.com/cat/says/Positioner
[shield-downloads-count]: https://img.shields.io/github/downloads/s0d3s/Positioner/total?cacheSeconds=1800
[shield-windows-only]: https://img.shields.io/badge/-Windows%20only-555?logoWidth=40&logo=windows&logoColor=0078D6
[shield-download]: https://img.shields.io/badge/%E2%80%8C[Latest]-Download-green?style=for-the-badge&logo=data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4NCjxzdmcgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPg0KPHBhdGggZD0iTTYgMjFIMThNMTIgM1YxN00xMiAxN0wxNyAxMk0xMiAxN0w3IDEyIiBzdHJva2U9IiM5N2NhMDAiIHN0cm9rZS13aWR0aD0iNCIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+DQo8L3N2Zz4=
