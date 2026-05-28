# Modern Bento Profile Screens Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Personal Profile Tab (`_ProfileTab` in `main_shell_screen.dart`) and the other user's Profile Detail Screen (`ProfileDetailScreen` in `profile_detail_screen.dart`) with a modern, premium Bento Grid aesthetic.

**Architecture:** Refactor existing UI layouts into structured grid and row structures mimicking Bento Boxes. Utilize Card, Row, Column, Expanded, and Custom shadow/border decoration properties in Flutter. Group settings menu items into semantic Bento cards and represent user metrics (stats) with colorful, highly visual pastel-themed widgets.

**Tech Stack:** Flutter, Dart, Google Fonts, Provider, AppTheme (BondyColors, BondyRadius)

---

## Chunk 1: Personal Profile Tab Redesign

### Task 1: Refactor Avatar & Profile Name Header Card
**Files:**
- Modify: `lib/screens/home/main_shell_screen.dart` (the `_buildProfileHeader` and `_buildAvatar` functions inside `_ProfileTabState`)

- [ ] **Step 1: Replace simple column avatar area with a Bento Grid Card**
  Change `_buildProfileHeader` to return a `Container` acting as a premium Bento Box with:
  - Background color: `Colors.white`
  - Rounded corners: `BorderRadius.circular(BondyRadius.lg)` (24dp)
  - Soft shadow:
    ```dart
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ]
    ```
  - Padding: `const EdgeInsets.all(24)`
  - Internal layout: A Row or a clean Column containing the Avatar, Display Name, Subtitles, and a top-right edit icon.

- [ ] **Step 2: Redesign the Avatar and Placeholder**
  Update `_buildAvatar` to display:
  - Size: 90dp diameter
  - Border: Double border style or a distinct border (`Border.all(color: BondyColors.primary, width: 2.5)`)
  - Placeholder: A `LinearGradient` from deep purple `Color(0xFF6366F1)` to warm pink `Color(0xFFEC4899)` behind the user's initial letters.

- [ ] **Step 3: Update Name, Subtitle and Edit Button**
  Arrange the Display Name with `GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold)` and wrap subtitles (email, bio) with appropriate font spacing. Add a circular, subtle edit button at the top-right corner of the card pointing to `_openEditProfile`.

- [ ] **Step 4: Verify the build**
  Run: `flutter analyze`
  Expected: No lint or build errors in `main_shell_screen.dart`.

- [ ] **Step 5: Commit changes**
  ```bash
  git add lib/screens/home/main_shell_screen.dart
  git commit -m "style: redesign avatar and header card in personal profile tab"
  ```

---

### Task 2: Redesign the User Stats Bento Box Row
**Files:**
- Modify: `lib/screens/home/main_shell_screen.dart` (the `_buildStat` function and its layout within `build`)

- [ ] **Step 1: Implement custom pastel colors and styles for stats**
  In the `_ProfileTab` static `_buildStat` function, accept new arguments: `IconData icon`, `Color bgColor`, `Color iconColor`, `Color textColor` to support distinct Bento styling per stat.
  Apply:
  - Streak Box: `bgColor = Color(0xFFFFF5F0)`, `icon = Icons.local_fire_department_rounded`, `iconColor = Color(0xFFF97316)`
  - Matches Box: `bgColor = Color(0xFFFFF0F5)`, `icon = Icons.favorite_rounded`, `iconColor = Color(0xFFEC4899)`
  - Weekly Box: `bgColor = Color(0xFFF5F3FF)`, `icon = Icons.check_circle_rounded`, `iconColor = Color(0xFF8B5CF6)`

- [ ] **Step 2: Restructure stats layout**
  Arrange stats in a Row using `Expanded` blocks with relative sizing (e.g. 40% for Streak, 30% for Matches, 30% for Weekly if possible, or equal proportions using customized paddings/flex values). Give each box a height of `90dp`, a soft corner radius of `16dp`, and a beautiful layout showcasing the large stat value, label, and icon.

