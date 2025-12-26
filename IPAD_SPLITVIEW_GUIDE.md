# iPad Split View Implementation Guide

## Overview

SurgiTrack now supports iPad split view navigation using SwiftUI's `NavigationSplitView`. This provides a professional, native iPad experience with sidebar navigation, content lists, and detail views.

## Architecture

### Files Created

1. **NavigationSection.swift** (`/SurgiTrack/App/Views/`)
   - Defines navigation sections (Dashboard, Patients, Appointments, Reports, Settings)
   - Defines quick actions (New Patient, Schedule, Risk Calculator, Operative Note)

2. **iPadSidebarView.swift** (`/SurgiTrack/App/Views/`)
   - Sidebar with user profile header
   - Main navigation sections
   - Quick action buttons
   - Settings access

3. **AdaptiveNavigationView.swift** (`/SurgiTrack/App/Views/`)
   - Main adaptive container
   - Uses `NavigationSplitView` on iPad
   - Falls back to `MainPageView` on iPhone
   - Manages three-column layout

4. **NavigationStateManager.swift** (`/SurgiTrack/App/`)
   - ObservableObject for managing navigation state
   - Handles section selection
   - Manages detail view selections
   - Controls column visibility

5. **iPadLayoutExtensions.swift** (`/SurgiTrack/App/Views/`)
   - Helper extensions for iPad-specific styling
   - Device detection utilities
   - Column width preferences

### Files Modified

1. **ContentView.swift**
   - Updated to use `AdaptiveNavigationView` instead of `MainPageView` when authenticated
   - Maintains backward compatibility with iPhone navigation

## Three-Column Layout

### Sidebar (Column 1)
- **Width**: 280-400pt (ideal: 320pt)
- **Content**:
  - User profile header with avatar
  - Main navigation sections
  - Quick action buttons
  - Settings access

### Content (Column 2)
- **Width**: 350-500pt (ideal: 400pt)
- **Purpose**: Display lists and overviews
- **Examples**:
  - Patient list
  - Appointment list
  - Reports list
  - Dashboard overview

### Detail (Column 3)
- **Width**: 500-700pt (ideal: 700pt)
- **Purpose**: Display detailed information
- **Examples**:
  - Patient details
  - Appointment details
  - Report content
  - Settings panels

## Navigation Sections

### Dashboard
- Overview statistics
- Quick access to common features
- Trends and analytics

### Patients
- Patient list in content area
- Patient details in detail area
- Quick add patient action

### Appointments
- Appointment list in content area
- Appointment details in detail area
- Quick schedule action

### Reports
- Report categories in content area
- Report details in detail area
- Generate new reports

### Settings
- Settings categories in content area
- Settings panels in detail area
- User preferences

## Quick Actions

Quick actions are available in the sidebar for rapid access:

1. **New Patient** - Opens add patient sheet
2. **Schedule Appointment** - Opens appointment list
3. **Risk Calculator** - Opens risk calculator tools
4. **Operative Note** - Opens operative notes

## Column Visibility

The split view supports three visibility modes:

1. **All** - Shows all three columns (default)
2. **DoubleColumn** - Shows two columns
3. **DetailOnly** - Shows only detail column

Users can toggle between modes using:
- Sidebar toggle button
- Swipe gestures
- System controls

## Usage Examples

### Basic Setup

```swift
import SwiftUI

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .environmentObject(AppState())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

### Accessing Navigation State

```swift
struct MyView: View {
    @EnvironmentObject var navigationState: NavigationStateManager

    var body: some View {
        Button("Go to Patients") {
            navigationState.navigateTo(.patients)
        }
    }
}
```

### Selecting Detail Items

```swift
// Select a patient for detail view
navigationState.selectPatient(patient.objectID)

// Select an appointment
navigationState.selectAppointment(appointment.objectID)

// Select a report
navigationState.selectReport(report.objectID)
```

### Custom iPad Styling

```swift
import SwiftUI

struct MyCustomView: View {
    var body: some View {
        Text("Hello")
            .iPadStyle { view in
                view.font(.largeTitle)
                    .padding(40)
            }
    }
}
```

## Best Practices

### 1. Column Width Guidelines
- **Sidebar**: Keep navigation concise, use icons with labels
- **Content**: Show list items with enough detail for selection
- **Detail**: Provide comprehensive information and actions

### 2. Responsive Design
- Test on different iPad sizes (9.7", 11", 12.9")
- Support both portrait and landscape orientations
- Handle multitasking split screen scenarios

### 3. Navigation Flow
- Always show appropriate placeholder when nothing is selected
- Provide clear visual feedback for selected items
- Support keyboard navigation for accessibility

### 4. State Management
- Use `NavigationStateManager` for centralized state
- Clear selections when changing sections
- Persist column visibility preferences if needed

## Accessibility

The implementation includes:

- VoiceOver labels for all navigation elements
- Keyboard navigation support
- Dynamic Type support
- High contrast mode compatibility

## Performance Considerations

1. **Lazy Loading**: Lists use `LazyVGrid` and `LazyVStack`
2. **State Management**: Centralized in `NavigationStateManager`
3. **View Lifecycle**: Proper use of `@StateObject` and `@EnvironmentObject`

## Testing

### iPad Simulators
- iPad Pro 12.9-inch (6th generation)
- iPad Pro 11-inch (4th generation)
- iPad Air (5th generation)
- iPad mini (6th generation)

### Test Scenarios
1. Section navigation
2. Detail selection
3. Quick actions
4. Column visibility toggling
5. Rotation (portrait ↔ landscape)
6. Multitasking/split screen
7. Dark mode support

## Future Enhancements

Potential improvements:

1. **Drag and Drop**: Between columns
2. **Multi-Selection**: In content lists
3. **Custom Toolbar**: Per-section toolbars
4. **Persistence**: Save navigation state
5. **Advanced Filtering**: Column-specific filters
6. **Keyboard Shortcuts**: iPad keyboard support

## Troubleshooting

### Issue: Sidebar not showing
**Solution**: Check `columnVisibility` state, ensure it's not set to `.detailOnly`

### Issue: Detail view blank
**Solution**: Verify navigation state has proper selection, check placeholder views

### Issue: Column widths not responsive
**Solution**: Review `navigationSplitViewColumnWidth` modifiers, check constraints

## Related Documentation

- [SwiftUI NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [Human Interface Guidelines - iPad](https://developer.apple.com/design/human-interface-guidelines/ipad)
- [Multitasking on iPad](https://developer.apple.com/design/human-interface-guidelines/multitasking)

## Support

For issues or questions:
1. Check this documentation
2. Review example implementations
3. Test on physical iPad device
4. Consult Apple's HIG for iPad

---

**Last Updated**: December 26, 2025
**Version**: 1.0
**Minimum iOS**: iOS 16.0+
