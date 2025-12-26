# iPad Split View - Quick Reference Card

## File Locations

```
SurgiTrack/
├── App/
│   ├── NavigationStateManager.swift          [State Management]
│   ├── iPadPreferences.swift                  [User Preferences]
│   └── Views/
│       ├── AdaptiveNavigationView.swift       [Main Container]
│       ├── iPadSidebarView.swift              [Sidebar UI]
│       ├── iPadLayoutExtensions.swift         [Utilities]
│       ├── NavigationSection.swift            [Navigation Model]
│       └── ContentView.swift                  [MODIFIED]
```

## Key Components

### AdaptiveNavigationView
Main entry point - automatically selects iPad or iPhone navigation.

```swift
AdaptiveNavigationView()
    .environmentObject(appState)
    .environment(\.managedObjectContext, context)
```

### NavigationSection (Enum)
```swift
.dashboard    // Dashboard overview
.patients     // Patient management
.appointments // Appointment scheduling
.reports      // Report generation
.settings     // App settings
```

### NavigationStateManager
```swift
@StateObject var navState = NavigationStateManager()

navState.navigateTo(.patients)
navState.selectPatient(objectID)
navState.columnVisibility = .all
```

## Column Widths

| Column  | Min  | Ideal | Max  |
|---------|------|-------|------|
| Sidebar | 280  | 320   | 400  |
| Content | 350  | 400   | 500  |
| Detail  | 500  | 700   | -    |

## Quick Actions

```swift
QuickAction.newPatient          // Add patient
QuickAction.scheduleAppointment // Schedule
QuickAction.riskCalculator      // Risk tools
QuickAction.operativeNote       // Op notes
```

## Column Visibility

```swift
.all           // Show all 3 columns
.doubleColumn  // Show 2 columns
.detailOnly    // Show detail only
```

## Common Patterns

### Navigate to Section
```swift
navigationState.navigateTo(.patients)
```

### Select Item for Detail
```swift
navigationState.selectPatient(patient.objectID)
```

### Toggle Sidebar
```swift
if navigationState.columnVisibility == .all {
    navigationState.columnVisibility = .detailOnly
} else {
    navigationState.columnVisibility = .all
}
```

### iPad-Specific Styling
```swift
MyView()
    .iPadStyle { view in
        view.padding(40)
    }
```

### Device Detection
```swift
if DeviceType.isPad {
    // iPad-specific code
}

if DeviceType.isLandscape {
    // Landscape-specific code
}
```

## Environment Objects

Required environment objects:
- `@EnvironmentObject var appState: AppState`
- `@EnvironmentObject var navigationState: NavigationStateManager`
- `@Environment(\.managedObjectContext) var viewContext`

## Preferences

```swift
let prefs = iPadPreferences.shared

prefs.preferredSidebarWidth     // 280-400
prefs.preferredContentWidth     // 350-500
prefs.autoHideSidebarInLandscape
prefs.useCompactSidebar
prefs.columnVisibility
```

## Testing Commands

```swift
// Preview iPad
#Preview("iPad") {
    AdaptiveNavigationView()
        .previewDevice("iPad Pro (12.9-inch)")
}

// Preview iPhone
#Preview("iPhone") {
    AdaptiveNavigationView()
        .previewDevice("iPhone 15 Pro")
}
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Sidebar not showing | Check `columnVisibility` state |
| Detail blank | Verify selection state |
| Layout wrong on iPhone | Ensure device check works |
| State not persisting | Check `@StateObject` usage |

## Accessibility

```swift
.accessibilityLabel("Dashboard section")
.accessibilityHint("Tap to navigate to dashboard")
.accessibilityAddTraits(.isButton)
```

## Performance Tips

1. Use `LazyVStack` and `LazyHStack`
2. Minimize state updates
3. Cache expensive computations
4. Use `@StateObject` for managers
5. Avoid nested `GeometryReader`

## Documentation

- **Full Guide**: `IPAD_SPLITVIEW_GUIDE.md`
- **Implementation**: `IPAD_IMPLEMENTATION_SUMMARY.md`
- **Visual Guide**: `IPAD_VISUAL_GUIDE.md`
- **This Card**: `QUICK_REFERENCE.md`

## Support

1. Check documentation
2. Review code comments
3. Test with preview providers
4. Consult Apple HIG

---

**Quick Reference v1.0** | iPad Split View Implementation
