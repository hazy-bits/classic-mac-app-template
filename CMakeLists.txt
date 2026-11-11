cmake_minimum_required(VERSION 3.27)
project(HelloClassic C)

option(CLASSIC_SMOKE_TEST "Run the guest smoke test and exit" OFF)

add_application(HelloClassic src/main.c src/HelloClassic.r CREATOR 'HeLo')
target_compile_features(HelloClassic PRIVATE c_std_11)

if(CLASSIC_SMOKE_TEST)
    if(NOT CLASSIC_MAC_HARNESS_DIR)
        message(FATAL_ERROR "CLASSIC_MAC_HARNESS_DIR is required for smoke builds")
    endif()
    add_subdirectory("${CLASSIC_MAC_HARNESS_DIR}/guest"
                     ${CMAKE_CURRENT_BINARY_DIR}/classic-test)
    target_link_libraries(HelloClassic PRIVATE classic-test)
    target_compile_definitions(HelloClassic PRIVATE CLASSIC_SMOKE_TEST)
endif()

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/HelloClassic.bin DESTINATION .)
if(CMAKE_SYSTEM_NAME STREQUAL "RetroCarbon")
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/HelloClassic.dsk DESTINATION . RENAME HelloClassic.img)
endif()
