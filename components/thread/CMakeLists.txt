set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

themis_component_register(
    INCLUDE_DIRS
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    REQUIRES misc
)

target_link_libraries(thread INTERFACE Threads::Threads)