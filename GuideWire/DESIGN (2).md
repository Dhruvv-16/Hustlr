# Design System Strategy: The Ethereal Night Atelier

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Ethereal Night Atelier."** 

This is not a standard dark mode; it is a high-end, editorial environment that mimics the quiet precision of a midnight workshop. We move away from the "boxy" nature of traditional dashboards by embracing a **Split-Canvas** layout and the **No-Line Rule**. By removing structural borders and relying on tonal shifts, the interface feels like an interconnected organic entity rather than a series of disconnected modules.

The experience is defined by:
*   **Intentional Asymmetry:** Breaking the rigid grid to guide the eye through editorial-style pacing.
*   **Luminous Accents:** Using "Electric Mint" as a digital ink that glows against deep obsidian surfaces.
*   **Atmospheric Depth:** Utilizing glassmorphism and primary-tinted ambient shadows to create a sense of floating, ethereal layers.

---

## 2. Color Philosophy & The "No-Line" Rule
The palette is rooted in deep, obsidian foundations with high-energy accents.

### The Palette
*   **Surface (Level 0):** `#0a0b0a` — The foundation. Use for the primary canvas.
*   **Surface-Container-Low (Level 1):** `#141614` — Used for secondary zones or large background shifts.
*   **Surface-Container-Lowest (Level 2):** `#1c1f1c` — Reserved for interactive elements like cards and input fields.
*   **Primary:** `#3fff8b` (Electric Mint) — Our signature "ink" for CTAs and critical information.
*   **Primary-Container:** `#004734` (Deep Forest) — A sophisticated backdrop for primary-colored icons or subtle callouts.
*   **On-Surface:** `#e1e3de` — Off-white, high-contrast text for maximum readability.
*   **On-Surface-Variant:** `#91938d` — Muted grey for metadata and secondary labels.

### The "No-Line" Rule
**Prohibit 1px solid borders for sectioning.** 
Structural boundaries must be defined solely through background color shifts or the **Split-Canvas** layout (e.g., a `surface-container-low` panel sitting flush against a `surface` background). If you feel the need to "separate" content, use vertical white space from our spacing scale (e.g., `spacing.12` or `spacing.16`) rather than a divider.

### The Glass & Gradient Rule
To achieve a premium "atelier" feel, floating navigation or overlay elements should use **Glassmorphism**:
*   **Fill:** `surface` at 60% opacity.
*   **Effect:** 20px Backdrop Blur.
*   **Signature Texture:** Main CTAs must use a linear gradient from `#3fff8b` (Primary) to `#00E676` to provide a sense of luminous depth.

---

## 3. Typography
We use **Manrope** exclusively. Its geometric yet approachable nature supports the "Organic" brand identity while maintaining technical precision.

*   **The Hook (Headline-SM):** 1.5rem (30px). Use this for introductory statements or "hooks" in `on-surface`. It should feel authoritative but breathable.
*   **Display Scales:** Use `display-lg` (3.5rem) for hero moments. These should be treated as graphic elements, often overlapping background transitions.
*   **Body & Labels:** Use `body-lg` (1rem) for primary reading and `label-md` (0.75rem) for secondary metadata.

**Editorial Tip:** To maintain the premium feel, increase line-height for body copy to 1.6x and ensure wide tracking (letter-spacing) for labels to evoke high-end fashion typography.

---

## 4. Elevation & Depth
In this system, depth is "felt" rather than "seen." 

### The Layering Principle
Hierarchy is achieved by stacking surface tiers. A `surface-container-lowest` card placed on a `surface` background creates a soft, natural lift. This "nested depth" mimics layers of fine paper on a dark desk.

### Ambient Shadows
When a component must float (e.g., a modal or a floating action button), use a tinted shadow to mimic the glow of the Electric Mint ink:
*   **Value:** `0 20px 40px rgba(63, 255, 139, 0.04)`
*   This subtle mint-tinted shadow suggests the primary color is a light source, creating an ethereal glow.

### The "Ghost Border" Fallback
If accessibility requires a container boundary, use a **Ghost Border**:
*   `outline-variant` token at 10% opacity. Never use 100% opaque borders.

---

## 5. Components

### Buttons & CTAs
*   **Primary Button:** Pill-shaped (`rounded.full`). Background: Gradient from `#3fff8b` to `#00E676`. Text: `on-primary`.
*   **Circular CTA:** 64px x 64px circle. Use the primary gradient with a centered custom arrow. These should be placed at the intersections of the split-canvas layout.

### Input Fields
*   **Style:** No borders. Background: `surface-container-lowest` (`#1c1f1c`). 
*   **Shape:** `rounded.md` (1.5rem). 
*   **Interaction:** On focus, the background shifts slightly lighter or a subtle `0.5px` ghost border in primary-container appears.

### Progress Indicators
*   **Track:** `surface-container-high` (`#1f201e`).
*   **Indicator:** Pill-shaped primary color. The indicator should glow, using the ambient shadow value for a "neon" effect.

### Cards & Lists
*   **No Dividers:** Separate list items with `spacing.4` or `spacing.6`. 
*   **Card Styling:** Use `surface-container-low` with `rounded.lg` corners. Ensure all images within cards use a subtle `0.5px` inner glow rather than an outer stroke.

---

## 6. Do's and Don'ts

### Do
*   **DO** use the Split-Canvas layout to separate navigation/meta-info from the primary content stream.
*   **DO** leverage 20px-40px of backdrop blur on all overlays to maintain the "Ethereal" feel.
*   **DO** use tonal shifts (Level 0 to Level 2) to define interactive zones.

### Don't
*   **DON'T** use 1px solid white or grey lines to separate content; it breaks the organic flow.
*   **DON'T** use standard grey shadows. Always use the Primary-tinted shadow for elevation.
*   **DON'T** overcrowd the layout. If in doubt, add more vertical white space from the spacing scale.
*   **DON'T** use sharp corners. Every container should have at least `rounded.DEFAULT` (1rem) to maintain the organic signature.