# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "system_audio_capture")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "system_audio_capture_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "system_audio_capture_plugin.cpp"
  "system_audio_capture_plugin.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/system_audio_capture/system_audio_capture_plugin_c_api.h"
  "system_audio_capture_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Require C++17 for std::optional, structured bindings, and inline statics.
target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_17)

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# <windows.h> defines min/max as macros, which break std::min/std::max (e.g.
# in FloatToInt16). NOMINMAX suppresses them for the whole translation unit; it
# must be defined before any windows.h include, so set it on the target rather
# than in a source file.
target_compile_definitions(${PLUGIN_NAME} PRIVATE NOMINMAX)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

# flutter / flutter_wrapper_plugin: the Flutter C++ client wrapper.
# Ole32       : CoInitializeEx / CoCreateInstance / CoTaskMemFree (COM).
# Mmdevapi    : IMMDeviceEnumerator / MMDeviceEnumerator (Core Audio device API).
#               WASAPI interfaces (IAudioClient / IAudioCaptureClient) resolve
#               through this and the headers in the Windows SDK.
# Avrt        : AvSetMmThreadCharacteristics (raise the capture thread to the
#               "Pro Audio" MMCSS task for glitch-free real-time capture).
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  Mmdevapi
  Ole32
  Avrt)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(system_audio_capture_bundled_libraries
  ""
  PARENT_SCOPE)
