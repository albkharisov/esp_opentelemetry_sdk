idf_component_register()

# This is a arch which doesn't affect opentelemetry-cpp lib
# but it helps to pass through the checks of root CMakeLists.txt
set(CMAKE_SYSTEM_PROCESSOR riscv)
option(WITH_STL CXX23)
set(WITH_STL CXX23)
option(CMAKE_POSITION_INDEPENDENT_CODE FALSE)
option(WITH_ZIPKIN OFF)
option(BUILD_TESTING OFF)
option(WITH_OTLP_GRPC OFF)
option(WITH_OTLP_HTTP OFF)
option(BUILD_SHARED_LIBS OFF)
option(WITH_EXAMPLES OFF)

# This is necessery to skip linking resolution to second pthread-lib (yes, esp-idf contains 2)
# and to avoid conflict of names when both libs are linked.
# Here we define stub to pthread_atfork() which does nothing useful for us:
# it is intended to reseed RNG in new forked events. And since we
# dont have MMU and processes we assume forks are impossible,
# so we can stab this one pthread call (which is not implemented in ESP-iDF) with stub.
add_library(pthread_stubs src/pthread_stubs.c)
set(CMAKE_PREFIX_PATH_ORIG "${CMAKE_PREFIX_PATH}")
set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR};${CMAKE_PREFIX_PATH}")

add_subdirectory(opentelemetry-cpp)

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH_ORIG}")
set(Thread_FOUND FALSE)

# Include everything except for opentelemetry_api target
target_link_libraries(${COMPONENT_LIB} INTERFACE
    opentelemetry_sdk
    opentelemetry_common
    opentelemetry_trace
    opentelemetry_metrics
    opentelemetry_logs
    opentelemetry_version
    opentelemetry_resources
    opentelemetry_ext
    opentelemetry_exporter_ostream_span
    opentelemetry_exporter_ostream_metrics
    opentelemetry_exporter_ostream_logs
    opentelemetry_exporter_in_memory
    opentelemetry_exporter_in_memory_metric
)

# This way we pass dependency name to esp_opentelemetry_api
set_target_properties(${COMPONENT_LIB}
    PROPERTIES
        OPENTELEMETRY_API_TARGET opentelemetry_api
)

