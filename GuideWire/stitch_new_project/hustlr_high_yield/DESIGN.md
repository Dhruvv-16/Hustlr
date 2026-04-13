# The Design System: High-End Editorial for Modern Gig-Finance

## 1. Overview & Creative North Star: "The Financial Architect"
This design system moves beyond the generic "SaaS dashboard" aesthetic. It is built on the **Creative North Star: The Financial Architect**. This concept treats the UI as a series of curated, high-end editorial blocks. We balance the raw utility required by gig workers with the prestige of a private wealth management firm. 

The system rejects rigid, crowded grids in favor of **Intentional Asymmetry** and **Tonal Depth**. We prioritize massive whitespace and "Hero Numbers"—treating earnings data with the same reverence a luxury magazine treats a pull-quote. The goal is to make the user feel like they are managing a high-scale business, not just "chasing gigs."

---

## 2. Colors & Surface Philosophy
The palette is rooted in stability and growth. We use sophisticated "Forest Green" accents to signal prosperity, balanced against a surgical, clean neutral scale.

### The "No-Line" Rule
To maintain a premium feel, **1px solid borders are strictly prohibited for sectioning.** Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` section should sit on a `surface` background to create a "recessed" or "elevated" effect without the visual clutter of a stroke.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of stacked material. 
- **Base Layer:** `surface` (#F8F9FA / #121212)
- **Primary Containers:** `surface-container-lowest` (#FFFFFF) for the most prominent data cards.
- **Supportive Elements:** `surface-container-high` for secondary metadata or input fields.

### The "Glass & Gradient" Rule
Reserved exclusively for "Elite" status or premium tier cards, use Glassmorphism to break the flat plane. Apply a `surface-variant` color at 40% opacity with a **32px Backdrop Blur**. 
- **Signature Texture:** Use a subtle mesh gradient transitioning from `primary` (#0D631B) to `primary-container` (#2E7D32) behind these glass elements to give the UI "soul" and professional depth.

---

## 3. Typography: Editorial Authority
We utilize a dual-font system to balance character with utility. **Manrope** provides a geometric, modern authority for headings, while **Inter** ensures surgical legibility for transactional data.

| Level | Token | Font | Size | Weight | Intent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Manrope | 3.5rem | 700 | Large monetary earnings/balances. |
| **Headline** | `headline-md` | Manrope | 1.75rem | 600 | Section headers (e.g., "Weekly Review"). |
| **Title** | `title-lg` | Inter | 1.375rem | 600 | Card titles and primary navigation. |
| **Body** | `body-md` | Inter | 0.875rem | 400 | General descriptions and labels. |
| **Label** | `label-sm` | Inter | 0.6875rem | 500 | Captions and micro-metadata. |

**Styling Note:** Always use `on-secondary-fixed` (#1A1A2E) for primary text in light mode to provide a deep, high-contrast "Ink" feel that is softer than pure black.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "standard." This system uses **Ambient Tonal Layering** to convey importance.

- **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` background. The slight shift in hex value creates a natural, soft lift.
- **Ambient Shadows:** For floating action buttons or high-priority modals, use a shadow with a **24px Blur** and **4% Opacity** using the `on-surface` color. It should feel like a soft glow of light, not a dark smudge.
- **The "Ghost Border" Fallback:** If a container requires a border for accessibility (common in Dark Mode), use the `outline-variant` token at **15% opacity**. Never use 100% opaque outlines.
- **Roundedness:** All main cards must use `xl` (16px) radius. Bottom sheets must use `24px` to feel like an organic extension of the hardware.

---

## 5. Components

### Buttons
- **Primary:** Filled with `primary` (#0D631B). Use a 16px (`lg`) radius. No shadow; use a subtle internal gradient from top to bottom.
- **Secondary:** Use `surface-container-highest` background with `on-surface` text. 
- **Tertiary:** Text-only using `primary` color, strictly for low-priority actions like "Cancel" or "View All."

### Cards & Lists
- **Rule:** **Forbid divider lines.** Separate list items using `spacing.4` (1.4rem) of whitespace. 
- **Segmented Visuals:** Use segmented progress bars for earnings goals. Each segment represents a milestone, using `primary-fixed` for unfilled states and `primary` for filled.

### Input Fields
- Avoid "box" inputs. Use a `surface-container-low` background with a subtle `outline-variant` Ghost Border. 
- Focus state: The border-radius remains 16px, and the border transitions to `primary` at 50% opacity.

### Elite Tier Glass Cards (Premium)
- Apply `glassmorphism` with a mesh gradient of `primary` and `tertiary`.
- Add a 0.5px "Light Leak" stroke on the top and left edges using `on-primary-container` at 30% opacity to simulate light hitting glass.

---

## 6. Do’s and Don’ts

### Do
- **Do** prioritize the "Hero Number." If a user earned $500, that number should be the largest thing on the screen.
- **Do** use `spacing.20` (7rem) for top-of-page margins to create an editorial, airy feel.
- **Do** use `tertiary` (#7A4B00) for "Pending" states to avoid the alarmism of red.

### Don't
- **Don't** use standard Material dividers or 1px lines. It breaks the premium "Financial Architect" vibe.
- **Don't** exceed 5 sections per screen. If the content is dense, use horizontal scrolling cards or secondary pages.
- **Don't** use pure black (#000000) for text or backgrounds. Always use the specified `surface` and `on-surface` tokens to maintain tonal depth.
- **Don't** apply glassmorphism to standard utility cards. It is a "reward" visual reserved for high-value data.