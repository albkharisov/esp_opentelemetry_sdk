idf_component_register()

# This is a arch which doesn't affect opentelemetry-cpp lib
# but it helps to pass through the checks of root CMakeLists.txt
set(CMAKE_SYSTEM_PROCESSOR riscv)
option(WITH_STL CXX23)
set(WITH_STL CXX23)
set(CMAKE_POSITION_INDEPENDENT_CODE FALSE CACHE BOOL "PIC" FORCE)
set(WITH_ZIPKIN OFF CACHE BOOL "ZIPKIN" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "BUILD_TESTING" FORCE)
set(WITH_OTLP_GRPC OFF CACHE BOOL "OTLP_GRPC" FORCE)
set(WITH_OTLP_HTTP OFF CACHE BOOL "OTLP_HTTP" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "SHARED_LIBS" FORCE)
set(WITH_EXAMPLES OFF CACHE BOOL "EXAMPLES" FORCE)
set(OPENTELEMETRY_INSTALL OFF CACHE BOOL "OPENTELEMETRY_INSTALL" FORCE)

# This is necessery to skip linking resolution to second pthread-lib (yes, esp-idf contains 2)
# and to avoid conflict of names when both libs are linked.
# Here we define stub to pthread_atfork() which does nothing useful for us:
# it is intended to reseed RNG in new forked events. And since we
# dont have MMU and processes we assume forks are impossible,
# so we can replace this one pthread call (which is not implemented in ESP-iDF) with stub.
add_library(pthread_stubs src/pthread_stubs.c)
set(CMAKE_PREFIX_PATH_ORIG "${CMAKE_PREFIX_PATH}")
set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake;${CMAKE_PREFIX_PATH}")

if(CONFIG_OPENTELEMETRY_USE_OTLP)
  set(WITH_OTLP_FILE ON CACHE BOOL "OTLP_FILE" FORCE)
  set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/${CONFIG_OPENTELEMETRY_PROTOBUF_CMAKE_PATH};${CMAKE_PREFIX_PATH}")
  set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/third_party_installed")
endif()

add_subdirectory(opentelemetry-cpp EXCLUDE_FROM_ALL)

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH_ORIG}")
set(Thread_FOUND FALSE)

set(OPENTELEMETRY_TARGETS
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

if(CONFIG_OPENTELEMETRY_USE_OTLP)
    if(CONFIG_OPENTELEMETRY_CUSTOM_PROTO_COMPONENT)
        get_target_property(target_deps opentelemetry_otlp_recordable LINK_LIBRARIES)
        if(target_deps)
            set(new_deps "idf::${CONFIG_OPENTELEMETRY_CUSTOM_PROTO_COMPONENT}")
            foreach(dep ${target_deps})
                if(NOT "${dep}" STREQUAL "opentelemetry_proto" AND NOT "${dep}" MATCHES "^opentelemetry_proto::")
                    list(APPEND new_deps ${dep})
                endif()
            endforeach()
            set_target_properties(opentelemetry_otlp_recordable PROPERTIES LINK_LIBRARIES "${new_deps}")
        endif()

        get_target_property(interface_deps opentelemetry_otlp_recordable INTERFACE_LINK_LIBRARIES)
        if(interface_deps)
            set(new_interface_deps "")
            foreach(dep ${interface_deps})
                if(NOT "${dep}" STREQUAL "opentelemetry_proto" AND NOT "${dep}" MATCHES "^opentelemetry_proto::")
                    list(APPEND new_interface_deps ${dep})
                endif()
            endforeach()
            set_property(TARGET opentelemetry_otlp_recordable PROPERTY INTERFACE_LINK_LIBRARIES "${new_interface_deps}")
        endif()
    endif()

    list(APPEND OPENTELEMETRY_TARGETS opentelemetry_otlp_recordable)
endif()

# Include everything except for opentelemetry_api target
target_link_libraries(${COMPONENT_LIB} INTERFACE
    ${OPENTELEMETRY_TARGETS}
)

# The one left target (opentelemetry_api) will be pulled by opentelemetry_api component
