include(FetchContent)

# Fetch nlohmann_json if needed
FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json.git
  GIT_TAG v3.11.3
)
FetchContent_MakeAvailable(nlohmann_json)

# Your source files
set(SOURCES
    src/Client.cpp
    src/SSHManager.cpp
    src/ShellManager.cpp
    src/SCPManager.cpp
    src/LockfileManager.cpp
    src/RemoteController.cpp
    src/MessageHandler.cpp
    src/RulesManager.cpp
    src/TCPHandler.cpp
    src/functions.cpp
    src/rat_server_main.cpp
)

add_executable(${PROJECT_NAME}
    ${SOURCES}
)

# Register with themis build system
themis_component_add(${PROJECT_NAME}
    # misc
    # thread
    dbus
    http
)

# Include directories
target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${nlohmann_json_SOURCE_DIR}/include
)

# Link libraries
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        nlohmann_json::nlohmann_json
        pthread
)

# Copy to bin directory
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/bin"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:${PROJECT_NAME}>"
            "${CMAKE_SOURCE_DIR}/bin/${FINAL_OUTPUT_NAME}"
    COMMENT "Copying executable to ./bin/${FINAL_OUTPUT_NAME}"
)