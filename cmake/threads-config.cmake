set(Threads_FOUND TRUE)
add_library(Threads::Threads INTERFACE IMPORTED)

target_link_libraries(Threads::Threads INTERFACE pthread_stubs)

