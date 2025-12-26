# iPad Split View - Visual Guide

## Layout Structure

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                                  Navigation Bar                                     │
│  [☰] SurgiTrack                                              [🔔] [⚙️]              │
├──────────────┬─────────────────────────┬──────────────────────────────────────────┤
│              │                         │                                          │
│   SIDEBAR    │        CONTENT          │              DETAIL                      │
│  (280-400pt) │      (350-500pt)        │            (500-700pt)                   │
│              │                         │                                          │
│ ┌──────────┐ │ ┌─────────────────────┐ │ ┌──────────────────────────────────────┐ │
│ │ Profile  │ │ │ Dashboard           │ │ │                                      │ │
│ │ ┌──────┐ │ │ │                     │ │ │     Dashboard Overview               │ │
│ │ │ 👤   │ │ │ │ Overview:           │ │ │                                      │ │
│ │ │      │ │ │ │                     │ │ │  ┌─────────┐  ┌─────────┐            │ │
│ │ └──────┘ │ │ │ • Dashboard Overview│ │ │  │Patients │  │Surgeries│            │ │
│ │ Dr. Name │ │ │ • Trends            │ │ │  │   124   │  │   45    │            │ │
│ └──────────┘ │ │                     │ │ │  └─────────┘  └─────────┘            │ │
│              │ │ Quick Access:       │ │ │                                      │ │
│ Navigation   │ │                     │ │ │  ┌─────────┐  ┌─────────┐            │ │
│ ────────────│ │ • All Patients      │ │ │  │ Today   │  │Follow-up│            │ │
│ 📊 Dashboard │ │ • All Appointments  │ │ │  │    8    │  │   12    │            │ │
│ 👥 Patients  │ │                     │ │ │  └─────────┘  └─────────┘            │ │
│ 📅 Appts     │ │                     │ │ │                                      │ │
│ 📄 Reports   │ │                     │ │ │                                      │ │
│ ⚙️  Settings │ │                     │ │ │                                      │ │
│              │ │                     │ │ │                                      │ │
│ Quick Actions│ │                     │ │ │                                      │ │
│ ────────────│ │                     │ │ │                                      │ │
│ + Patient    │ │                     │ │ │                                      │ │
│ 📅 Schedule  │ │                     │ │ │                                      │ │
│ 🧮 Risk Calc │ │                     │ │ │                                      │ │
│ 📝 Op Note   │ │                     │ │ │                                      │ │
│              │ │                     │ │ │                                      │ │
└──────────────┴─────────────────────────┴──────────────────────────────────────────┘
```

## Interaction Flow

### 1. Section Selection
```
User Taps "Patients" in Sidebar
         ↓
Content Column Updates → Shows Patient List
         ↓
Detail Column → Shows "Select a patient" placeholder
```

### 2. Item Selection
```
User Selects Patient from List
         ↓
Content Column → Highlights selected patient
         ↓
Detail Column → Shows Patient Details
```

### 3. Quick Action
```
User Taps "New Patient" Quick Action
         ↓
Sheet Presentation → Add Patient Form
         ↓
On Save → Updates Patient List
```

## Column Layouts

### Sidebar - Navigation & Quick Access
```
┌─────────────────────┐
│  ┌──────────────┐   │
│  │   👤 Photo   │   │
│  │              │   │
│  └──────────────┘   │
│  Dr. John Smith      │
│  View Profile →      │
└─────────────────────┘

Navigation
───────────────────────
📊  Dashboard
👥  Patients
📅  Appointments
📄  Reports
⚙️   Settings

Quick Actions
───────────────────────
+   New Patient
📅  Schedule
🧮  Risk Calculator
📝  Operative Note
```

### Content - Lists & Overviews
```
┌────────────────────────┐
│ Dashboard             │
│                       │
│ Overview              │
│ • Dashboard Overview  │
│ • Trends             │
│                       │
│ Quick Access          │
│ • All Patients        │
│ • All Appointments    │
│                       │
└────────────────────────┘

OR

