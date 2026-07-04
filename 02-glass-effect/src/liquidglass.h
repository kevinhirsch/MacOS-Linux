/*
    Tahoe Liquid Glass — KWin 6 (Plasma 6) desktop effect.

    DRAFT skeleton. Models the proven Better Blur architecture:
      * dual-Kawase downsample/upsample of the region BEHIND the target surface,
      * the FINAL upsample tap runs liquid_glass.frag which lenses/tints the blur.
    The heavy lifting (grabbing the backdrop into an offscreen FBO, iterating the
    down/upsample passes, per-output-scale handling, blur-region bookkeeping) is
    inherited conceptually from Better Blur; this header shows the shape a
    from-scratch fork would take and where the Tahoe-specific uniforms plug in.

    NOTE ON BASE CLASS: OffscreenEffect renders a window into an offscreen texture
    and lets you post-process it — handy if we ever want to distort the WINDOW.
    For "glass behind the surface" we mostly need the *backdrop*, which Better Blur
    grabs directly from the current render target, so we subclass Effect and manage
    our own FBOs like Better Blur does. We keep the OffscreenEffect include here
    because the window-decoration path (decorations get rendered by KWin into a
    texture) can reuse it. Pick one at implementation time; documented in the .cpp.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <memory>

#include <QVector2D>
#include <QVector4D>

#include <effect/effect.h>            // KWin::Effect, KWin::EffectWindow (KWin 6 path)
#include <opengl/glutils.h>           // KWin::GLShader, KWin::GLFramebuffer, KWin::GLTexture

namespace KWin
{

// Tahoe design tokens as runtime settings. Defaults are CALIBRATED to the
// "macOS 26 (Community)" Figma kit's native Glass effect (see ../parity/figma-extract.md
// and tokens/tahoe.json  material.glass.figma). Figma Glass params (constant across
// element sizes):  Refraction 100 · Depth 16 · Dispersion 0 · Splay 6 ·
// Light angle -45deg, intensity 67%.  Frost (backdrop blur) scales with size:
// Small 7 / Medium 12 / Large 14 px.  Medium/Light tint #F5F5F5@67% (over #262626);
// glass-layer fill #000@20%.  The KCM (kcm/) overrides these via KConfig group
// "TahoeLiquidGlass".  NB: Figma's params are on its own 0-100 scales; the mapping
// to these shader uniforms is documented per-field and is a starting point for the
// parity loop, not a physical identity.
struct LiquidGlassSettings
{
    // Which surfaces get glass. Because KWin can only touch windows it composites,
    // this is a list of window classes / roles (panels, plasmashell, docks,
    // menus) plus a toggle for window decorations. See honest-gaps in the .cpp.
    bool applyToDecorations = true;
    bool applyToPanels      = true;   // matches plasmashell panel surfaces
    bool applyToMenus       = true;   // matches Qt/GTK menu + tooltip surfaces

    // Blur == Figma "Frost". Iterations approximate the px radius; per-surface the
    // .cpp picks Small/Medium/Large = 7/12/14. Default = Medium (panels/menus).
    int   blurStrength      = 12;     // Figma Frost: 7 small / 12 medium / 14 large
    float noiseStrength     = 0.0f;   // dither to kill banding

    // ---- Liquid Glass optics ----
    float edgeSizePixels    = 20.0f;  // bezel band; informed by Figma Depth 16 / Splay 6
    float ior               = 2.4f;   // shader refract() IOR (Figma "Refraction 100" is its own scale)
    float superellipseN     = 4.0f;   // squircle exponent (tokens squircle.exponent)
    float refractionStrength= 0.45f;  // restrained master gain; Figma refraction=100 but edge-localized
    float rgbFringing       = 0.05f;  // Figma Dispersion 0 -> near-zero chromatic aberration

    // ---- Lighting (Figma Light -45deg, intensity 67%) ----
    QVector2D lightDir      = {-0.707f, -0.707f}; // -45deg: key light from top-left
    float specStrength      = 0.67f;              // Figma light intensity 67%
    float specShininess     = 40.0f;
    float fresnelStrength   = 0.6f;

    // ---- Material / variant ----
    // variant: 0 = Regular (tinted), 1 = Clear (near-clear + adaptive dim).
    int       variant       = 0;
    // Regular LIGHT tint = Figma #F5F5F5 (0.961) at a ~0.50 wash. Kit uses 0.67 over
    // its own frost; softened here since our blur already supplies the frost. Dark
    // glass swaps rgb toward #262626 (0.149) via the color scheme / KCM.
    QVector4D tintColor     = {0.961f, 0.961f, 0.961f, 0.50f};
    float     clearDim      = 0.35f;  // Clear dim over bright content (tokens clear.dimming)
    float     inkThreshold  = 0.36f;  // relative-luminance flip point (tokens adaptiveInk.flip)

    // Corners: per-surface, set by the .cpp from tokens (window 16 / menu 13 /
    // popover 20 / sheet 26 / dock 15). Default = window titlebar 16.
    float topCornerRadius   = 16.0f;
    float bottomCornerRadius= 16.0f;
    float antialiasing      = 1.0f;
    float opacity           = 1.0f;   // held ~constant; animate `materialize`.
};

class LiquidGlassEffect : public Effect
{
    Q_OBJECT

public:
    LiquidGlassEffect();
    ~LiquidGlassEffect() override;

    // KWin plugin gates (called by the factory macro in main.cpp).
    static bool supported();
    static bool enabledByDefault();

    // Effect priority: draw glass before the surface's own content lands.
    static int requestedEffectChainPosition()
    {
        return 20; // same neighbourhood as stock blur
    }

    // --- KWin 6 paint hooks ---
    void reconfigure(ReconfigureFlags flags) override;
    void prePaintScreen(ScreenPrePaintData &data, std::chrono::milliseconds time) override;
    void prePaintWindow(EffectWindow *w, WindowPrePaintData &data, std::chrono::milliseconds time) override;
    void drawWindow(const RenderTarget &renderTarget,
                    const RenderViewport &viewport,
                    EffectWindow *w,
                    int mask,
                    const QRegion &region,
                    WindowPaintData &data) override;

    bool provides(Feature feature) override;
    bool isActive() const override;

private:
    // Build all GLSL programs from the Qt resource (:/effects/tahoe_liquid_glass/...).
    bool loadShaders();
    // Decide whether this window is a glass target (class/role match + settings).
    bool shouldGlass(const EffectWindow *w) const;
    // Drive the show/hide "materialize" animation for a window (0..1).
    float materializeFor(const EffectWindow *w, std::chrono::milliseconds time);

    LiquidGlassSettings m_settings;

    // Downsample pass (unchanged Kawase, reused from Better Blur).
    struct {
        std::unique_ptr<GLShader> shader;
        int mvpMatrixLocation;
        int offsetLocation;
        int halfpixelLocation;
    } m_downsamplePass;

    // Upsample+lens pass: runs liquid_glass.frag. All Tahoe uniforms live here.
    struct {
        std::unique_ptr<GLShader> shader;
        int mvpMatrixLocation;
        int offsetLocation;
        int halfpixelLocation;

        // blur/noise
        int noiseLocation;
        int noiseTextureLocation;
        int noiseTextureSizeLocation;

        // geometry / corners
        int blurSizeLocation;
        int edgeSizePixelsLocation;
        int topCornerRadiusLocation;
        int bottomCornerRadiusLocation;
        int antialiasingLocation;
        int opacityLocation;

        // optics
        int iorLocation;
        int superellipseNLocation;
        int refractionStrengthLocation;
        int rgbFringingLocation;

        // lighting
        int lightDirLocation;
        int specStrengthLocation;
        int specShininessLocation;
        int fresnelStrengthLocation;

        // material / variant
        int variantLocation;
        int tintColorLocation;
        int clearDimLocation;
        int inkThresholdLocation;

        // animation
        int materializeLocation;
    } m_upsamplePass;

    std::unique_ptr<GLTexture> m_noiseTexture;

    // Per-target scratch FBOs for the down/upsample chain (allocated lazily).
    std::vector<std::unique_ptr<GLFramebuffer>> m_renderTargets;
    std::vector<GLTexture *>                    m_renderTextures;
};

} // namespace KWin
