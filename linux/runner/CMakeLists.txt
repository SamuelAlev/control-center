cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# libgcc_s must be the first NEEDED entry. This engine build's
# libflutter_linux_gtk.so exports its LLVM libunwind _Unwind_* symbols but not
# _Unwind_GetIPInfo; loaded first, it takes every C++ throw in the process,
# libstdc++'s personality hands its context to libgcc's _Unwind_GetIPInfo, and
# a plugin exception that should be caught (libsecret with no keyring running)
# ends in std::terminate. First in the lookup order, libgcc's unwinder wins.
target_link_options(${BINARY_NAME} PRIVATE
  "LINKER:--push-state,--no-as-needed" "-lgcc_s" "LINKER:--pop-state")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
# EGL through libepoxy, as the engine calls it: my_application.cc releases the
# contexts the engine's OpenGL renderer leaves current. GTK links epoxy itself.
pkg_check_modules(EPOXY REQUIRED IMPORTED_TARGET epoxy)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::EPOXY)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
