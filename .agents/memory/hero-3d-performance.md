---
name: HeroSection 3D performance
description: Speed tuning and dark mode wiring for the R3F courtroom hero scene.
---

# HeroSection 3D Performance & Dark Mode

## Speed settings (post-tuning)
- `CinematicCamera`: `delta * 0.50` → ~2s fly-in (was 0.19 ~5.2s)
- `RiseGroup`: `delta * 4.5` → snappy rise (was 1.45, sluggish)
- Reveal phase timers: `[80, 220, 380, 540, 740]` ms (was `[180, 580, 1020, 1460, 2050]`)
- Scroll duration `dur = 900` ms (was 2800)

## Dark mode prop threading
`HeroSection` → `GavelScene(isDark)` → `BackWall(isDark)`, `MarbleFloor(isDark)`, `GavelMesh(isDark)`

## Dark mode lighting (GavelScene)
- Ambient: near-black `#0a102a`, intensity 0.10 (very low)
- Key light becomes cold moonlight `#6878c8`
- Extra gold `pointLight` nodes added inside `{isDark && <>` block for rim glow
- Spot: burgundy `#7C1D2B` → deep indigo `#1020b0`
- All gold point lights boosted 2–3× intensity
- `Environment preset`: `"warehouse"` → `"night"`
- `toneMappingExposure`: `1.65` in dark (was `1.32`)

## Dark mode materials
- BackWall: `#cec8be` → `#080808`, roughness 0.55→0.9
- MarbleFloor: `#e8e2d8` → `#0c0c0c`; vein lines become gold `#D4AF37`
- GavelMesh barrel: near-void `#030100`, metalness 0.55, envMapIntensity 8.5
- GavelMesh ferrule/collar: `emissiveIntensity` 0.38 (was 0.06) for gold glow

**Why:** Dark mode 3D requires boosted emissive/point lights to compensate for the near-black ambient; warm lights become cold/blue, gold accents become the dominant light source.
