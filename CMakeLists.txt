cmake_minimum_required(VERSION 3.6)
project(Suit)

set(SOURCE_FILES Sources)

find_package(PkgConfig)
pkg_check_modules(GLIB QUIET glib-2.0)
set(LIBXML2_DEFINITIONS ${PC_LIBXML_CFLAGS_OTHER})

add_custom_target(Suit
        COMMAND /home/pmacrory/swift-install/usr/bin/swift build
        -Xswiftc -I/usr/include/freetype2/
        -Xswiftc -I/usr/include/cairo/
        -Xswiftc -I/usr/include/pango-1.0/
        -Xswiftc -I/usr/include/glib-2.0/
        -Xswiftc -I/usr/lib/x86_64-linux-gnu/glib-2.0/include
        -Xswiftc -I/usr/include/
        -Xswiftc -L${CMAKE_SOURCE_DIR}/../SuitShims/bulld/
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES Package.swift ${SOURCE_FILES}
       )
