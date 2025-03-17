# [Automatic subtitle downloading for MPV](https://github.com/davidde/mpv-autosub)
* Cross-platform: **Windows, Mac and Linux**
* Multi-language support
* Subtitle provider login support
* **No hotkeys required**: opening a video will automatically trigger subtitles to download
  (Only when the right subtitles are not yet present)

## Dependencies
This Lua script uses the [Python](https://www.python.org/downloads/) program
[subliminal](https://github.com/Diaoul/subliminal) to download subtitles.
Make sure you have both installed:  
```bash
pip install subliminal
```

## Setup
1. Clone the project into you mpv scripts folder.
  You may have to create the `scripts` folder yourself if it does not already exist.
  You should end up with the following folder structure:

   |       OS      |                      Path                                      |
   |---------------|----------------------------------------------------------------|
   | **Windows**   | [Drive]:\Users\\[User]\AppData\Roaming\mpv\scripts\mpv-autosub |
   | **Mac/Linux** | ~/.config/mpv/scripts/mpv-autosub                              |

   ```bash
   mkdir ~/.config/mpv/scripts
   cd ~/.config/mpv/scripts
   git clone https://github.com/eilifb/mpv-autosub
   ```

   You can also download the script as a ZIP-file from this github page.
   Just press the green `<> Code ▼` button and select `Download ZIP`.
   Extract the `mpv-autosub-master` folder and put it in `./mpv/scripts/` folder.

2. Create a file called `autosub.conf` and put it in the `scrip-opts` folder.
  You may have to create `scrip-opts` yourself if it does not already exist.

   |       OS      |                      Path                                           |
   |---------------|---------------------------------------------------------------------|
   | **Windows**   | [Drive]:\Users\\[User]\AppData\Roaming\mpv\scripts-opt\autosub.conf |
   | **Mac/Linux** | ~/.config/mpv/script-opts/autosub.conf                              |

    You can refer to `autosub_config_example.config` for a description of possible options.

3. Specify the correct subliminal location for your system:
   - To determine the correct path, use:

     |       OS      |      App       |        Command          |
     |---------------|----------------|-------------------------|
     | **Windows**   | Command Prompt |    where subliminal     |
     | **Mac/Linux** | Terminal       |    which subliminal     |

   - Copy this path to the `subliminal` option in `autosub.conf`:
     ```properties
      subliminal=Path/To/subliminal.exe
     ```

## Customization
All customization is done via the `script-opts/autosub.conf` configuration file.
* Optionally change the subtitle languages / [ISO codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).
  Be sure to put your preferred language at the top of the list.
  If necessary, you can manually trigger downloading your first choice language by pressing `b`,
  or your second choice language by pressing `n`.
* Optionally specify the login credentials for your preferred subtitle provider(s), if you have one.
* If you do not care for the automatic downloading functionality, and only wish to use the hotkeys,
  simply change the `auto` option to `no`.
* For added convenience, you can specify the locations to exclude from auto-downloading subtitles, or alternatively,
the *only* locations that *should* auto-download subtitles.

This script is under the [MIT License](./LICENSE-MIT),
so you are free to modify and adapt this script to your needs:
check out the [MPV Lua API](https://mpv.io/manual/stable/#lua-scripting) for more information.

If you find yourself unable to find the correct subtitles for some niche movies/series,
you might be interested in the [submod](https://github.com/davidde/submod_rs)
command line tool I've written to manually correct subtitle timing.

## Credits
Inspired by [selsta's](https://gist.github.com/selsta/ce3fb37e775dbd15c698) and
[fullmetalsheep's](https://gist.github.com/fullmetalsheep/28c397b200a7348027d983f31a7eddfa) autosub scripts.
