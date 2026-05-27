# Welcome Onboard UI Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrating the first onboarding screen "Start Your Journey" UI using the Google Stitch designs, specifically updating the image asset to `stitch_journey_hero.jpg` and implementing the Healing Pulse breathing animation for the Shield badge.

**Architecture:** Update `lib/screens/auth/onboarding_screen.dart` Page 0 visual section to point to the newly downloaded hero asset, and implement `_HealingPulse` class at the bottom of the file to wrap the Shield Icon positioned at the top-right of the hero.

**Tech Stack:** Flutter, Dart 3.11+, Material Design 3

---

### Task 1: Code Migration of Onboarding Screen Page 0

**Files:**
- Modify: `lib/screens/auth/onboarding_screen.dart`

- [ ] **Step 1: Replace hero image asset**
  In the `_buildStartJourneyPage()` method, replace `'assets/images/healing_stitch/stitch_healing_19.jpg'` on line 156 with the newly downloaded `'assets/images/healing_stitch/stitch_journey_hero.jpg'`.

  ```dart
  // Before:
  child: Image.asset(
    'assets/images/healing_stitch/stitch_healing_19.jpg',
    fit: BoxFit.cover,
    ...
  )

  // After:
  child: Image.asset(
    'assets/images/healing_stitch/stitch_journey_hero.jpg',
    fit: BoxFit.cover,
    ...
  )
  ```

- [ ] **Step 2: Add `_HealingPulse` widget**
  At the bottom of `lib/screens/auth/onboarding_screen.dart`, implement a private `_HealingPulse` stateful widget to create a smooth breathing scaling effect from 1.0 to 1.05 over 2 seconds (using reverse animation).

  ```dart
  class _HealingPulse extends StatefulWidget {
    final Widget child;

    const _HealingPulse({super.key, required this.child});

    @override
    State<_HealingPulse> createState() => _HealingPulseState();
  }

  class _HealingPulseState extends State<_HealingPulse>
      with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<double> _scaleAnimation;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);

      _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      );
    }
  }
  ```

- [ ] **Step 3: Wrap Shield Icon with `_HealingPulse`**
  In `_buildStartJourneyPage()`, wrap the `_buildGlassCircle` widget (the Shield Icon positioned at the top-right) with the new `_HealingPulse` widget.

  ```dart
  // Before:
  Positioned(
    top: topPadding + 96,
    right: 24,
    child: _buildGlassCircle(
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFF994100),
    ),
  )

  // After:
  Positioned(
    top: topPadding + 96,
    right: 24,
    child: _HealingPulse(
      child: _buildGlassCircle(
        icon: Icons.shield_outlined,
        iconColor: const Color(0xFF994100),
      ),
    ),
  )
  ```

- [ ] **Step 4: Commit changes**

  ```bash
  git add lib/screens/auth/onboarding_screen.dart
  git commit -m "feat(auth): migrate first welcome onboard UI with stitch design and pulse effect"
  ```

---

### Task 2: Verification and Cleanup

**Files:**
- Test: Run flutter analyzer on workspace

- [ ] **Step 1: Run flutter analyze**
  Run: `flutter analyze`
  Expected: No errors or warnings in onboarding_screen.dart.

- [ ] **Step 2: Commit verification results**
  Save verification notes and complete the session.
