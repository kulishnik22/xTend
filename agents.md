# xTend Agents

## Overview
- xTend is a Windows-only Flutter desktop companion that maps Xbox controller input into Windows mouse and keyboard events.
- The app is built around a small set of cooperating agents: data sources that read hardware state, a domain service that decides how to respond, platform bindings that emit synthetic input, and a lightweight UI shell that exposes keyboard overlays and system tray integration.
- Internally the codebase is divided into data (FFI bindings and persistence), service (input orchestration), controller (view-facing glue), view (Flutter widgets), util (platform channels), and Windows runner extensions written in C++.

## Bootstrapping & Lifecycle
1. `lib/main.dart` aborts on non-Windows platforms, wires up dependency injection through `XtendApp`, and launches `XtendFlutterApp`.
2. `XtendApp` (`lib/app/app.dart`) registers singletons into a `GetIt`-backed container (`lib/app/dependency.dart`). The container exposes `get<T>()` to retrieve services anywhere in the app.
3. `XtendView` (`lib/view/xtend_view.dart`) is resolved from the container and becomes the root widget. During `initState` it:
   - Builds a `KeyboardController` and wraps it in a `VirtualKeyboardInterface`.
   - Asynchronously initializes the `XtendController`, which in turn initializes the core `Xtend` service.
   - Installs system tray support and begins listening to mode changes emitted by `Xtend`.
4. When the app shuts down through the tray menu, `XtendView` disposes the keyboard and `Xtend` service, removes the tray icon, and asks the native window to close.

## Core Runtime Agents

### XtendApp & Dependency Container (`lib/app/app.dart`, `lib/app/dependency.dart`)
- **Purpose**: centralizes object graph construction and exposes lazily fetched singletons.
- **Key registrations**:
  - Data sources: `User32Api`, `GamepadService`, `ConfigService.file()`.
  - Domain service: `Xtend`, which depends on the above.
  - Controller: `XtendController`.
  - View: `XtendView`.
- **Notes**: `XtendApp.initialize()` populates the static instance and must be called before retrieving any dependency. The container is intentionally simple (no scopes), which matches the desktop app’s single-window lifetime.

### Xtend Service (`lib/service/xtend.dart`)
- **Role**: heart of the application; mediates between controller state, configuration, and OS side-effects.
- **Inputs**:
  - Streams from `GamepadService.stateStream`, `KeyboardInterface.charEventStream`, and `KeyboardInterface.keyEventStream`.
  - Configuration loaded from `ConfigService`.
- **Outputs**:
  - Synthetic mouse and keyboard events sent via `User32Api`.
  - Mode updates broadcast through `_modeStreamController`.
  - Updates to the injected `KeyboardInterface` (caps lock state, key presses).
- **Capabilities**:
  - Maintains current `XtendMode` (`mouse`, `keyboard`, `gamepad`, or `none`) and cycles modes when START+BACK are pressed simultaneously.
  - Applies configurable button/joystick mappings (`Config.gamepadMapping`) to convert controller deltas into OS events.
  - Implements acceleration curves for mouse movement and dead-zoning + directional logic for keyboard navigation.
  - Handles modifier chords (e.g., Ctrl+C) and layered joystick actions (scrolling, cursor movement).
  - Listens to the caps lock state while in keyboard mode to keep the virtual keyboard in sync.
  - Protects against redundant work by tracking the previous gamepad sample and ignoring unchanged packets.
- **Error handling**: encapsulates configuration errors as `XtendExceptionType` values surfaced to the UI so the user can see when defaults are used.

### GamepadService & XinputApi (`lib/data/xinput/*.dart`)
- **GamepadService**:
  - Spawns an isolate that polls `XInputGetState` every ~16 ms (roughly 60 Hz) to read controller state without blocking the UI isolate.
  - Uses a `ReceivePort` / `SendPort` handshake to ship raw JSON-serializable maps back to the main isolate, where they are converted into the immutable `Gamepad` model.
  - Implements cooperative shutdown by sending a `null` sentinel after the isolate has torn down native resources.
- **XinputApi**:
  - Thin FFI layer over `xinput1_4.dll`. Loads the library at runtime, exposes `readState`, and maps C structs into Dart-friendly shapes (`XINPUT_STATE` → `Gamepad`).
  - Responsibility for closing the dynamic library lies with the isolate upon exit.

### User32Api (`lib/data/user_32/user_32_api.dart`)
- **Function**: wraps the Win32 `user32.dll` APIs used to emit cursor and keyboard activity.
- **Implemented calls**:
  - `GetCursorPos`, `SetCursorPos`, `SendInput`, `GetKeyState`, and `VkKeyScanW`.
- **Key behaviours**:
  - Provides key-repeat support for keyboard events by scheduling timers when a key-down event occurs and cancelling on key-up.
  - Decodes characters into keyboard events + modifier requirements using `VkKeyScanW`, then dispatches modifiers around the main key press.
  - Supports combined vertical and horizontal scrolling via two mouse `INPUT` structures.
  - Exposes a polling-based caps lock stream used by `Xtend` while in keyboard mode.
  - Cleans up by cancelling timers and closing the dynamic library when disposed.

### ConfigService & Config Model (`lib/data/config/*`)
- `ConfigService.file()` handles persistence in `config.json` alongside the executable. On first run it writes the default `Config.standard()`.
- Configuration schema:
  ```json
  {
    "mouse": { "...": "ButtonAction" },
    "keyboard": { "...": "ButtonAction" }
  }
  ```
  where each property matches a `GamepadMapping` field (buttons, triggers, joystick actions).
