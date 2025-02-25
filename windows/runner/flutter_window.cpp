#include "flutter_window.h"

#include <optional>
#include <memory> 
#include <windows.h>
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib") 
#include "resource.h"

#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_channel.h"        // For MethodChannel
#include "flutter/standard_method_codec.h"   // For StandardMethodCodec
#include "flutter/encodable_value.h"         // For EncodableValue

#define WM_TRAYICON (WM_USER + 2)
#define ID_TRAY_EXIT 1001

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::RegisterWindowUtilChannel() {
  // Create the method channel using the engine's messenger.
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "window_util",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("showWindowWithoutFocus") == 0) {
          // Extract properties from arguments.
          auto args = std::get<flutter::EncodableMap>(*call.arguments());
          double width = std::get<double>(args[flutter::EncodableValue("width")]);
          double height = std::get<double>(args[flutter::EncodableValue("height")]);
          int opacity = std::get<int>(args[flutter::EncodableValue("opacity")]);
          BYTE alpha = static_cast<BYTE>(opacity);
          bool center = false;
          if (args.find(flutter::EncodableValue("center")) != args.end()) {
            center = std::get<bool>(args[flutter::EncodableValue("center")]);
          }

          // If center is true, calculate centered coordinates.
          double x = 0;
          double y = 0;
          RECT desktopRect;
          HWND hDesktop = GetDesktopWindow();
          GetWindowRect(hDesktop, &desktopRect);
          int screenWidth = desktopRect.right - desktopRect.left;
          int screenHeight = desktopRect.bottom - desktopRect.top;
          x = (screenWidth - width) / 2;
          y = center ? ((screenHeight - height) / 2) : (screenHeight - height);

          // Use GetHandle() from the base Win32Window to get the HWND.
          HWND windowHandle = GetHandle();
          LONG style = GetWindowLong(windowHandle, GWL_STYLE);
          LONG exStyle = GetWindowLong(windowHandle, GWL_EXSTYLE);

          // Remove caption and borders.
          style &= ~(WS_CAPTION | WS_THICKFRAME);
          // Enable layered window style.
          exStyle |= WS_EX_LAYERED;
          // Add WS_EX_TOOLWINDOW and remove WS_EX_APPWINDOW.
          exStyle |= WS_EX_TOOLWINDOW;
          exStyle &= ~WS_EX_APPWINDOW;

          SetWindowLong(windowHandle, GWL_STYLE, style);
          SetWindowLong(windowHandle, GWL_EXSTYLE, exStyle);

          // Use per-pixel alpha: 255 makes the window fully opaque
          // so Flutter’s own alpha (e.g. transparent backgrounds) is respected.
          SetLayeredWindowAttributes(windowHandle, 0, alpha, LWA_ALPHA);

          // Extend the frame into the client area so that areas not painted by Flutter remain transparent.
          MARGINS margins;
          margins.cxLeftWidth   = -1;
          margins.cxRightWidth  = -1;
          margins.cyTopHeight   = -1;
          margins.cyBottomHeight = -1;
          DwmExtendFrameIntoClientArea(windowHandle, &margins);

          // Set window position and size.
          SetWindowPos(windowHandle, HWND_TOPMOST,
                       static_cast<int>(x),
                       static_cast<int>(y),
                       static_cast<int>(width),
                       static_cast<int>(height),
                       SWP_NOACTIVATE | SWP_SHOWWINDOW);

          // Show the window without activating it.
          ShowWindow(windowHandle, SW_SHOWNOACTIVATE);
          result->Success(flutter::EncodableValue(true));
        } else if (call.method_name().compare("hideWindow") == 0) {
          ShowWindow(GetHandle(), SW_HIDE);
          result->Success(flutter::EncodableValue(true));
         } else if (call.method_name().compare("closeWindow") == 0) {
          // Post a WM_CLOSE message to close the window gracefully.
          PostMessage(GetHandle(), WM_CLOSE, 0, 0);
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }

      });
}

void FlutterWindow::RegisterSystemTrayChannel() {
  system_tray_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "system_tray_util",
      &flutter::StandardMethodCodec::GetInstance());

  system_tray_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("addTrayIcon") == 0) {
          // Setup tray icon.
          NOTIFYICONDATA nid = {};
          nid.cbSize = sizeof(NOTIFYICONDATA);
          nid.hWnd = GetHandle();
          nid.uID = 2;  // Unique identifier.
          nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
          nid.uCallbackMessage = WM_TRAYICON;
          HICON trayIcon = static_cast<HICON>(
            LoadImage(GetModuleHandle(NULL),
                      MAKEINTRESOURCE(IDI_APP_ICON),
                      IMAGE_ICON,
                      32, 32,
                      LR_DEFAULTCOLOR)
          );
          nid.hIcon = trayIcon;
          wcscpy_s(nid.szTip, _countof(nid.szTip), L"xTend");
          if (Shell_NotifyIcon(NIM_ADD, &nid)) {
            result->Success(flutter::EncodableValue(true));
          } else {
            result->Error("TrayError", "Failed to add tray icon");
          }
        } else if (call.method_name().compare("removeTrayIcon") == 0) {
          NOTIFYICONDATA nid = {};
          nid.cbSize = sizeof(NOTIFYICONDATA);
          nid.hWnd = GetHandle();
          nid.uID = 2;
          if (Shell_NotifyIcon(NIM_DELETE, &nid)) {
            result->Success(flutter::EncodableValue(true));
          } else {
            result->Error("TrayError", "Failed to remove tray icon");
          }
        } else {
          result->NotImplemented();
        }
      });
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    //this->Show(); window_manager_plus instruction was to delete this line
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  //TODO Custom code
  RegisterWindowUtilChannel();
  RegisterSystemTrayChannel();
  
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TRAYICON:
      // Check for left/right button release.
      if (lparam == WM_RBUTTONUP || lparam == WM_LBUTTONUP) {
        POINT pt;
        GetCursorPos(&pt);
        // Create a temporary message-only window to own the popup menu.
        HWND hTemp = CreateWindowEx(0, L"STATIC", L"",
                                    WS_OVERLAPPEDWINDOW,
                                    CW_USEDEFAULT, CW_USEDEFAULT,
                                    CW_USEDEFAULT, CW_USEDEFAULT,
                                    HWND_MESSAGE, NULL, GetModuleHandle(NULL), NULL);
        // Bring hTemp to foreground without affecting main window.
        SetForegroundWindow(hTemp);
        HMENU hMenu = CreatePopupMenu();
        AppendMenu(hMenu, MF_STRING, ID_TRAY_EXIT, TEXT("Exit"));
        UINT clicked = TrackPopupMenu(hMenu,
                                      TPM_RETURNCMD | TPM_RIGHTBUTTON,
                                      pt.x, pt.y, 0, hTemp, NULL);
        // If the user selects "Exit", call back into Dart.
        if (clicked == ID_TRAY_EXIT) {
          if (system_tray_channel_) {
            system_tray_channel_->InvokeMethod("onExitMenuSelected", std::make_unique<flutter::EncodableValue>(true));
          }
        }
        DestroyMenu(hMenu);
        DestroyWindow(hTemp);
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
