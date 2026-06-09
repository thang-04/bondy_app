# Relationship UI and Avatar Tweaks Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the three relationship UI and avatar issues: (1) hide the back arrow on the home dashboard when embedded, (2) remove the "Mối quan hệ của tôi" menu item in the profile tab, and (3) fix the user's avatar display in the home dashboard header by loading the profile via ProfileService.

**Architecture:** 
- Add a configurable boolean parameter `showBackButton` (defaults to true) to `RelationshipHomeDashboard` to control back button rendering in the header.
- Pass `showBackButton: false` when instantiating `RelationshipHomeDashboard` inside the `MainShellScreen` IndexedStack.
- Remove the `'Mối quan hệ của tôi'` menu item and its adjacent `Divider` from the profile tab in `MainShellScreen`.
- Modify `RelationshipHomeDashboard`'s profile loading to fetch the profile from `ProfileService().getProfile()` and fallback to `AuthService().getCurrentUser()` on failure, using `rewriteMediaUrl` to ensure correct domain/port rewriting.

**Tech Stack:** Flutter, Provider, Media URL rewriting, Dio/Http API calls.

---

## Chunk 1: Configure Back Button and Remove Profile Tab Menu Item

### Task 1: Add showBackButton parameter and toggle rendering in RelationshipHomeDashboard

**Files:**
- Modify: `lib/screens/relationship/relationship_home_dashboard.dart:11-20`, `lib/screens/relationship/relationship_home_dashboard.dart:230-244`

- [ ] **Step 1: Modify RelationshipHomeDashboard constructor to add showBackButton**
  Update the constructor to include `final bool showBackButton;` (defaults to true).

- [ ] **Step 2: Update build method in RelationshipHomeDashboard to respect showBackButton**
  Change the back button condition in the header to:
  `if (widget.showBackButton && Navigator.of(context).canPop()) ...[`

### Task 2: Configure MainShellScreen to hide back button and remove menu item in profile

**Files:**
- Modify: `lib/screens/home/main_shell_screen.dart:90-95`, `lib/screens/home/main_shell_screen.dart:980-1002`

- [ ] **Step 1: Pass showBackButton: false in MainShellScreen**
  Change `relationshipHome: RelationshipHomeDashboard(viewModel: context.read<RelationshipViewModel>(),)` to pass `showBackButton: false`.

- [ ] **Step 2: Remove the "Mối quan hệ của tôi" menu item and its Divider from _ProfileTab**
  Remove the `_ProfileTab._buildMenuItem` for `'Mối quan hệ của tôi'` and its subsequent `Divider`.

---

## Chunk 2: Load User Profile and Rewrite Avatar URL in Dashboard

### Task 3: Import ProfileService and rewriteMediaUrl in RelationshipHomeDashboard, then update _loadMyProfile

**Files:**
- Modify: `lib/screens/relationship/relationship_home_dashboard.dart:1-10`, `lib/screens/relationship/relationship_home_dashboard.dart:44-55`

- [ ] **Step 1: Add imports to relationship_home_dashboard.dart**
  Import `../../services/profile_service.dart` and `../../core/media_url.dart`.

- [ ] **Step 2: Update _loadMyProfile to use ProfileService**
  Modify `_loadMyProfile` to first attempt loading via `ProfileService().getProfile()`. If successful, set `_myDisplayName` to `profile.displayName` and `_myPhotoUrl` to `profile.image ?? (profile.photos.isNotEmpty ? profile.photos.first : null)`. Fallback to `AuthService().getCurrentUser()` on failure, wrapping the fallback photo URL in `rewriteMediaUrl`.

---

## Chunk 3: Verification

### Task 4: Run unit tests and verify the code compiles and tests pass

- [ ] **Step 1: Run flutter tests for home and relationship screens**
  Run command: `flutter test test/screens/relationship/relationship_home_dashboard_test.dart`
  Expected: PASS
  Run command: `flutter test test/screens/home/main_shell_profile_tab_test.dart`
  Expected: PASS
