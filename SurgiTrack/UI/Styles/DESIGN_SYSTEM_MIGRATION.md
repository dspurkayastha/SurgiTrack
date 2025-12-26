# Design System Migration Guide

## Overview

The SurgiTrack design system has been consolidated into a single, authoritative source: `DesignSystem.swift`. This consolidation provides:

- **Single Source of Truth**: All design tokens in one place
- **WCAG AA Compliance**: All colors meet accessibility standards
- **Medical-Specific Colors**: Specialized palettes for healthcare contexts
- **Better Documentation**: Clear usage guidelines for each token
- **Backward Compatibility**: Existing code continues to work
- **Dark Mode Support**: Proper adaptive colors

## Architecture

### Before (Multiple Files)
```
Theme.swift             → Basic theme colors
MedicalDesignSystem.swift → Medical-specific colors
ThemeBridge.swift       → Environment bridging
```

### After (Consolidated)
```
DesignSystem.swift      → Single source of truth (NEW)
Theme.swift            → Legacy compatibility wrapper (DEPRECATED)
MedicalDesignSystem.swift → Deprecated (kept for reference)
ThemeBridge.swift      → Updated to use DesignSystem
```

## Quick Migration Reference

### Colors

| Old (Deprecated) | New (Recommended) | Notes |
|-----------------|-------------------|-------|
| `Theme.colors.primary` | `DesignSystem.Colors.primary` | Professional teal |
| `Theme.colors.secondary` | `DesignSystem.Colors.secondary` | Professional blue |
| `Theme.colors.success` | `DesignSystem.Colors.success` | WCAG AA compliant |
| `Theme.colors.warning` | `DesignSystem.Colors.warning` | WCAG AA compliant |
| `Theme.colors.error` | `DesignSystem.Colors.error` | WCAG AA compliant |
| `LegacyThemeColors.background` | `DesignSystem.Colors.Adaptive.background` | Auto light/dark |
| `MedicalColors.PatientStatus.*` | `DesignSystem.Colors.PatientStatus.*` | Consolidated |
| `MedicalColors.RiskLevel.*` | `DesignSystem.Colors.RiskLevel.*` | Consolidated |

### Typography

| Old (Deprecated) | New (Recommended) | Notes |
|-----------------|-------------------|-------|
| `ThemeTypography.h1` | `DesignSystem.Typography.displayMedium` | Renamed for clarity |
| `ThemeTypography.h2` | `DesignSystem.Typography.headlineLarge` | Renamed for clarity |
| `ThemeTypography.bodyLarge` | `DesignSystem.Typography.bodyLarge` | Same API |
| `MedicalTypography.displayLarge` | `DesignSystem.Typography.displayLarge` | Consolidated |
| `MedicalTypography.monoMedium` | `DesignSystem.Typography.monoMedium` | For medical IDs |

### Spacing

| Old (Deprecated) | New (Recommended) | Notes |
|-----------------|-------------------|-------|
| `ThemeSpacing.sm` | `DesignSystem.Spacing.sm` | Same API |
| `ThemeSpacing.md` | `DesignSystem.Spacing.md` | Same API |
| `ThemeSpacing.xl` | `DesignSystem.Spacing.xl` | Same API |
| `MedicalSpacing.md` | `DesignSystem.Spacing.md` | Consolidated |

### Shadows

| Old (Deprecated) | New (Recommended) | Notes |
|-----------------|-------------------|-------|
| `ThemeShadows.small` | `DesignSystem.Shadows.small` | Tuple format |
| `ThemeShadows.medium` | `DesignSystem.Shadows.medium` | Tuple format |
| `ThemeShadows.large` | `DesignSystem.Shadows.large` | Tuple format |

### Animation

| Old (Deprecated) | New (Recommended) | Notes |
|-----------------|-------------------|-------|
| `ThemeAnimation.spring` | `DesignSystem.Animation.spring` | Same API |
| `ThemeAnimation.easeOut` | `DesignSystem.Animation.easeOut` | Same API |
| `MedicalAnimation.fast` | `DesignSystem.Animation.fast` | Consolidated |

