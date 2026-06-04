find_package(PkgConfig REQUIRED)
include(FetchContent)
pkg_check_modules(DBUS REQUIRED IMPORTED_TARGET dbus-1)

themis_component_register(
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${DBUS_INCLUDE_DIRS}
    REQUIRES misc thread
)

FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json.git
  GIT_TAG v3.11.3
)
FetchContent_MakeAvailable(nlohmann_json)
FetchContent_GetProperties(nlohmann_json)

target_link_libraries(dbus PUBLIC PkgConfig::DBUS)
target_link_libraries(dbus PUBLIC nlohmann_json::nlohmann_json)