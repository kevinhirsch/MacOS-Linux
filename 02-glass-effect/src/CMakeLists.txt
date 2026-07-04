# src/CMakeLists.txt — builds the KWin effect plugin .so and installs it into
# KWin's binary-effect plugin directory. This is the modern (Plasma 6) location:
#   ${KDE_INSTALL_PLUGINDIR}/kwin/effects/plugins/    (e.g. /usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/)
# NOT the old ~/.local/share/kwin/effects/<id>/ scripted-effect layout — that path
# is for QML/JS scripted effects, which cannot run custom GLSL. Binary effects are
# regular Qt plugins discovered by KWin's plugin loader by their metadata Id.

set(effect_SRCS
    main.cpp
    liquidglass.cpp
    liquidglass.qrc          # AUTORCC compiles the shaders into the .so
)

# kwin_add_effect() is provided by the KWin CMake package and does the right
# thing (plugin target, MOC, install path, metadata handling). If your KWin
# package does not export it, fall back to the qt_add_plugin block below.
if(COMMAND kwin_add_effect)
    kwin_add_effect(kwin_tahoe_liquid_glass ${effect_SRCS})
    target_link_libraries(kwin_tahoe_liquid_glass
        PRIVATE
            Qt6::Core
            Qt6::Gui
            Qt6::OpenGL
            KF6::ConfigWidgets
            KF6::CoreAddons
            KF6::I18n
            KWin::kwineffects
            epoxy::epoxy
    )
else()
    # --- Fallback: raw Qt plugin, explicit install path. ---
    qt_add_plugin(kwin_tahoe_liquid_glass SHARED ${effect_SRCS})
    set_target_properties(kwin_tahoe_liquid_glass PROPERTIES
        OUTPUT_NAME kwin_tahoe_liquid_glass
    )
    target_link_libraries(kwin_tahoe_liquid_glass
        PRIVATE
            Qt6::Core Qt6::Gui Qt6::OpenGL
            KF6::ConfigWidgets KF6::CoreAddons KF6::I18n
            KWin::kwineffects
            epoxy::epoxy
    )
    install(TARGETS kwin_tahoe_liquid_glass
            DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/plugins/)
endif()

# --- Optional: the KCM (settings page in System Settings). ---
# Sketch only; wire up when kcm/ is populated. It builds a second small plugin
# whose Id matches metadata.json's "X-KDE-ConfigModule": kwin_tahoe_liquid_glass_config.
# add_subdirectory(kcm)
