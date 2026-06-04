cmake_minimum_required(VERSION 3.16)
project(client_agent LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── nlohmann/json ─────────────────────────────────────────────────────────────
# FetchContent instead of find_package so no system install is required on
# the remote target machine.
include(FetchContent)
FetchContent_Declare(
    nlohmann_json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG        v3.11.3
)
FetchContent_MakeAvailable(nlohmann_json)

# ── libdbus-1 ─────────────────────────────────────────────────────────────────
find_package(PkgConfig REQUIRED)
pkg_check_modules(DBUS REQUIRED dbus-1)

# ── Sources ───────────────────────────────────────────────────────────────────
set(SOURCES
    src/Agent.cpp
    src/MessageHandler.cpp
    src/TCPClient.cpp
    src/LockfileManager.cpp
    src/main.cpp
)

add_executable(client_agent ${SOURCES})

# ── Includes ──────────────────────────────────────────────────────────────────
target_include_directories(client_agent PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${DBUS_INCLUDE_DIRS}
)

# ── Link ──────────────────────────────────────────────────────────────────────
target_link_libraries(client_agent PRIVATE
    nlohmann_json::nlohmann_json   # exposes headers via imported target
    ${DBUS_LIBRARIES}
    pthread
)

# Pass dbus-1 compile flags (e.g. -D_REENTRANT) to all agent sources
target_compile_options(client_agent PRIVATE
    ${DBUS_CFLAGS_OTHER}
)

# ── Output ────────────────────────────────────────────────────────────────────
add_custom_command(TARGET client_agent POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/bin"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:client_agent>"
        "${CMAKE_SOURCE_DIR}/bin/client_agent"
    COMMENT "Copying client_agent to ./bin/"
)