## Detailed Migration Examples

### Example 1: Basic Color Usage

**Before:**
```swift
Text("Patient Name")
    .foregroundColor(Theme.colors.primary)
    .background(Theme.colors.surface)
```

**After:**
```swift
Text("Patient Name")
    .foregroundColor(DesignSystem.Colors.primary)
    .background(DesignSystem.Colors.Adaptive.surface)
```

### Example 2: Medical Status Colors

**Before:**
```swift
Circle()
    .fill(MedicalColors.PatientStatus.inSurgery)
```

**After:**
```swift
Circle()
    .fill(DesignSystem.Colors.PatientStatus.inSurgery)
```

### Example 3: Risk Level Indicators

**Before:**
```swift
let riskColor = MedicalColors.RiskLevel.color(for: 75.0)
```

**After:**
```swift
let riskColor = DesignSystem.Colors.RiskLevel.color(for: 75.0)
```

### Example 4: Typography

**Before:**
```swift
Text("Vital Signs")
    .font(ThemeTypography.h2)

Text("120 bpm")
    .font(MedicalTypography.numericLarge)
```

**After:**
```swift
Text("Vital Signs")
    .font(DesignSystem.Typography.headlineLarge)

Text("120 bpm")
    .font(DesignSystem.Typography.numericLarge)
```

### Example 5: Spacing and Layout

**Before:**
```swift
VStack(spacing: ThemeSpacing.md) {
    // content
}
.padding(MedicalSpacing.xl)
```

**After:**
```swift
VStack(spacing: DesignSystem.Spacing.md) {
    // content
}
.padding(DesignSystem.Spacing.xl)
```

### Example 6: Shadows

**Before:**
```swift
.shadow(
    color: ThemeShadows.medium.color,
    radius: ThemeShadows.medium.radius,
    x: ThemeShadows.medium.x,
    y: ThemeShadows.medium.y
)
```

**After:**
```swift
.shadow(
    color: DesignSystem.Shadows.medium.color,
    radius: DesignSystem.Shadows.medium.radius,
    x: DesignSystem.Shadows.medium.x,
    y: DesignSystem.Shadows.medium.y
)
```

## New Features in DesignSystem

### 1. Adaptive Colors

```swift
// Automatically adapts to light/dark mode
DesignSystem.Colors.Adaptive.background
DesignSystem.Colors.Adaptive.textPrimary
DesignSystem.Colors.Adaptive.border
```

### 2. Corner Radius System

```swift
// New standardized corner radii
.cornerRadius(DesignSystem.CornerRadius.sm)  // 8pt - buttons
.cornerRadius(DesignSystem.CornerRadius.md)  // 12pt - cards
.cornerRadius(DesignSystem.CornerRadius.lg)  // 16pt - prominent cards
```

### 3. Icon Sizes

```swift
// Standardized icon sizing
Image(systemName: "heart.fill")
    .font(.system(size: DesignSystem.IconSize.md))  // 20pt
```

### 4. Enhanced Medical Colors

```swift
// All medical-specific colors now in one place
DesignSystem.Colors.PatientStatus.*
DesignSystem.Colors.RiskLevel.*
DesignSystem.Colors.Clinical.*
DesignSystem.Colors.Surgery.*
```

### 5. Brand Colors

```swift
// Professional brand palette
DesignSystem.Colors.primary       // Teal-700 - calming, professional
DesignSystem.Colors.primaryLight  // Teal-500
DesignSystem.Colors.primaryDark   // Teal-600
```

## Color Accessibility

All colors in DesignSystem meet WCAG AA standards:

| Color | Contrast Ratio | Use Case |
|-------|---------------|----------|
| `primary` on white | 7.2:1 | AAA for text |
| `error` on white | 6.5:1 | AA for text |
| `success` on white | 5.8:1 | AA for text |
| `textPrimary` on white | 16.1:1 | AAA for text |
| `textSecondary` on white | 4.7:1 | AA for text |

## Medical Color Usage Guidelines

### Patient Status Colors

