# widebrim HD
<p align="middle">
  <img src="./res_demo/demo_0.png" width="30%" align="justify">
  <img src="./res_demo/demo_1.png" width="30%" align="justify">
  <img src="./res_demo/demo_2.png" width="30%" align="justify">
  <br><i>assets by Level-5, running in widebrim HD</i>
</p>

widebrim HD is a work-in-progress Godot-based high-level engine recreation for the mobile versions of LAYTON2 _(Layton: Diabolical Box in HD / Layton: Pandora's Box in HD)_ for running the game **natively, without emulation** on any compatible system.

## Quickstart: How do I get this running?
### Required Prerequisites
You will need the following:

 - A dump of LAYTON2 HD for Android, including both the APK and OBB
 - Godot 4.2 or newer
 - Python 3.11
 - [PyCriCodecs](https://github.com/Youjose/PyCriCodecs), tested with 0.4.8

### Optional Prerequisites
To improve your experience, the following is recommended:

 - Environment for building Python extensions (e.g., Microsoft Build Tools for Visual Studio)
 - FFMPEG with libvorbis (e.g., any modern FFMPEG 'essentials' build)
	- This should be accessible from any terminal, i.e., on PATH for Windows.

### Installation Guide

 1. Install the required prerequisites (and optional for a better experience)
 2. Clone the repository.
 3. Start a terminal inside `widebrim_hd/assets_py_unpacker` and run the following:
    - Install requirements with `pip install -r requirements.txt`
	     - <i>(Optional, <b>recommended</b>)</i> Build Cython extension for faster unpacking with `python setup.py build_ext --inplace`
    - Unpack and convert assets with `python install_apk_obb.py <path to apk> <path to obb>`
	     - If you do not have the optional prerequisites installed, this will be **very** slow and will consume significantly more space. **This is the intended way to install the assets**, but if this is too slow you can try [QuickBMS](https://aluigi.altervista.org/quickbms.htm) with [this script](https://aluigi.altervista.org/bms/layton_curious_village.bms). You will need to manually extract the asset folder from the APK and combine both the OBB output and APK files into the `widebrim_hd/assets` folder. **This method is deprecated and will be incompatible in the future.** Audio support is not planned with this method.
 4. Import `widebrim_hd/project.godot` into the Godot Editor.

## Quickstart: How do I use this?

Open Godot, load the project and press Play in the top-right. By default, the game loads and saves a DS-like save slot as `state.sav` in the project root. To delete all progression and restart, delete this save.

## What is widebrim HD for?

widebrim HD continues where [widebrim](https://github.com/bullbin/widebrim) left off and tackles research for the HD ports of LAYTON2... <sup>...but to be honest, it's actually just for fun, I don't know much about Godot 😄<sup>

## How accurate is this?
widebrim HD is a rewrite of [widebrim](https://github.com/bullbin/widebrim) combined with additional knowledge from reversing LAYTON2 HD. It tries to be largely accurate and should replicate most engine-related bugs in the future, especially because the new engine itself has none of the quirks of the Nintendo DS version.

## How far along is this?
Not very, gamemode switching is implemented and a basic event and room parser have been written. It's not known how far along the story can be completed yet.

## How can I contribute?
### Something broke and I'd like to file a bug report
**Please open a GitHub issue describing the problem, your save file and steps to reproduce.** The save system in-game isn't complete yet so we might need significant information if the bug isn't easily reproducible. Thanks!

### I'd like to request a feature
Open a GitHub issue - keep in mind that features in the original game are already intended to have implementations in widebrim HD.

### I'd like to contribute code
Feel free, open a pull request 😎

## Who's fault is this?
Thanks goes to...
 - The contributors of [PyCriCodecs](https://github.com/Youjose/PyCriCodecs), audio support is planned and this library is responsible for making it possible ❤️
 - Christian Robertson for the font [Roboto](https://fonts.google.com/specimen/Roboto), I'm lazy and can't be bothered to finish reversing `font.dat` but this is similar enough
 - ssh for figuring out the decryption routine for the HD Layton games (RIP ZenHAX)
 - [creativelynameduser](https://github.com/creativelynameduser) for their help with decoding the in-game font format
 - Everyone who helped with [widebrim](https://github.com/bullbin/widebrim) and by extension, [madhatter](https://github.com/bullbin/madhatter) for understanding HD file formats
