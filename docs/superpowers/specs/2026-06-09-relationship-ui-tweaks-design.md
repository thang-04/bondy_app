# Design Spec: Relationship UI and Avatar Tweaks

**Date:** 2026-06-09
**Status:** Approved

## Goal

Resolve three minor UI and data retrieval issues after relationship confirmation:
1. Hide the back button on the home dashboard (when active relationship is confirmed).
2. Remove the duplicate/redundant "Mối quan hệ của tôi" menu item from the Profile tab.
3. Fix the user's avatar displaying as a placeholder instead of their actual profile photo in the home dashboard header.

## Proposed Changes

### 1. `lib/screens/relationship/relationship_home_dashboard.dart`
- Import `../../services/profile_service.dart` and `../../core/media_url.dart`.
- Add a constructor parameter `showBackButton` (defaults to `true`).
- Conditionally render the back icon button in the header only if `widget.showBackButton && Navigator.of(context).canPop()`.
- Update `_loadMyProfile` to fetch profile data using `ProfileService().getProfile()`, falling back to `AuthService().getCurrentUser()` on failure.
- Set `_myPhotoUrl` using `profile.image ?? (profile.photos.isNotEmpty ? profile.photos.first : null)`.

### 2. `lib/screens/home/main_shell_screen.dart`
- Pass `showBackButton: false` when instantiating `RelationshipHomeDashboard` in `MainShellScreen`.
- Remove the `'Mối quan hệ của tôi'` menu item and its corresponding `Divider` from the `_ProfileTab` layout.

## Verification Plan

### Manual Verification
1. Verify that the home dashboard no longer shows the back arrow button at the top-left after relationship is active.
2. Verify that the "Mối quan hệ của tôi" list tile is removed from the profile page.
3. Verify that the user's avatar photo displays correctly beside the partner's avatar photo.
