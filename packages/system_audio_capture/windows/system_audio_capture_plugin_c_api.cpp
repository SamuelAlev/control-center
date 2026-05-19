#include "include/system_audio_capture/system_audio_capture_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "system_audio_capture_plugin.h"

void SystemAudioCapturePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  system_audio_capture::SystemAudioCapturePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
