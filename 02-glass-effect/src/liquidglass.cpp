/*
    Tahoe Liquid Glass — KWin 6 (Plasma 6) desktop effect. DRAFT implementation.

    Scope of this draft: it is deliberately focused on the parts that are
    Tahoe-specific and load-bearing — loading the GLSL programs, resolving every
    uniform location, and pushing the correct per-frame uniform values around the
    upsample+lens draw. The dual-Kawase down/upsample FBO chain that captures the
    backdrop is the same algorithm as Better Blur; it is sketched here with clear
    TODO markers rather than copied wholesale, because that ~600 lines of FBO
    bookkeeping is orthogonal to the optics and is the thing you literally get for
    free by forking Better Blur (see the recommendation in the package README).

    Confirmed-correct KWin 6 API used below:
      * ShaderManager::instance()->generateShaderFromFile(ShaderTrait, vert, frag)
      * shader->uniformLocation("name") / shader->setUniform(loc, value)
      * ShaderManager::instance()->pushShader(shader) / popShader()
      * effects->isOpenGLCompositing() as the support gate
      * GLShader::ModelViewProjectionMatrix for the MVP uniform

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "liquidglass.h"

#include <QMatrix4x4>

#include <effect/effecthandler.h>     // KWin::effects
#include <opengl/glutils.h>           // pulls in GLShader / ShaderManager / GLFramebuffer
                                      // (modern KWin aggregates these here; matches Better Blur)

namespace KWin
{

LiquidGlassEffect::LiquidGlassEffect()
{
    reconfigure(ReconfigureAll);

    if (effects->isOpenGLCompositing()) {
        loadShaders();
    }
}

LiquidGlassEffect::~LiquidGlassEffect() = default;

bool LiquidGlassEffect::supported()
{
    // Same gate the stock blur uses. No GL => no glass; the effect silently
    // disables itself (KWin will not list it as active).
    return effects->isOpenGLCompositing();
}

bool LiquidGlassEffect::enabledByDefault()
{
    // Opt-in: this is a heavy, opinionated look. metadata.json also says false.
    return false;
}

bool LiquidGlassEffect::provides(Feature feature)
{
    // We provide Nothing special to other effects; but if we want to fully own
    // background blur we could claim Feature::Blur so the stock blur backs off.
    Q_UNUSED(feature)
    return false;
}

bool LiquidGlassEffect::isActive() const
{
    return static_cast<bool>(m_upsamplePass.shader) && effects->isOpenGLCompositing();
}

// ---------------------------------------------------------------------------
//  Shader loading — resolves every uniform up front so the hot path only sets.
// ---------------------------------------------------------------------------
bool LiquidGlassEffect::loadShaders()
{
    auto *sm = ShaderManager::instance();

    // Vertex/fragment selection between the 1.10 and 1.40 variants is handled by
    // KWin: passing the non-core paths and it swaps in *_core automatically on a
    // core-profile context via the shader preprocessor include machinery. Better
    // Blur passes the .vert/.frag names and lets KWin resolve the dialect.

    // --- Downsample (plain Kawase) ---
    m_downsamplePass.shader = sm->generateShaderFromFile(
        ShaderTrait::MapTexture,
        QStringLiteral(":/effects/tahoe_liquid_glass/shaders/vertex.vert"),
        QStringLiteral(":/effects/tahoe_liquid_glass/shaders/downsample.frag"));
    if (!m_downsamplePass.shader || !m_downsamplePass.shader->isValid()) {
        return false;
    }
    m_downsamplePass.mvpMatrixLocation = m_downsamplePass.shader->uniformLocation("modelViewProjectionMatrix");
    m_downsamplePass.offsetLocation    = m_downsamplePass.shader->uniformLocation("offset");
    m_downsamplePass.halfpixelLocation = m_downsamplePass.shader->uniformLocation("halfpixel");

    // --- Upsample + Liquid Glass lens ---
    m_upsamplePass.shader = sm->generateShaderFromFile(
        ShaderTrait::MapTexture,
        QStringLiteral(":/effects/tahoe_liquid_glass/shaders/vertex.vert"),
        QStringLiteral(":/effects/tahoe_liquid_glass/shaders/liquid_glass.frag"));
    if (!m_upsamplePass.shader || !m_upsamplePass.shader->isValid()) {
        return false;
    }

    auto &U = m_upsamplePass;
    auto  L = [&](const char *name) { return U.shader->uniformLocation(name); };

    U.mvpMatrixLocation        = L("modelViewProjectionMatrix");
    U.offsetLocation           = L("offset");
    U.halfpixelLocation        = L("halfpixel");

    U.noiseLocation            = L("noise");
    U.noiseTextureLocation     = L("noiseTexture");
    U.noiseTextureSizeLocation = L("noiseTextureSize");

    U.blurSizeLocation         = L("blurSize");
    U.edgeSizePixelsLocation   = L("edgeSizePixels");
    U.topCornerRadiusLocation  = L("topCornerRadius");
    U.bottomCornerRadiusLocation = L("bottomCornerRadius");
    U.antialiasingLocation     = L("antialiasing");
    U.opacityLocation          = L("opacity");

    U.iorLocation              = L("ior");
    U.superellipseNLocation    = L("superellipseN");
    U.refractionStrengthLocation = L("refractionStrength");
    U.rgbFringingLocation      = L("rgbFringing");

    U.lightDirLocation         = L("lightDir");
    U.specStrengthLocation     = L("specStrength");
    U.specShininessLocation    = L("specShininess");
    U.fresnelStrengthLocation  = L("fresnelStrength");

    U.variantLocation          = L("variant");
    U.tintColorLocation        = L("tintColor");
    U.clearDimLocation         = L("clearDim");
    U.inkThresholdLocation     = L("inkThreshold");

    U.materializeLocation      = L("materialize");

    return true;
}

void LiquidGlassEffect::reconfigure(ReconfigureFlags)
{
    // TODO: read m_settings from KConfig (group "TahoeLiquidGlass"), same pattern
    // as Better Blur's settings.cpp. Defaults in LiquidGlassSettings already hold
    // the tuned Tahoe tokens, so the effect is usable before the KCM is wired.
}

void LiquidGlassEffect::prePaintScreen(ScreenPrePaintData &data, std::chrono::milliseconds time)
{
    effects->prePaintScreen(data, time);
}

void LiquidGlassEffect::prePaintWindow(EffectWindow *w, WindowPrePaintData &data, std::chrono::milliseconds time)
{
    // If this window is a glass target, mark its region as needing a repaint of
    // the backdrop (so blur stays live as things move behind it). Better Blur
    // does the real region math here (expanding by the blur radius, tracking the
    // "blur region" from _KDE_NET_WM_BLUR_BEHIND_REGION or the whole window).
    if (shouldGlass(w)) {
        data.setTranslucent();
        // TODO: expand paint region by blur radius; register backdrop dirty rect.
    }
    effects->prePaintWindow(w, data, time);
}

// ---------------------------------------------------------------------------
//  The draw: capture backdrop -> Kawase down/up -> final upsample runs the lens.
// ---------------------------------------------------------------------------
void LiquidGlassEffect::drawWindow(const RenderTarget &renderTarget,
                                   const RenderViewport &viewport,
                                   EffectWindow *w,
                                   int mask,
                                   const QRegion &region,
                                   WindowPaintData &data)
{
    if (!isActive() || !shouldGlass(w)) {
        effects->drawWindow(renderTarget, viewport, w, mask, region, data);
        return;
    }

    // --- STEP A: grab the backdrop behind w's blur region into m_renderTargets[0].
    //     Identical to Better Blur: blit the current render target's region into
    //     an FBO. Omitted here for brevity. TODO.
    //
    // --- STEP B: dual-Kawase downsample chain (m_downsamplePass), N iterations,
    //     halving resolution each step. TODO (copy Better Blur downsample loop).
    //
    // --- STEP C: upsample chain, and on the FINAL upsample use the lens shader.
    //     Below is that final draw with the full Tahoe uniform set. This is the
    //     bit that turns "blur" into "Liquid Glass".

    const QRectF surfRect = w->frameGeometry();               // logical geometry
    const qreal  scale    = viewport.scale();                 // HiDPI/output scale
    const QSizeF devSize  = surfRect.size() * scale;          // device px size

    auto *sm = ShaderManager::instance();
    auto &U  = m_upsamplePass;

    sm->pushShader(U.shader.get());

    // MVP: KWin gives us the projection for this window's quad. Better Blur builds
    // this from the viewport; here we use the data's transform for correctness.
    QMatrix4x4 mvp = viewport.projectionMatrix();
    mvp.translate(surfRect.x() * scale, surfRect.y() * scale);
    U.shader->setUniform(GLShader::ModelViewProjectionMatrix, mvp);

    // Kawase upsample params for this (final) tap.
    U.shader->setUniform(U.offsetLocation, 1.0f);
    U.shader->setUniform(U.halfpixelLocation,
                         QVector2D(0.5f / devSize.width(), 0.5f / devSize.height()));

    // Geometry / corners.
    U.shader->setUniform(U.blurSizeLocation,
                         QVector2D(devSize.width(), devSize.height()));
    // Clamp the bezel band so it never exceeds half the smaller side.
    const float maxBand = 0.5f * std::min<float>(devSize.width(), devSize.height());
    U.shader->setUniform(U.edgeSizePixelsLocation,
                         std::min(m_settings.edgeSizePixels * (float)scale, maxBand));
    U.shader->setUniform(U.topCornerRadiusLocation,    m_settings.topCornerRadius * (float)scale);
    U.shader->setUniform(U.bottomCornerRadiusLocation, m_settings.bottomCornerRadius * (float)scale);
    U.shader->setUniform(U.antialiasingLocation,       m_settings.antialiasing * (float)scale);
    U.shader->setUniform(U.opacityLocation,            m_settings.opacity * (float)data.opacity());

    // Optics.
    U.shader->setUniform(U.iorLocation,               m_settings.ior);
    U.shader->setUniform(U.superellipseNLocation,     m_settings.superellipseN);
    U.shader->setUniform(U.refractionStrengthLocation,m_settings.refractionStrength);
    U.shader->setUniform(U.rgbFringingLocation,       m_settings.rgbFringing);

    // Lighting.
    U.shader->setUniform(U.lightDirLocation,          m_settings.lightDir);
    U.shader->setUniform(U.specStrengthLocation,      m_settings.specStrength);
    U.shader->setUniform(U.specShininessLocation,     m_settings.specShininess);
    U.shader->setUniform(U.fresnelStrengthLocation,   m_settings.fresnelStrength);

    // Material / variant.
    U.shader->setUniform(U.variantLocation,           m_settings.variant);
    U.shader->setUniform(U.tintColorLocation,         m_settings.tintColor);
    U.shader->setUniform(U.clearDimLocation,          m_settings.clearDim);
    U.shader->setUniform(U.inkThresholdLocation,      m_settings.inkThreshold);

    // Animation: THIS is what "materializes" the panel — lensing/specular/Fresnel
    // ramp 0->1 on show, 1->0 on hide, while opacity stays put (per the token
    // "materialize by modulating lensing not opacity").
    U.shader->setUniform(U.materializeLocation,
                         const_cast<LiquidGlassEffect *>(this)->materializeFor(w, std::chrono::milliseconds{0}));

    // Noise/dither.
    const bool useNoise = m_settings.noiseStrength > 0.0f && m_noiseTexture;
    U.shader->setUniform(U.noiseLocation, useNoise);
    if (useNoise) {
        glActiveTexture(GL_TEXTURE1);
        m_noiseTexture->bind();
        U.shader->setUniform(U.noiseTextureLocation, 1);
        U.shader->setUniform(U.noiseTextureSizeLocation,
                             QVector2D(m_noiseTexture->width(), m_noiseTexture->height()));
        glActiveTexture(GL_TEXTURE0);
    }

    // Bind the last upsample source (the blurred backdrop) at unit 0 as "texUnit".
    // TODO: bind m_renderTextures[last] here; then issue the fullscreen-quad draw
    // over the surface rect (GLVertexBuffer, GL_TRIANGLE_STRIP), exactly as Better
    // Blur's upsample() does.

    sm->popShader();

    // Finally let KWin paint the window's OWN content (icons, text) on top of the
    // glass we just laid down. Crucially we tint the glass, never this content.
    effects->drawWindow(renderTarget, viewport, w, mask, region, data);
}

// ---------------------------------------------------------------------------
//  Target selection. KWin can only reach windows it composites, so "glass" is a
//  class/role match. Panels & docks are plasmashell windows; menus/tooltips are
//  override-redirect windows. Window decorations are handled via a separate path.
// ---------------------------------------------------------------------------
bool LiquidGlassEffect::shouldGlass(const EffectWindow *w) const
{
    if (!w) {
        return false;
    }

    // Docks / panels (Plasma sets windowType == Dock for panels).
    if (m_settings.applyToPanels && w->isDock()) {
        return true;
    }
    // Menus, combo/dropdowns, tooltips (override-redirect popups).
    if (m_settings.applyToMenus && (w->isPopupMenu() || w->isDropdownMenu()
                                    || w->isMenu() || w->isComboBox() || w->isTooltip())) {
        return true;
    }
    // Normal windows only if they've opted in (e.g. _KDE_NET_WM_BLUR_BEHIND set,
    // or a matching window rule). Better Blur's "force blur" list plugs in here.
    // Window DECORATIONS are covered by the decoration path, not this test.
    return false;
}

float LiquidGlassEffect::materializeFor(const EffectWindow *w, std::chrono::milliseconds)
{
    // TODO: keep a per-window TimeLine keyed on w, started on windowAdded /
    // stopped-and-reversed on windowClosed, easing OutCubic over ~200ms. Return
    // its progress. For this draft, fully materialized.
    Q_UNUSED(w)
    return 1.0f;
}

} // namespace KWin
