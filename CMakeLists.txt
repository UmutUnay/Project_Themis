cmake_minimum_required(VERSION 3.16)

# Custom cmake functions path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(themis_custom_functions)

# Must have
set(_TARGET_NAME "main" CACHE STRING "Target to build: main or a plugin directory name")
message(STATUS "Built target: ${_TARGET_NAME}")
themis_setup_build_conf("${_TARGET_NAME}")
file(STRINGS "${CMAKE_BINARY_DIR}/conf/build.conf" THEMIS_CONFIG_LINES)

set(_VERSION_MAJOR 0)
set(_VERSION_MINOR 0)
set(_VERSION_SHAME 0)
set(_ARCH "null")
set(_PROJECT_NAME "Project_Themis")

foreach(line IN LISTS THEMIS_CONFIG_LINES)
    string(STRIP "${line}" line)
    if(line STREQUAL "" OR line MATCHES "^#")
        continue()
    endif()
    if(line MATCHES "^CONFIG_PROJECT_NAME=")
        string(REGEX REPLACE "^CONFIG_PROJECT_NAME=\"(.*)\"$" "\\1" _PROJECT_NAME "${line}")
    elseif(line MATCHES "^CONFIG_VERSION_MAJOR=")
        string(REGEX REPLACE "^CONFIG_VERSION_MAJOR=([0-9]+)$" "\\1" _VERSION_MAJOR "${line}")
    elseif(line MATCHES "^CONFIG_VERSION_MINOR=")
        string(REGEX REPLACE "^CONFIG_VERSION_MINOR=([0-9]+)$" "\\1" _VERSION_MINOR "${line}")
    elseif(line MATCHES "^CONFIG_VERSION_SHAME=")
        string(REGEX REPLACE "^CONFIG_VERSION_SHAME=([0-9]+)$" "\\1" _VERSION_SHAME "${line}")
    elseif(line MATCHES "^CONFIG_ARCH=")
        string(REGEX REPLACE "^CONFIG_ARCH=\"(.*)\"$" "\\1" _ARCH "${line}")
    endif()
endforeach()

# Compiler must be set BEFORE project()
if(_ARCH STREQUAL "ARM")
    set(CMAKE_C_COMPILER   /usr/bin/aarch64-linux-gnu-gcc)
    set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)
elseif(_ARCH STREQUAL "x86")
    set(CMAKE_C_COMPILER   /usr/bin/gcc)
    set(CMAKE_CXX_COMPILER /usr/bin/g++)
elseif(_ARCH STREQUAL "null")
    message(FATAL_ERROR "Architecture not found, aborting!...")
endif()

set(projName "${_PROJECT_NAME}")
set(projArch "${_ARCH}")
set(projVersion "${_VERSION_MAJOR}.${_VERSION_MINOR}.${_VERSION_SHAME}")
message(STATUS "Themis config: project='${projName}', architecture='${projArch}', version='${projVersion}'")

# project() must come before any add_subdirectory()
project("${projName}"
    VERSION "${projVersion}"
    LANGUAGES C CXX
)

string(REPLACE " " "_" projNameSanitized "${projName}")
# Each binary gets its own output name
set(FINAL_OUTPUT_NAME "${projNameSanitized}_${projArch}_v${projVersion}")
message(STATUS "Final output name:      ${FINAL_OUTPUT_NAME}")

# Default Standards
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

themis_select_target("${_TARGET_NAME}")