```swift
// Use these for patient status indicators
DesignSystem.Colors.PatientStatus.active          // Currently receiving care
DesignSystem.Colors.PatientStatus.preOperative    // Scheduled for surgery
DesignSystem.Colors.PatientStatus.inSurgery       // In OR (high visibility)
DesignSystem.Colors.PatientStatus.postOperative   // In recovery
DesignSystem.Colors.PatientStatus.readyForDischarge
DesignSystem.Colors.PatientStatus.discharged
DesignSystem.Colors.PatientStatus.critical        // Urgent attention
```

### Risk Level Colors

```swift
// Dynamic risk coloring based on percentage
let patientRisk = 65.0  // 65% risk
let riskColor = DesignSystem.Colors.RiskLevel.color(for: patientRisk)

// Or use specific risk levels
DesignSystem.Colors.RiskLevel.minimal    // 0-10%
DesignSystem.Colors.RiskLevel.low        // 10-25%
DesignSystem.Colors.RiskLevel.moderate   // 25-50%
DesignSystem.Colors.RiskLevel.high       // 50-75%
DesignSystem.Colors.RiskLevel.veryHigh   // 75-90%
DesignSystem.Colors.RiskLevel.critical   // 90%+
```

### Clinical Indicators

```swift
// For lab results and clinical values
DesignSystem.Colors.Clinical.normal         // Within normal range
DesignSystem.Colors.Clinical.abnormal       // Out of range
DesignSystem.Colors.Clinical.criticalValue  // Significantly abnormal
DesignSystem.Colors.Clinical.pending        // Awaiting results
DesignSystem.Colors.Clinical.verified       // Confirmed/verified
```

## Migration Strategy

### Phase 1: New Code (Immediate)
- All new views and components use `DesignSystem.*` exclusively
- No new references to `Theme.*` or `MedicalColors.*`

### Phase 2: Update Existing Code (Gradual)
- Update files as you work on them
- Use Xcode's "Find and Replace" for bulk updates
- Run search for deprecated APIs: `Theme.colors`, `ThemeTypography`, etc.

### Phase 3: Complete Migration (Future)
- When all code is migrated, remove deprecated structs
- Keep only `DesignSystem.swift` as the source of truth

## Xcode Find/Replace Patterns

Use these regex patterns for bulk migration:

1. **Colors:**
   - Find: `Theme\.colors\.(\w+)`
   - Replace: `DesignSystem.Colors.$1`

2. **Typography:**
   - Find: `ThemeTypography\.(\w+)`
   - Replace: `DesignSystem.Typography.$1`

3. **Spacing:**
   - Find: `ThemeSpacing\.(\w+)`
   - Replace: `DesignSystem.Spacing.$1`

4. **Medical Colors:**
   - Find: `MedicalColors\.(\w+)\.(\w+)`
   - Replace: `DesignSystem.Colors.$1.$2`

## Testing After Migration

After migrating a file, verify:

1. **Compilation:** No build errors
2. **Visual Appearance:** Colors and spacing look correct
3. **Dark Mode:** Test in both light and dark modes
4. **Accessibility:** VoiceOver works correctly
5. **Performance:** No degradation in performance

## Benefits Summary

| Benefit | Description |
|---------|-------------|
| **Consistency** | Single source prevents conflicting definitions |
| **Accessibility** | All colors WCAG AA compliant |
| **Documentation** | Each token has clear usage guidelines |
| **Maintainability** | Easier to update design tokens |
| **Type Safety** | Compile-time checks prevent errors |
| **Dark Mode** | Proper adaptive color support |
| **Medical Focus** | Specialized healthcare color palettes |

## Support

For questions or issues with migration:
1. Review the inline documentation in `DesignSystem.swift`
2. Check the migration examples in `Theme.swift` preview
3. See the comprehensive migration guide (this document)

## References

- **Primary File:** `/SurgiTrack/UI/Styles/DesignSystem.swift`
- **Legacy File:** `/SurgiTrack/UI/Styles/Theme.swift` (deprecated)
- **Medical Reference:** `/SurgiTrack/UI/Styles/MedicalDesignSystem.swift` (deprecated)
