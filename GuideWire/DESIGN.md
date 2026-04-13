# Design System Strategy: The Guardian Glow

## 1. Overview & Creative North Star
This design system is built to transform the often-sterile insurance industry into a high-end, lifestyle-centric experience for the modern gig worker. Our Creative North Star is **"The Guardian Glow."** 

Unlike traditional fintech apps that rely on rigid grids and clinical white space, this system embraces a "Digital Concierge" aesthetic. We break the "template" look through **Organic Fluidity**: utilizing extreme corner radii (`round-xl` to `round-full`) and deep, tonal layering. The interface should feel like a series of soft, protective glass shields floating over a void. By utilizing intentional asymmetry—such as staggered card layouts and oversized display typography—we create an editorial rhythm that feels premium, energetic, and protective.

---

## 2. Colors & Surface Philosophy
The palette is rooted in a "Deep Sea" dark mode, punctuated by high-vibrancy pastel "pops" that signify life and movement.

### Surface Hierarchy & Nesting
We do not build flat interfaces. We build environments.
- **The "No-Line" Rule:** 1px solid borders are strictly prohibited for sectioning. Separation is achieved through **Tonal Transition**. 
- **The Stacking Logic:** 
    1. Base layer: `background` (#0e0e0e).
    2. Sectioning: `surface_container_low` (#131313).
    3. Interactive Components: `surface_container` (#1a1a1a) or `surface_container_high` (#20201f).
- **The Glass & Gradient Rule:** For primary actions and high-level summaries, use **Glassmorphism**. Apply a semi-transparent `surface_variant` with a 20px-40px backdrop blur. 
- **Signature Gradients:** To add "soul," use subtle linear gradients for CTAs, transitioning from `primary` (#aaffdc) to `primary_container` (#00fdc1) at a 135-degree angle.

---

## 3. Typography: Editorial Authority
We use **Manrope** as our sole typeface to maintain a clean, modern, and high-end feel.

- **Display & Headlines:** Use `display-lg` (3.5rem) and `headline-lg` (2rem) with tight letter-spacing (-0.02em) to create a bold, "magazine cover" presence. These are for moments of impact—celebrating a milestone or stating a coverage amount.
- **Data & Title:** `title-lg` (1.375rem) should be used for policy names and financial figures. It must feel authoritative.
- **Body & Labels:** `body-md` (0.875rem) is our workhorse. Ensure a generous line-height (1.6) to prevent the "wall of text" feel common in legal/insurance apps.
- **Visual Hierarchy:** Use `on_surface_variant` (#adaaaa) for secondary metadata to ensure the primary data "glows" against the dark background.

---

## 4. Elevation & Depth: The Layered Principle
We move away from the standard material shadow toward **Ambient Depth**.

- **Tonal Layering:** Hierarchy is achieved by "stacking." A `surface_container_highest` (#262626) card sitting on a `surface_container_low` (#131313) background creates a natural, soft lift.
- **Ambient Shadows:** For floating elements (like Bottom Sheets or Modals), use an extra-diffused shadow: `box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5)`. The shadow should feel like a soft cloud, not a hard drop.
- **Neumorphic Tactility:** For static cards or secondary buttons, use a subtle neumorphic "debossed" effect using `surface_container_lowest` for the inner shadow and a faint `outline_variant` glow to give the impression that the UI is molded from a single piece of dark glass.
- **The Ghost Border:** If accessibility requires a stroke, use `outline_variant` at 15% opacity. Never use 100% opacity for borders.

---

## 5. Components

### Buttons & Interaction
- **Primary Action:** Pill-shaped (`round-full`). Background: `primary` (#aaffdc). Text: `on_primary_fixed` (#004734). These should have a subtle glow effect (box-shadow using the primary color at 20% opacity).
- **Secondary Action:** Glassmorphic. Background: `surface_variant` at 40% opacity with backdrop blur.
- **States:** On `hover` or `pressed`, shift the background to its `_dim` variant (e.g., `primary_dim`).

### Cards & Information Display
- **The Hustle Card:** Use `round-xl` (3rem) for main dashboard cards. 
- **Spacing:** Use `spacing-6` (2rem) for internal padding to ensure the content "breathes."
- **Dividers:** Forbidden. Separate list items using a `spacing-3` (1rem) vertical gap and a background shift to `surface_container_low`.

### Inputs & Forms
- **Wells:** Input fields should be styled as "wells"—slightly recessed into the surface using `surface_container_lowest`. 
- **Focus State:** Instead of a border, the entire background of the input should softly transition to a 10% opacity of the `primary` color.
- **Errors:** Use `error_dim` (#d7383b) for helper text and a subtle `error` (#ff716c) glow around the input container.

### Signature Component: The "Coverage Pulse"
A glassmorphic ring or chip using `tertiary` (#d5baff) and `secondary` (#ff99cc) that pulsates slowly. This is used for active insurance status, giving the user a visual "heartbeat" of protection.

---

## 6. Do’s and Don’ts

### Do
- **Do** use `round-full` for all action-oriented elements (chips, buttons, search bars).
- **Do** lean into asymmetry. Place a `display-lg` headline off-center to create visual interest.
- **Do** use the `primary_fixed_dim` (#00edb4) for active data states to ensure high legibility against the deep background.

### Don’t
- **Don’t** use pure black (#000000) for anything other than `surface_container_lowest`. 
- **Don’t** use high-contrast white text for body copy; use `on_surface_variant` (#adaaaa) to reduce eye strain.
- **Don’t** use sharp corners. If an element isn't at least `round-md` (1.5rem), it doesn't belong in this system.
- **Don’t** use traditional "Material" elevation shadows. Stick to tonal shifts and backdrop blurs.