# Tahoe Liquid Glass — top-level CMake. Modeled on Better Blur (v1.5.0) /
# the KWin stock blur effect build, updated for Plasma 6 / KWin 6.4+.
#
# Build (from this directory):
#   mkdir build && cd build
#   cmake .. -DCMAKE_INSTALL_PREFIX=/usr
#   make -j$(nproc)
#   sudo make install
#
# Then: System Settings -> Desktop Effects -> enable "Tahoe Liquid Glass".
# ALWAYS delete build/ before rebuilding (KWin effect builds cache aggressively).

cmake_minimum_required(VERSION 3.16.0)

project(tahoe-liquid-glass VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# KWin 6.4 is the floor (same as Better Blur's final release). Effect ABI changes
# between minor Plasma releases; pin to your installed KWin if you hit link errors.
set(KWIN_MIN_VERSION "6.4.0")
set(QT_MIN_VERSION   "6.6.0")
set(KF6_MIN_VERSION  "6.0.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQtDeclareLoggingCategory)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core
    Gui
    DBus
    Widgets
    OpenGL
)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    ConfigWidgets
    CoreAddons
    KCMUtils
    I18n
    WindowSystem
)

# KWin's effect + OpenGL headers. Provided by kwin-dev (Debian/Ubuntu),
# kwin-devel (Fedora), or the kwin package (Arch).
find_package(KWin REQUIRED COMPONENTS kwineffects)

# Decoration API (for the window-decoration glass path).
find_package(KDecoration3 REQUIRED)

# libepoxy for GL entry points, same as stock blur.
find_package(epoxy REQUIRED)

add_subdirectory(src)
