# Design System Specification: Premium Fintech Editorial

## 1. Overview & Creative North Star

### Creative North Star: "The Architectural Sanctuary"
This design system moves beyond the transactional nature of fintech into a space of "Architectural Sanctuary." It is designed to feel like a high-end physical lounge: quiet, spacious, and impeccably organized. We reject the "dashboard-in-a-box" aesthetic in favor of editorial layouts that prioritize data clarity through high-contrast typography scales and intentional asymmetry.

By leveraging wide margins, overlapping surfaces, and a rejection of traditional borders, the system creates a sense of "unlimited liquidity." It feels premium because it breathes. It feels trustworthy because it refuses to clutter the user’s cognitive space.

---

## 2. Colors

The color strategy is rooted in "Atmospheric Depth." We use a primary fintech green to signal growth and security, supported by a sophisticated palette of slates and surfaces.

### Primary Palette
- **Primary:** `#0d631b` (Core brand action)
- **Primary Container:** `#2e7d32` (Prominent backgrounds/CTAs)
- **Error:** `#ba1a1a` (Critical alerts)
- **Secondary:** `#585f6c` (Supporting info)

### The "No-Line" Rule
**Explicit Instruction:** Sectioning via 1px solid borders is strictly prohibited. 
Visual boundaries must be achieved through:
1.  **Background Shifts:** Transitioning from `surface` (`#fcf8ff`) to `surface-container-low` (`#f5f2ff`).
2.  **Shadow Depth:** Utilizing the custom 12px blur ambient shadows to lift a card from the canvas.
3.  **Negative Space:** Using a minimum of `spacing-8` (2.75rem) to separate distinct functional modules.

### Glass & Gradient Signature
To elevate CTAs from "standard" to "premium," main buttons and hero data visualizations should utilize a subtle linear gradient: `primary` (`#0d631b`) to `primary_container` (`#2e7d32`) at a 135-degree angle. Floating navigation or contextual overlays must use **Glassmorphism**: 80% opacity on the surface color with a `24px` backdrop-blur.

---

## 3. Typography

The typographic system is a dialogue between the utilitarian precision of **Inter** and the editorial character of **Manrope**.

| Role | Font Family | Size | Weight / Usage |
| :--- | :--- | :--- | :--- |
| **Display-LG** | Manrope | 3.5rem | Bold. Used for "Massive Numbers" in monetary balances. |
| **Headline-LG** | Manrope | 2.0rem | Semi-bold. Page titles and high-level summaries. |
| **Title-MD** | Inter | 1.125rem | Medium. Section headers within cards. |
| **Body-LG** | Inter | 1.0rem | Regular. Default reading text. |
| **Label-MD** | Inter | 0.75rem | Bold. Caps-lock for pill-shaped badges/metadata. |

**Editorial Intent:** Use `Display-LG` for numbers to create an "authoritative scale." Ensure tracking (letter-spacing) is set to `-0.02em` for all Manrope headlines to maintain a tight, professional look.

---

## 4. Elevation & Depth

We define hierarchy through **Tonal Layering** rather than structural lines.

- **The Layering Principle:** 
  - Level 0 (Base): `surface` (`#fcf8ff`)
  - Level 1 (Sections): `surface-container-low` (`#f5f2ff`)
  - Level 2 (Interactive Cards): `surface-container-lowest` (`#ffffff`) 
  - *Result:* Placing a white card on a low-tinted background creates a natural, soft lift without visual noise.

- **Ambient Shadows:** 
  For floating elements, use `rgba(26, 26, 46, 0.04)` (a tint of the `on-surface` color) with a `12px` blur and `4px` Y-offset. This mimics natural light falling on a matte surface.

- **The Ghost Border:**
  If containment is required for accessibility (e.g., in Dark Mode), use `outline-variant` (`#bfcaba`) at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components

### Cards & Containers
- **Border Radius:** Fixed `xl` (1.5rem / 24px) for main containers to match the "soft premium" vibe.
- **Layout:** Forbid divider lines. Use `spacing-4` (1.4rem) to separate list items within a card.

### Buttons
- **Primary:** `primary` background, `on-primary` text. Pill-shaped (`rounded-full`). 
- **Secondary:** `secondary_container` background with `on_secondary_container` text.
- **Interaction:** On hover, apply a `10%` white overlay (Light Theme) or `10%` black overlay (Dark Theme) to simulate a "physical" press.

### Pill-Shaped Badges (Chips)
- **Style:** Background at 12% opacity of the semantic color (e.g., `error` at 12% for alerts).
- **Text:** Full opacity semantic color, `label-md` typography.

### Input Fields
- **Container:** `surface-container-high` background. No border.
- **States:** On focus, the background shifts to `surface-container-highest` with a `2px` `primary` "Ghost Border" (20% opacity).

### Specialized: The "Momentum" List
In insurance contexts, use vertical lists where the "Leading Element" (Icon) sits in a `surface-variant` circular container, and the "Trailing Element" (Price/Amount) uses `title-lg` Manrope bold numbers.

---

## 6. Do’s and Don’ts

### Do
- **Do** use "Massive Bold Numbers" for all currency values to establish immediate financial hierarchy.
- **Do** maximize whitespace. If a layout feels "full," increase the spacing scale by one increment.
- **Do** use asymmetrical card widths (e.g., a 60/40 split) to break the "grid template" feel and create editorial interest.

### Don’t
- **Don't** use 1px solid dividers to separate content. Use a `0.5px` background color shift or whitespace.
- **Don't** use pure black `#000000` for shadows or text. Always use the `on-surface` (`#1a1a2e`) or its tinted variants to maintain "fintech calm."
- **Don't** use sci-fi, glowing, or neon elements. The "Hustlr" vibe is grounded, premium, and architectural.