- [ ] **Step 3: Verify alignment**
  Ensure statistics fit perfectly without horizontal overflowing on narrower viewports.
  Run: `flutter analyze`

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/screens/home/main_shell_screen.dart
  git commit -m "style: upgrade user stats section into colorful bento row"
  ```

---

### Task 3: Group Settings Menu Items into Bento Group Cards & Revamp Logout Button
**Files:**
- Modify: `lib/screens/home/main_shell_screen.dart` (the menu construction inside `build` and the `_logout` button layout)

- [ ] **Step 1: Redesign the static menu item builder**
  Modify `_buildMenuItem` in `_ProfileTab` to look like a modern table row:
  - Leading icon: Clean monochrome or slightly colored icon.
  - Text style: `GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600)`
  - Trailing chevron: Soft gray chevron icon.
  - Border: No individual outer border; instead rely on the group container's boundary.
  - Tap effect: InkWell for material splash inside the group card.

- [ ] **Step 2: Group list tiles into 3 Bento Containers**
  Wrap menu items into three distinct containers with:
  - Background color: `Colors.white`
  - Rounded corners: `BorderRadius.circular(BondyRadius.md)` (20dp)
  - Soft shadow and padding.
  - Group 1 (Personal & Premium): Interests, My Relationship, Premium (with a beautiful gold "PRO" badge).
  - Group 2 (Settings & Security): Change Password, Privacy, Notifications.
  - Group 3 (Support & About): Help, About Bondy.
  Separate internal items in each group container with a very thin `Divider(height: 1, thickness: 0.5, color: Color(0xFFF3F4F6))`.

- [ ] **Step 3: Redesign the Logout button**
  Replace the simple TextButton with a stylized OutlinedButton:
  - Border color: `Color(0xFFFEE2E2)` (red-100) or red-200.
  - Text/Icon color: `BondyColors.error`
  - Background color: `Color(0xFFFEF2F2)` (soft red-50)
  - Shape: Rounded rectangle with `BorderRadius.circular(16)`.
  - Display centered at the bottom of the scroll view.

- [ ] **Step 4: Run flutter analysis**
  Verify code syntax.
  Run: `flutter analyze`

- [ ] **Step 5: Commit changes**
  ```bash
  git add lib/screens/home/main_shell_screen.dart
  git commit -m "style: group menu options into bento containers and revamp logout button"
  ```

---

## Chunk 2: Other User's Profile Detail Screen Redesign

### Task 4: Upgrade Image Header and Location Chips
**Files:**
- Modify: `lib/screens/discover/profile_detail_screen.dart` (the `_buildHero` and header structure)

- [ ] **Step 1: Soften Image Corners**
  Update the main photo container in `_buildHero` to have a large bottom corner radius:
  - Bottom-left & Bottom-right: `Radius.circular(32)`
  - Ensure the image clips properly within this container.

- [ ] **Step 2: Implement Premium Glassmorphic Location Chip**
  Redesign the distance/location display:
  - Background: `Colors.white.withValues(alpha: 0.15)`
  - Border: `Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1)`
  - Backing filter: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8))`
  - Shape: Fully rounded caps (`BorderRadius.circular(20)`)
  - Padding: `const EdgeInsets.symmetric(horizontal: 14, vertical: 8)`

