add_executable(${PROJECT_NAME}
    src/main.cpp
    src/apache_functions.cpp
)


themis_component_add(${PROJECT_NAME}
    # misc
    # thread
    dbus
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/bin"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:${PROJECT_NAME}>"
            "${CMAKE_SOURCE_DIR}/bin/${FINAL_OUTPUT_NAME}"
    COMMENT "Copying executable to ./bin/${FINAL_OUTPUT_NAME}"
)