#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

// Register codebench:// URI scheme in HKCU so it doesn't need elevation.
void RegisterUriScheme() {
  HKEY hKey;
  const wchar_t* scheme = L"SOFTWARE\\Classes\\codebench";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, scheme, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                      &hKey, nullptr) == ERROR_SUCCESS) {
    const wchar_t* desc = L"URL:Code Bench Protocol";
    RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(desc),
                   static_cast<DWORD>((wcslen(desc) + 1) * sizeof(wchar_t)));
    const wchar_t* urlProtocol = L"URL Protocol";
    RegSetValueExW(hKey, urlProtocol, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(L""),
                   static_cast<DWORD>(sizeof(wchar_t)));
    RegCloseKey(hKey);
  }
  // Set the command to open
  HKEY hCmdKey;
  const wchar_t* cmdPath =
      L"SOFTWARE\\Classes\\codebench\\shell\\open\\command";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, cmdPath, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                      &hCmdKey, nullptr) == ERROR_SUCCESS) {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);
    std::wstring cmd = std::wstring(L"\"") + exePath + L"\" \"%1\"";
    RegSetValueExW(hCmdKey, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(cmd.c_str()),
                   static_cast<DWORD>((cmd.length() + 1) * sizeof(wchar_t)));
    RegCloseKey(hCmdKey);
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  RegisterUriScheme();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"code_bench_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
