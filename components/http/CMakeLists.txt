include(FetchContent)

FetchContent_Declare(
  httplib_upstream
  GIT_REPOSITORY https://github.com/yhirose/cpp-httplib.git
  GIT_TAG v0.29.0
)
FetchContent_MakeAvailable(httplib_upstream)
FetchContent_GetProperties(httplib_upstream)

themis_component_register(
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    REQUIRES misc thread
)

if(TARGET httplib::httplib)
  target_link_libraries(http PUBLIC httplib::httplib)
endif()

