cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "archive_extract")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

find_package(PkgConfig REQUIRED)
pkg_check_modules(ARCHIVE REQUIRED IMPORTED_TARGET libarchive)

add_library(${PLUGIN_NAME} SHARED
  archive_extract_plugin.cc
  ../shared/libarchive_extract.c
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  C_VISIBILITY_PRESET hidden
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME}
  INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../shared"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  PkgConfig::ARCHIVE
)
