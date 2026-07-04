/*
    Tahoe Liquid Glass — KWin 6 effect plugin entry point.

    This mirrors the exact factory pattern used by the KWin stock blur effect and
    by Better Blur (taj-ny/kwin-effects-forceblur). The macro registers the effect
    class with KWin's plugin loader, wires metadata.json, and exposes the static
    supported()/enabledByDefault() gates so KWin can skip the effect on unsupported
    backends (e.g. software compositing).

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "liquidglass.h"

namespace KWin
{

KWIN_EFFECT_FACTORY_SUPPORTED_ENABLED(LiquidGlassEffect,
                                      "metadata.json",
                                      return LiquidGlassEffect::supported();
                                      ,
                                      return LiquidGlassEffect::enabledByDefault();)

} // namespace KWin

#include "main.moc"
