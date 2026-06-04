# Kinda mirrored from ESP-IDF custom cmake functions go check'em out if interested

# Minimum requirement version is not much important but 3.16 is a good point I believe
cmake_minimum_required(VERSION 3.16)

# Globally list all the current components
set(THEMIS_COMPONENTS "" CACHE INTERNAL "Registered themis components")

# Register helper
function(themis_load_component comp_name)
    if(TARGET ${comp_name})
        return()
    endif()

    set(_comp_dir "${CMAKE_SOURCE_DIR}/components/${comp_name}")

    if(EXISTS "${_comp_dir}/CMakeLists.txt")
        add_subdirectory(
            "${_comp_dir}"
            "${CMAKE_BINARY_DIR}/components/${comp_name}"
        )
    else()
        message(FATAL_ERROR
            "themis_load_component(): component '${comp_name}' not found at "
            "${_comp_dir}"
        )
    endif()

    if(NOT TARGET ${comp_name})
        message(FATAL_ERROR
            "themis_load_component(): component '${comp_name}' was loaded, "
            "but target '${comp_name}' was not created. "
            "Check that it calls themis_component_register()."
        )
    endif()
endfunction()

# Compile the component
function(themis_component_register)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs SRCS INCLUDE_DIRS REQUIRES)
    cmake_parse_arguments(THEMIS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    get_filename_component(_comp_name ${CMAKE_CURRENT_SOURCE_DIR} NAME)

    # Auto-detect sources if not explicitly given
    if(NOT THEMIS_SRCS)
        file(GLOB_RECURSE THEMIS_SRCS CONFIGURE_DEPENDS
            "${CMAKE_CURRENT_SOURCE_DIR}/*.c"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
            "${CMAKE_CURRENT_SOURCE_DIR}/*.cc"
        )
    endif()

    # --- Header-only component case ---
    if(NOT THEMIS_SRCS)
        if(NOT THEMIS_INCLUDE_DIRS)
            message(FATAL_ERROR
                "themis_component_register(): no sources AND no include dirs "
                "for component '${_comp_name}' in ${CMAKE_CURRENT_SOURCE_DIR}"
            )
        endif()

        add_library(${_comp_name} INTERFACE)
        target_include_directories(${_comp_name} INTERFACE ${THEMIS_INCLUDE_DIRS})

        foreach(dep ${THEMIS_REQUIRES})
            themis_load_component(${dep})
            if(NOT TARGET ${dep})
                message(FATAL_ERROR
                    "themis_component_register(): required component '${dep}' "
                    "for '${_comp_name}' not found. Make sure its directory is "
                    "added with add_subdirectory() before this one."
                )
            endif()
            target_link_libraries(${_comp_name} INTERFACE ${dep})
        endforeach()

        if (TARGET themis_conf AND DEFINED THEMIS_CONF_H)
            add_dependencies(${_comp_name} themis_conf)
            target_compile_options(${_comp_name} INTERFACE
                -include "${THEMIS_CONF_H}"
            )
        endif()

        list(APPEND THEMIS_COMPONENTS ${_comp_name})
        set(THEMIS_COMPONENTS "${THEMIS_COMPONENTS}" CACHE INTERNAL "Registered themis components")
        message(STATUS "themis_component_register(): registered header-only component '${_comp_name}'")
        return()
    endif()

    # --- Normal component with sources ---
    add_library(${_comp_name} STATIC ${THEMIS_SRCS})
    target_include_directories(${_comp_name} PUBLIC ${THEMIS_INCLUDE_DIRS})
    target_compile_features(${_comp_name} PUBLIC cxx_std_23)

    foreach(dep ${THEMIS_REQUIRES})
        themis_load_component(${dep})
        if(NOT TARGET ${dep})
            message(FATAL_ERROR
                "themis_component_register(): required component '${dep}' "
                "for '${_comp_name}' not found. Make sure its directory is "
                "added with add_subdirectory() before this one."
            )
        endif()
        target_link_libraries(${_comp_name} PUBLIC ${dep})
    endforeach()

    if (TARGET themis_conf AND DEFINED THEMIS_CONF_H)
        add_dependencies(${_comp_name} themis_conf)
        target_compile_options(${_comp_name} PUBLIC
            -include "${THEMIS_CONF_H}"
        )
    endif()

    list(APPEND THEMIS_COMPONENTS ${_comp_name})
    set(THEMIS_COMPONENTS "${THEMIS_COMPONENTS}" CACHE INTERNAL "Registered themis components")
    message(STATUS "themis_component_register(): registered component '${_comp_name}'")
endfunction()

# Linking of compiled binaries of components
function(themis_component_add target_name)
    foreach(_comp ${ARGN})
        if(NOT TARGET ${_comp})
            set(_comp_dir "${CMAKE_SOURCE_DIR}/components/${_comp}")

            if(EXISTS "${_comp_dir}/CMakeLists.txt")
                add_subdirectory(
                    "${_comp_dir}"
                    "${CMAKE_BINARY_DIR}/components/${_comp}"
                )
            else()
                message(FATAL_ERROR
                    "themis_component_add(): component '${_comp}' not found at "
                    "${_comp_dir}"
                )
            endif()
        endif()

        if(NOT TARGET ${_comp})
            message(FATAL_ERROR
                "themis_component_add(): component '${_comp}' was added, "
                "but it did not create target '${_comp}'. "
                "Check that its CMakeLists.txt calls themis_component_register()."
            )
        endif()

        target_link_libraries(${target_name} PUBLIC ${_comp})
        message(STATUS "themis_component_add(): linked component '${_comp}' -> '${target_name}'")
    endforeach()

    if (TARGET themis_conf AND DEFINED THEMIS_CONF_H)
        get_target_property(_already ${target_name} THEMIS_CONF_INJECTED)

        if (NOT _already)
            add_dependencies(${target_name} themis_conf)

            target_compile_options(${target_name} PUBLIC
                -include "${THEMIS_CONF_H}"
            )

            set_property(TARGET ${target_name} PROPERTY THEMIS_CONF_INJECTED TRUE)
        endif()
    endif()
endfunction()

# Build Configs
function(themis_setup_build_conf target_name)
    if (NOT Python3_EXECUTABLE)
        find_package(Python3 REQUIRED COMPONENTS Interpreter)
    endif()

    set(THEMIS_BUILD_CONF_ROOT
        "${CMAKE_SOURCE_DIR}/build.conf"
        CACHE INTERNAL ""
    )

    set(THEMIS_SCRIPT
        "${CMAKE_SOURCE_DIR}/confgen.py"
        CACHE INTERNAL ""
    )

    set(THEMIS_CONF_H
        "${CMAKE_BINARY_DIR}/conf/conf.h"
        CACHE INTERNAL ""
    )

    set(THEMIS_BUILD_FINAL
        "${CMAKE_BINARY_DIR}/conf/build.conf"
        CACHE INTERNAL ""
    )

    add_custom_command(
        OUTPUT "${CMAKE_BINARY_DIR}/conf/build.conf"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_BINARY_DIR}/conf"
        COMMAND "${CMAKE_COMMAND}" -E touch "${CMAKE_BINARY_DIR}/conf/build.conf"
        COMMENT "Generating files and directories"
        VERBATIM
    )

    file(READ "${THEMIS_BUILD_CONF_ROOT}" _root_conf_contents)
    file(WRITE "${THEMIS_BUILD_FINAL}" "${_root_conf_contents}")

    if (NOT "${target_name}" STREQUAL "main")
        set(THEMIS_BUILD_CONF_TARGET
            "${CMAKE_SOURCE_DIR}/plugins/${target_name}/build.conf"
            CACHE INTERNAL ""
        )
        file(READ "${THEMIS_BUILD_CONF_TARGET}" _target_conf_contents)
        file(APPEND "${THEMIS_BUILD_FINAL}" "${_target_conf_contents}")
    endif()

    add_custom_command(
        OUTPUT "${THEMIS_CONF_H}"
        COMMAND "${Python3_EXECUTABLE}" "${THEMIS_SCRIPT}" "${THEMIS_BUILD_FINAL}" "${THEMIS_CONF_H}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        DEPENDS "${THEMIS_BUILD_FINAL}" "${THEMIS_SCRIPT}"
        COMMENT "Generating config files from build.conf's"
        VERBATIM
    )

    add_custom_target(themis_conf ALL
        DEPENDS "${THEMIS_CONF_H}"
    )
endfunction()

# Build Configs
function(themis_select_target target_name)
    set(THEMIS_TARGET_NAME
        "main"
        CACHE INTERNAL ""
    )
    if (NOT "${target_name}" STREQUAL "main")
        set(THEMIS_TARGET_NAME
            "plugins/${target_name}"
            CACHE INTERNAL ""
        )
    endif()

    # Add only components requested through themis_component_add()
    foreach(_comp_name ${THEMIS_COMPONENTS})
    if(NOT TARGET ${_comp_name})
        if(EXISTS "${CMAKE_SOURCE_DIR}/components/${_comp_name}/CMakeLists.txt")
            add_subdirectory("components/${_comp_name}")
        else()
                message(FATAL_ERROR
                    "themis_select_target(): registered component '${_comp_name}' not found at "
                    "${CMAKE_SOURCE_DIR}/components/${_comp_name}"
                )
            endif()
        endif()
    endforeach()

    add_subdirectory(${THEMIS_TARGET_NAME})
endfunction()