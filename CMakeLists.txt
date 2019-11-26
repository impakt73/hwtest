cmake_minimum_required (VERSION 3.10)

project(hwtest LANGUAGES CXX)

add_executable(hwtest src/main.cpp)

target_include_directories(hwtest PRIVATE src)

# TODO: Replace this with CMake FetchContent
set(PROTOBRIDGE_LIB_PATH "../protobridge")

set(PROTOBRIDGE_TRACE ON)
set(PROTOBRIDGE_HW_PATH "${CMAKE_CURRENT_SOURCE_DIR}/hw")

add_subdirectory(${PROTOBRIDGE_LIB_PATH} protobridge)
target_link_libraries(hwtest PRIVATE protobridge)
