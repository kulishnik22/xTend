<div align="center">
    <img src="./windows/runner/resources/app_icon.ico" alt="Icon" width="200" height="200">
    <p id="version">v1.0.0</p>
    <h1>xTend</h1>
    <p>Let's you control your Windows PC using <b>Xbox controller</b></p>
    <p style="font-size:14px;"><b>Minimalistic | Easy to use | Open-source</b></p>
</div>


## Usage
### Switching modes
To switch between modes, both **START** and **BACK** buttons have to be clicked at the same time
>  **START** and **BACK** buttons are located on the left and right of the Xbox logo button

There are 3 user-selectable modes:
-  **Gamepad**
-  **Mouse**
-  **Keyboard**  
>**Gamepad** is the initial mode after connecting your Xbox controller to PC

### Gamepad mode
Doesn't respond to any controller input except for mode switch key combination
### Default mouse mode configuration
| Gamepad key        | Mapping                                                            |
|--------------------|--------------------------------------------------------------------|
| **Left joystick**  | Controls the mouse movement in exponential speed                   |
| **Right joystick** | Controls the scroll in linear speed (both vertical and horizontal) |
| **A**              | Left mouse button                                                  |
| **B**              | Right mouse button                                                 |
| **X**              | Browser back                                                       |
| **Y**              | Browser forward                                                    |
| **Left trigger**   | Volume down                                                        |
| **Right trigger**  | Volume up                                                          |
| **Left shoulder**  | Alt                                                                |
| **Right shoulder** | Tab                                                                |
> To switch between windows, hold **Left shoulder** and click **Right shoulder** button

### Default keyboard mode configuration
On-screen keyboard is displayed in alphanumeric mode in 50% opacity.  
| Gamepad key         | Mapping                                     |
|---------------------|---------------------------------------------|
| **Left joystick**   | Moves the selected keyboard key             |
| **Directional pad** | Controls the arrow keys for text navigation |
| **A**               | Simulates the selected key on the keyboard  |
| **B**               | Backspace                                   |
| **X**               | Enter                                       |
| **Y**               | Toggle CapsLock                             |
| **Left trigger**    | Ctrl+C                                      |
| **Right trigger**   | Ctrl+V                                      |
| **Left shoulder**   | Alt                                         |
| **Right shoulder**  | Tab                                         |
> In case of special characters or symbols, the keyboard also presses the necessary keys to achieve the character such as ctrl, alt or shift

> To switch between windows, hold **Left shoulder** and click **Right shoulder** button  

## Custom mapping
To change controller mappings, open `config.json` file located next to your xTend executable.  
> Note that it requires first run for the application to generate the config file  

There are two mappings called `mouse` and `keyboard` each corresponding to a mapping for specific mode.  
### Button mappings (including triggers)
- `mouseLeftClick` `// mouse mode specific`
- `mouseRightClick` `// mouse mode specific`
- `browserBack`
- `browserForward`
- `alt`
- `tab`
- `arrowUp`
- `arrowDown`
- `arrowLeft`
- `arrowRight`
- `backspace`
- `enter`
- `capsLock`
- `clickAtKeyboardCursor` `// keyboard mode specific`
- `volumeUp`
- `volumeDown`
- `shift`
- `win`
- `ctrl`
- `ctrlC`
- `ctrlV`
- `ctrlX`
- `ctrlW`
- `ctrlA`
- `ctrlS`
- `none`

### Joysticks mappings
- `mouse`
- `scroll`
- `keyboardNavigation` `// keyboard mode specific`
- `none`
> Note that certain mappings are **mode-specific**

## Installation  
### Download the latest build  
1.  [Download](https://github.com/kulishnik22/xTend/releases/download/v1.0.0/xTend.zip) the archive
2. Unzip the archive and extract the xTend directory
3. Place the directory somewhere safe
4. Run the **xtend.exe** in the directory
> Optionally, you can create a shortcut of **xtend.exe** and place the shortcut in your startup directory to run xTend on boot
### Build from source
**Requirements:**
- Flutter 3.29.0
- Dart 3.7.0
- Windows 10 or above

**Steps**
1. Git clone the [repository](https://github.com/kulishnik22/xTend.git)
2. Run `flutter clean` and `flutter pub get`
3. To build the project run `flutter build windows --release`  
Release binary along with dependencies will be located in `/build/windows/runner/Release/`  
> The location of your build will also be written to the console output  

___
Uicons by [Flaticon](https://www.flaticon.com)
