#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  auto_updater_windows
  file_selector_windows
  flutter_inappwebview_windows
  flutter_secure_storage_windows
  flutter_webrtc
  irondash_engine_context
  local_notifier
  media_kit_libs_windows_audio
  record_windows
  sentry_flutter
  super_native_extensions
  system_audio_capture
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  cnativeapi
  flutter_pty
  jni
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
