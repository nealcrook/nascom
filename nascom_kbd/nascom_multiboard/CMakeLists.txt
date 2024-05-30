cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(nascom_multiboard_project C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
pico_sdk_init()

add_executable(nascom_multiboard
        nascom_multiboard.c
)

pico_enable_stdio_usb(nascom_multiboard 1)
pico_enable_stdio_uart(nascom_multiboard 0)

pico_add_extra_outputs(nascom_multiboard)

target_link_libraries(nascom_multiboard
        pico_stdlib
        pico_multicore)
