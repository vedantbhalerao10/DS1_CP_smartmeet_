cmake_minimum_required(VERSION 3.20)

project(SmartMeetContactEngine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

FetchContent_Declare(
    json
    URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz
)

FetchContent_MakeAvailable(json)

add_executable(
    smartmeet_contact_engine
    src/main.cpp
    src/contact_manager.cpp
    src/trie.cpp
)

add_executable(
    smartmeet_engine_api
    src/engine_api.cpp
    src/contact_manager.cpp
    src/trie.cpp
)

target_include_directories(
    smartmeet_contact_engine
    PRIVATE
    include
)

target_include_directories(
    smartmeet_engine_api
    PRIVATE
    include
)

target_link_libraries(
    smartmeet_engine_api
    PRIVATE
    nlohmann_json::nlohmann_json
)