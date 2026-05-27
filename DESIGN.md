# Design System Document: The Emotional Interface

## 1. Overview & Creative North Star
The dating landscape is often transactional and cold. This design system is built to counter that fatigue. Our Creative North Star is **"The Digital Sanctuary."** 

We are moving away from the rigid, grid-locked "catalog" look of traditional dating apps toward an editorial, immersive experience that prioritizes empathy and healing. We achieve this through **Intentional Asymmetry**—where profile images might bleed off-edge or overlap with typography—and **Tonal Depth**, replacing harsh dividers with soft, glowing transitions. This isn't just an interface; it's a safe space for meaningful connection.

---

## 2. Colors & Surface Philosophy
Color in this system is not decorative; it is emotional. We use a palette that shifts from deep, safe purples to vibrant, romantic pinks.

### The Palette (Material Tokens)
*   **Primary (The Heartbeat):** `#b70047` (Primary) to `#ff728f` (Primary Container).
*   **Secondary (The Soul):** `#92348e` (Secondary) / `#660066` equivalent.
*   **Tertiary (The Spark):** `#994100` (Tertiary) / `#FD7000` equivalent.
*   **Neutral (The Canvas):** `#fbf5f7` (Surface) / `#302e30` (On-Surface).

### The "No-Line" Rule
**Strict Mandate:** Prohibit the use of 1px solid borders for sectioning. 
Structure must be defined by background shifts. For example, a user's bio section (using `surface-container-low`) should sit directly on the main page (`surface`) without a stroke. The transition of color is the boundary.

### Surface Hierarchy & Nesting
Treat the UI as a stack of physical, semi-translucent layers.
*   **Base:** `surface` (#fbf5f7)
*   **Secondary Content:** `surface-container-low` (#f5eff1)
*   **Interactive Cards:** `surface-container-lowest` (#ffffff)
*   **Floating Navigation:** Glassmorphic layer using `surface-bright` at 70% opacity with a 20px backdrop blur.

### Signature Textures
Avoid flat primary colors. Main CTAs and Hero headers must use the **Signature Gradient**: `#FF0066` to `#FF007F`. This provides a professional polish and "vibrancy" that flat hex codes cannot replicate.

---

## 3. Typography: The Editorial Voice
We pair the high-end character of **Plus Jakarta Sans** for displays with the functional clarity of **Inter**.

*   **Display (The Statement):** `display-md` (2.75rem, Plus Jakarta Sans). Use for onboarding "hooks" or high-impact emotional quotes.
*   **Headline (The Story):** `headline-sm` (1.5rem, Plus Jakarta Sans). For user names and section titles.
*   **Body (The Connection):** `body-lg` (1rem, Inter). For bios and messaging.
*   **Label (The Detail):** `label-md` (0.75rem, Inter). For timestamps and metadata.

**Note:** Use asymmetric tracking (letter-spacing: -0.02em) on headlines to create a tight, premium editorial feel.

---

## 4. Elevation & Depth
Depth is achieved through light and layering, never through heavy shadows.

*   **The Layering Principle:** Instead of shadows, stack `surface-container-highest` components on `surface-dim` backgrounds. This creates "Natural Lift."
*   **Ambient Shadows:** If a floating element (like a "Send Like" button) requires a shadow, use a large blur (32px+) at 6% opacity. Use a tinted shadow: `rgba(183, 0, 71, 0.08)`—a soft pink tint—rather than grey.
*   **The Ghost Border:** If accessibility requires a container edge, use `outline-variant` at 15% opacity. It should feel like a suggestion of an edge, not a cage.
*   **Glassmorphism:** All overlays (modals, bottom sheets) must use a 12px-20px backdrop blur to allow the warm brand gradients to bleed through from the layer below.

---

## 5. Components

### Buttons
*   **Primary:** Signature Gradient (#FF0066 to #FF007F), `round-md` (1.5rem/24px). High-gloss, no border.
*   **Secondary:** `surface-container-highest` background with `primary` text.
*   **Tertiary:** Ghost style—no background, `primary` text, medium weight.

### Profiles & Cards
*   **The Profile Card:** Forbid divider lines. Use `spacing-6` (2rem) of vertical whitespace to separate interests from the bio.
*   **The Floating Action:** Buttons like "Match" should utilize the Glassmorphism rule—semi-transparent white with a high blur, making them feel like they are floating on water.

### Input Fields
*   **Soft Inputs:** Use `surface-container-low` for the fill. On focus, transition the background to `surface-container-lowest` and add a subtle `primary` ghost border (20% opacity).

### Specialized Components for Bondy
*   **The Healing Pulse:** A soft, breathing animation (scaling 1.0 to 1.05) used on "Safety" or "Support" icons, utilizing the `tertiary_fixed` (orange) glow.
*   **Connection Chips:** Use `secondary_container` (#ffbdf4) with `on_secondary_container` (#7a1c78) text. Corners must be `round-full` (9999px) for a soft, friendly touch.

---

## 6. Do's and Don'ts

### Do:
*   **Do** use intentional white space. Let the user's photos and words breathe.
*   **Do** overlap typography onto images slightly (using negative margins) to create an editorial, high-end feel.
*   **Do** use the Spacing Scale strictly (e.g., `spacing-4` for internal card padding).

### Don't:
*   **Don't** use pure black (#000000) for text. Use `on_surface` (#302e30) for better readability and a softer feel.
*   **Don't** use 100% opaque shadows. They feel "dirty" and break the "Sanctuary" vibe.
*   **Don't** use hard corners. Everything must feel touchable and safe—stick to the `md` (24px) or `lg` (32px) corner scales.

---

## 7. Accessibility & Motion
*   **Readability:** Ensure `on_primary` text always sits on the darker end of the gradient.
*   **Motion:** Transitions should be "Liquid." Use an `ease-in-out` cubic-bezier (0.4, 0, 0.2, 1) for all page transitions to mimic a slow, romantic fade rather than a mechanical snap.