- Robustness: JSON decoding errors throw `DeserializationException`, allowing the UI to notify the user while falling back to defaults.

### Virtual Keyboard Stack (`lib/view/keyboard/*`)
- **KeyboardController**:
  - Maintains observable state (`ValueNotifier`) for layout, cursor position, caps lock, and pressed keys.
  - Implements circular navigation with key repeat timers mirroring physical keyboard behaviour.
  - Emits a broadcast stream of `VirtualKeyEvent`s that differentiate textual keys, functional keys, and redirect keys.
- **VirtualKeyboardInterface**:
  - Adapts the controller to the `KeyboardInterface` contract expected by `Xtend`.
  - Splits text vs. functional events, mapping functional keys to `KeyboardEvent` codes and forwarding to the `User32Api`.
- **Keyboard widget**:
  - Renders keys based on the active `KeyboardLayout` definition (alphabetic/numeric or special characters).
  - Highlights selection and pressed keys, and supports layout switching via redirect keys.
- **Layouts**:
  - Defined declaratively in `KeyboardLayout` with cursor defaults and key geometry. `RedirectKey` toggles between layouts, enabling symbol entry without leaving controller mode.

### XtendController & XtendView (`lib/controller/xtend_controller.dart`, `lib/view/xtend_view.dart`)
- **XtendController**: thin facade that wires the `KeyboardController` into `Xtend.initialize` and exposes the mode stream to the view.
- **XtendView**:
  - Manages system tray initialization, window visibility, and keyboard overlay toggling.
  - Reacts to mode transitions: shows the keyboard overlay in keyboard mode, hides the window when exiting keyboard mode, otherwise shows a mode icon.
  - Provides user feedback when configuration errors occur by temporarily showing the error widget.
  - Integrates with `WindowUtil` to show the overlay without stealing focus and to auto-hide after a timeout.

### Platform Utilities (`lib/util/*.dart` and `windows/runner/*`)
- **WindowUtil**: wraps a platform channel (`window_util`) that allows Flutter code to show/hide/resize the transparent window without activating it, keeping the overlay unobtrusive.
- **SystemTrayUtil**: exposes add/remove tray icon commands and receives native callbacks when the tray menu invokes "Exit".
- **Windows runner changes** (`windows/runner/flutter_window.cpp` etc.):
  - Register the method channels used by the utilities.
  - Configure the window as always-on-top, transparent, and unfocusable when displaying overlays.
  - Create a system tray icon, handle popup menu selection, and bounce callbacks into Dart.
  - Keep the process alive when the window closes (`SetQuitOnClose(false)`) so the app runs headless in the tray.

## Configuration Schema & Mapping Logic
- `GamepadMapping` enumerates every actionable input (buttons, D-pad directions, triggers mapped as buttons, joysticks mapped as axes).
- `ButtonAction` options cover OS shortcuts (Win+D, Alt+Tab) and text-editing commands (Ctrl+C, Ctrl+V, etc.).
- `JoystickAction` differentiates mouse movement, scroll, keyboard navigation, or no-op.
- The configuration file stores the enum `name` for each mapping; `GamepadMapping.fromJson` performs name-to-enum resolution and throws if an unknown value is encountered.
- Updating `config.json` allows end users to remap controller behaviour without rebuilding the app.

## Control Flow Highlights
- **Mode switching**: On each gamepad sample, `_updateXtendMode` checks whether START and BACK transitioned to pressed simultaneously; if so, `_nextXtendMode` cycles modes and publishes the new mode.
- **Mouse mode**:
  - Left joystick coordinates are converted to a non-linear speed curve for cursor movement.
  - Right joystick emits scroll events on both axes.
  - Buttons fire the configured mouse or OS shortcuts through `User32Api`.
- **Keyboard mode**:
  - Left joystick drives virtual keyboard navigation with dead-zone filtering; whichever axis has the greatest magnitude determines direction.
  - Button mappings trigger `KeyboardController` actions (click, backspace, enter, caps lock, redirect).
  - Text keys stream into `User32Api.simulateCharacter`, which handles modifier requirements automatically.
- **Gamepad passthrough**: When `XtendMode.gamepad` is active the service ignores input, effectively yielding control back to the game/gamepad consumers.
- **Error presentation**: If config loading fails, `XtendView` surfaces a transient message and continues operating with defaults.

## Platform Channel Details
- Channels are registered in C++ so they are available immediately after the Flutter engine boots.
- `window_util` expects arguments `{width, height, center?, opacity}` for `showWindowWithoutFocus` and returns simple booleans.
- `system_tray_util` methods return booleans and may throw `PlatformException` which are wrapped in domain-specific exceptions for higher-level handling.
- Tray event callback `onExitMenuSelected` is invoked directly from native code when the user selects "Exit" from the tray menu; this keeps shutdown logic centralized in Dart.

## Extension & Testing Notes
- To add new controller actions, extend `ButtonAction` / `JoystickAction`, update JSON parsing, and implement the behaviour in `Xtend._getButtonAction` or `_getJoystickAction`.
- Additional keyboard layouts can be introduced by expanding `KeyboardLayoutType` and providing new factory constructors.
- Consider integrating structured logging around mode transitions and config loading to aid troubleshooting.
- When modifying FFI bindings, ensure structures remain packed correctly (`@Uint16`, etc.) and remember to release any allocated memory (`calloc.free`).
- Manual testing remains Windows-only; automated integration tests would need to mock `GamepadService` and `User32Api` to avoid relying on native DLLs.