┌────────────────────────┐
│ Patients         [+]   │
│                       │
│ [Search patients...]  │
│                       │
│ ┌──────────────────┐ │
│ │ 👤 John Doe      │ │
│ │ MRN: 12345       │ │
│ └──────────────────┘ │
│                       │
│ ┌──────────────────┐ │
│ │ 👤 Jane Smith    │ │
│ │ MRN: 12346       │ │
│ └──────────────────┘ │
│                       │
└────────────────────────┘
```

### Detail - Full Information
```
┌──────────────────────────────────┐
│ Patient Details            [Edit]│
│                                  │
│ Personal Information             │
│ ─────────────────────────────── │
│ Name:      John Doe              │
│ DOB:       Jan 1, 1980           │
│ MRN:       12345                 │
│ Phone:     555-0123              │
│                                  │
│ Medical History                  │
│ ─────────────────────────────── │
│ • Hypertension                   │
│ • Diabetes Type 2                │
│                                  │
│ Recent Appointments              │
│ ─────────────────────────────── │
│ • Surgery - Dec 15, 2025         │
│ • Follow-up - Dec 22, 2025       │
│                                  │
│ [View Full History] [Add Note]   │
└──────────────────────────────────┘
```

## Orientation Modes

### Portrait
```
┌──────────────┬─────────────────────────────┐
│   Sidebar    │     Content + Detail        │
│   (visible)  │   (stacked or combined)     │
│              │                             │
│              │                             │
└──────────────┴─────────────────────────────┘
```

### Landscape
```
┌─────────┬──────────────┬────────────────────┐
│ Sidebar │   Content    │      Detail        │
│         │              │                    │
│         │              │                    │
└─────────┴──────────────┴────────────────────┘
```

## Column Visibility States

### All Columns (Default)
```
[Sidebar] [Content] [Detail]
```

### Double Column
```
[Sidebar] [Content+Detail]
```

### Detail Only
```
[Detail with back button]
```

## User Flow Examples

### Example 1: View Patient
```
1. User opens app
   → Dashboard shown in all three columns

2. User taps "Patients" in sidebar
   → Content shows patient list
   → Detail shows placeholder

3. User selects patient "John Doe"
   → Content highlights selection
   → Detail shows patient information

4. User can edit, view history, add notes
   → Actions in detail column
```

### Example 2: Add New Patient
```
1. User taps "+ New Patient" quick action
   → Sheet modal appears

2. User fills in patient information
   → Form validation

3. User taps "Save"
   → Patient added to database
   → Sheet dismisses
   → Patient list updates
   → New patient auto-selected
```

### Example 3: Schedule Appointment
```
1. User taps "📅 Schedule" quick action
   → Appointment list sheet appears

2. User taps "Add Appointment"
   → Add appointment form

3. User selects patient, date, time
   → Form validation

4. User saves
   → Appointment created
   → Calendar updates
   → Notification sent
```

## Gesture Support

### Swipes
- **Swipe Right**: Show sidebar (when hidden)
- **Swipe Left**: Hide sidebar
- **Pull Down**: Refresh lists

### Taps
- **Single Tap**: Select item
- **Double Tap**: Open detail/edit
- **Long Press**: Context menu

### Keyboard Shortcuts (iPad)
- **⌘[**: Show/hide sidebar
- **⌘N**: New item
- **⌘F**: Find/search
- **⌘,**: Settings
- **Arrow Keys**: Navigate lists

## Accessibility

### VoiceOver
```
"Dashboard, selected, tab 1 of 5"
"Patients list, showing 50 of 124 patients"
"John Doe, patient, MRN 12345, tap to view details"
```

### Dynamic Type
- All text scales with system settings
- Minimum touch target: 44x44pt
- Proper contrast ratios

### Voice Control
- All buttons labeled
- List items numbered
- Commands: "Show patients", "Tap add patient"

## Color Schemes

### Light Mode
```
Sidebar:     Light gray (#F2F2F7)
Content:     White (#FFFFFF)
Detail:      Light gray (#F9F9F9)
Separators:  Light gray (#C6C6C8)
Text:        Black (#000000)
```

### Dark Mode
```
Sidebar:     Dark gray (#1C1C1E)
Content:     Darker gray (#2C2C2E)
Detail:      Dark gray (#1C1C1E)
Separators:  Dark gray (#38383A)
Text:        White (#FFFFFF)
```

## Performance Metrics

### Target Performance
- **Launch Time**: < 2 seconds
- **Section Switch**: < 100ms
- **Item Selection**: < 50ms
- **List Scroll**: 60fps
- **Memory Usage**: < 100MB (typical)

### Optimization Techniques
1. Lazy loading of lists
2. Image caching
3. Virtualized scrolling
4. Efficient state updates
5. Minimal re-renders

## Testing Scenarios

### Critical Paths
1. ✓ Launch app → View dashboard
2. ✓ Navigate to patients → Select patient
3. ✓ Add new patient → Save → View details
4. ✓ Schedule appointment → Save
5. ✓ Generate report → View → Share
6. ✓ Change settings → Apply
7. ✓ Rotate device → Layout adjusts
8. ✓ Split screen multitasking
9. ✓ Dark mode toggle
10. ✓ VoiceOver navigation

---

**Visual Guide Version**: 1.0
**Last Updated**: December 26, 2025
**For**: SurgiTrack iPad Implementation