- [ ] **Step 3: Verify the build**
  Run: `flutter analyze`

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/screens/discover/profile_detail_screen.dart
  git commit -m "style: add glassmorphic chips and rounded bottom corner to hero profile photo"
  ```

---

### Task 5: Implement Bento Grid Layout for Match %, Dating Goal, Icebreaker, and Bio
**Files:**
- Modify: `lib/screens/discover/profile_detail_screen.dart` (the `build` method and helper layout functions)

- [ ] **Step 1: Build the Hàng 1 (Match % & Dating Goal) Bento Grid**
  Create a row containing two equal-width Bento Cards:
  - **Left Card (% Match):**
    - Background: `Color(0xFFFFF0F5)` (pink pastel)
    - Content: Large match percentage text, pink heart icon, and subtext indicating emotional alignment.
  - **Right Card (Dating Goal):**
    - Background: `Color(0xFFF5F3FF)` (purple pastel)
    - Content: Highlighted dating goal text matching the profile goal type, elegant overlapping heart icon, and concise sub-goal description.
  Both cards styled with `BorderRadius.circular(20)` and subtle padding.

- [ ] **Step 2: Redesign the Icebreaker Card**
  Refactor `_buildIcebreaker` to return a premium Bento card:
  - Background: `Color(0xFFFEF3C7)` (amber/orange pastel)
  - Layout: Clear typography using "GỢI Ý MỞ LỜI" badge, vibrant lightbulb icon, and the prompt answer formatted elegantly with italics.
  - Shape: `BorderRadius.circular(24)`

- [ ] **Step 3: Redesign the Bio & Compatibility Cards**
  Refactor the "Về tôi" (Bio) area into a clean white card Bento:
  - Background: `Colors.white`
  - Rounded corners: `BorderRadius.circular(24)`
  - Internal layout: Soft title with a writing icon, and bio text with spacious `height: 1.6` line-height.

- [ ] **Step 4: Check compilation**
  Run: `flutter analyze`

- [ ] **Step 5: Commit changes**
  ```bash
  git add lib/screens/discover/profile_detail_screen.dart
  git commit -m "style: organize profile details, dating goal and icebreaker into bento layouts"
  ```

---

### Task 6: Beautify Interests Tags and Photo Gallery Cards
**Files:**
- Modify: `lib/screens/discover/profile_detail_screen.dart` (the tag building functions and gallery thumbnails)

- [ ] **Step 1: Implement Multi-colored Pastel Interests Chips**
  Update the tag rendering code (`_buildTag`) to cycle through or randomly assign a list of sophisticated pastel colors:
  - Color choices: Blue pastel (`0xFFEFF6FF`), Pink pastel (`0xFFFFF0F5`), Green pastel (`0xFFECFDF5`), Orange pastel (`0xFFFFF7ED`).
  - Text color: Darker matching hue corresponding to each pastel background (e.g. `Color(0xFF1E40AF)` for blue, `Color(0xFF9D174D)` for pink).
  - Wrap inside a white Bento card with rounded corners (`24dp`).

- [ ] **Step 2: Upgrade Photo Gallery Bento Box**
  Place the horizontal thumbnail list within its own white Bento Container. Improve thumbnail decorations:
  - Border radius: `16dp` for each photo thumbnail.
  - Border highlights: Smooth animation highlights for the currently selected index.

- [ ] **Step 3: Run analysis and verification**
  Run: `flutter analyze`

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/screens/discover/profile_detail_screen.dart
  git commit -m "style: modernize interests chips and photo gallery container"
  ```

---

### Task 7: Improve Floating Action Button (FAB) Aesthetics
**Files:**
- Modify: `lib/screens/discover/profile_detail_screen.dart` (the FAB configuration in `build`)

- [ ] **Step 1: Restyle the FAB container**
  Enhance the FAB container shape and gradient:
  - Kích thước: `60dp` x `60dp`
  - Gradient: LinearGradient from soft rose/peach `Color(0xFFFD3A84)` to coral red `Color(0xFFFF6B6B)`
  - Shadow:
    ```dart
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFFD3A84).withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 6),
      )
    ]
    ```

- [ ] **Step 2: Add interactive haptics**
  Integrate `HapticFeedback.lightImpact()` inside the `onPressed` swipe action for instant tactile feedback when users express interest.

- [ ] **Step 3: Complete project-wide validation**
  Build and compile the workspace to ensure everything works flawlessly.
  Run: `flutter analyze`

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/screens/discover/profile_detail_screen.dart
  git commit -m "style: apply premium gradient and glow to profile detail floating heart button"
  ```
