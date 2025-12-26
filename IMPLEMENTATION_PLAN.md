# SurgiTrack Implementation Plan

**Date:** December 26, 2025
**Objective:** iOS 26 Migration, Security Fixes, and Missing Features

---

## Executive Summary

Based on comprehensive code audit, SurgiTrack is **functionally complete** but requires:
1. **iOS 26 Migration** - Adopt Liquid Glass design, new SwiftUI APIs
2. **Critical Security Fixes** - Password hashing, Keychain migration
3. **Production Readiness** - Logging, error handling, testing
4. **Feature Completion** - Implement stub/placeholder code

---

## Phase 1: Critical Security Fixes (Priority: CRITICAL)

### 1.1 Implement Secure Password/PIN Hashing
**Files:** `Core/Services/AuthManager.swift`

```swift
// Replace fake hashing with CryptoKit
import CryptoKit

func hashPin(_ pin: String, salt: String = UUID().uuidString) -> String {
    let inputData = Data((pin + salt).utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
```

### 1.2 Keychain Integration for Credentials
**New File:** `Core/Services/KeychainManager.swift`

- Migrate credentials from UserDefaults to Keychain
- Store: PIN hash, auth tokens, saved credentials
- Implement proper accessibility levels (whenUnlockedThisDeviceOnly)

### 1.3 Remove Hardcoded API Keys
**Files:** `SurgiTrackApp.swift`, `Info.plist`

- Create `Configuration.swift` with environment-based keys
- Use `.xcconfig` files for dev/staging/prod
- Remove test key from source control

---

## Phase 2: iOS 26 Migration (Priority: HIGH)

### 2.1 Liquid Glass Design Adoption
**Automatic with Xcode 26 recompile, but optimize:**

| Component | Update Required |
|-----------|-----------------|
| ModernCard | Add `.glassEffect()` modifier |
| ModernButton | Apply glass material for secondary style |
| ModernTabBar | Automatic liquid tab bar |
| NavigationBar | Automatic liquid glass |
| Sidebar | Automatic on iPad |

### 2.2 New SwiftUI APIs to Adopt

```swift
// 1. @Animatable macro for custom animations
@Animatable
struct PulseAnimation: View { ... }

// 2. Chart3D for trends visualization
Chart3D(data) { ... }

// 3. Native WebView (if needed)
WebView(url: URL)

// 4. Scene bridging (if UIKit views exist)
// Already SwiftUI-native, minimal work needed
```

### 2.3 Swift 6.2 Concurrency Updates
- Add `@MainActor` to ViewModels
- Replace `DispatchQueue.main.async` with `Task { @MainActor in }`
- Audit for data races in async code

### 2.4 Deprecated API Replacements

| Deprecated | Replacement |
|------------|-------------|
| `UIApplication.shared.windows` | `@Environment(\.openWindow)` / scene-based |
| `UIAlertController` in SwiftUI | `.alert()` or `.confirmationDialog()` |
| Old `Alert()` struct | New `.alert()` modifier syntax |

---

## Phase 3: Logging Infrastructure (Priority: HIGH)

### 3.1 Create Logging Service
**New File:** `Core/Services/Logger.swift`

```swift
import OSLog

enum LogCategory: String {
    case auth, patient, reports, network, persistence
}

struct Logger {
    static func debug(_ message: String, category: LogCategory)
    static func info(_ message: String, category: LogCategory)
    static func warning(_ message: String, category: LogCategory)
    static func error(_ message: String, error: Error?, category: LogCategory)
}
```

### 3.2 Replace Print Statements
**73 locations identified** - Replace with appropriate log levels:
- Debug prints → `Logger.debug()`
- Error prints → `Logger.error()`
- Info prints → `Logger.info()`

---

## Phase 4: Error Handling Improvements (Priority: MEDIUM)

### 4.1 Create Error Types
**New File:** `Core/Models/AppError.swift`

```swift
enum AppError: LocalizedError {
    case persistenceError(underlying: Error)
    case authenticationFailed(reason: String)
    case networkError(underlying: Error)
    case validationError(field: String, message: String)

    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

### 4.2 User-Facing Error Handling
- Replace catch blocks that only print
- Show user-friendly alerts for recoverable errors
- Log detailed errors for debugging

---

## Phase 5: Feature Completion (Priority: MEDIUM)

### 5.1 Notification Settings Persistence
**Files:** `QuietHoursView.swift`, `NotificationScheduleView.swift`

- Actually save to UserDefaults/CoreData
- Implement UNUserNotificationCenter scheduling

### 5.2 Data Export Implementation
**File:** `ExportDataView.swift`

- Generate actual CSV/JSON exports
- Implement iOS share sheet integration

### 5.3 Cache Management
**File:** `DataUsageView.swift`, `SettingsView.swift`

- Implement actual cache clearing
- Calculate real storage usage

### 5.4 App Store Rating
**File:** `SettingsView.swift`

- Use `SKStoreReviewController` for in-app rating

---

## Phase 6: Testing Infrastructure (Priority: HIGH)

### 6.1 Unit Test Targets

| Area | Priority | Tests Needed |
|------|----------|--------------|
| AuthManager | Critical | Login, PIN, lockout, hashing |
| RiskCalculatorEngine | Critical | All 5 calculators with edge cases |
| PersistenceController | High | CRUD operations, migrations |
| LoginViewModel | High | State transitions, error handling |
| TrendsAnalysisManager | Medium | Statistical calculations |

### 6.2 UI Test Targets

| Flow | Priority |
|------|----------|
| Login → Main | Critical |
| Add Patient | High |
| Risk Calculation | High |
| Appointment Scheduling | Medium |

### 6.3 Test Infrastructure
- Create mock services for Clerk
- In-memory CoreData for tests
- Snapshot tests for UI components

---

## Phase 7: HIPAA Compliance (Priority: HIGH)

### 7.1 Audit Logging
**New File:** `Core/Services/AuditLogger.swift`

```swift
struct AuditEvent {
    let timestamp: Date
    let userId: String
    let action: AuditAction
    let resourceType: String
    let resourceId: String
    let details: [String: Any]?
}

enum AuditAction {
    case view, create, update, delete, export, print
}
```

### 7.2 Session Timeout
**File:** `AuthManager.swift`

- Implement idle timeout (configurable, default 15 min)
- Auto-logout on background timeout
- Re-authentication on resume

### 7.3 Data Encryption
- Enable `NSFileProtectionComplete` for CoreData
- Consider field-level encryption for PHI

---

## Phase 8: Performance Optimizations (Priority: LOW)

### 8.1 CoreData Optimizations
- Add fetch batch sizes
- Implement prefetching for lists
- Move images to file system

### 8.2 CoreData Migrations
- Create versioned data model
- Add migration mappings

---

## Implementation Order

### Sprint 1: Security (Immediate)
1. ✅ KeychainManager implementation
2. ✅ Secure password hashing
3. ✅ Configuration management (API keys)
4. ✅ Logger infrastructure

### Sprint 2: iOS 26 Preparation
1. ✅ Deprecated API replacements
2. ✅ Swift 6.2 concurrency updates
3. ✅ @MainActor annotations
4. ⏳ Liquid Glass preparation (requires Xcode 26)

### Sprint 3: Production Readiness
1. Error handling improvements
2. Stub feature completion
3. Audit logging

### Sprint 4: Testing
1. Unit test infrastructure
2. Critical path tests
3. UI tests

### Sprint 5: Polish
1. Performance optimizations
2. Documentation
3. CoreData migrations

---

## Files to Create

| File | Purpose |
|------|---------|
| `Core/Services/KeychainManager.swift` | Secure credential storage |
| `Core/Services/Logger.swift` | Unified logging |
| `Core/Services/AuditLogger.swift` | HIPAA compliance |
| `Core/Models/AppError.swift` | Error types |
| `Core/Configuration.swift` | Environment config |
| `SurgiTrackTests/AuthManagerTests.swift` | Auth tests |
| `SurgiTrackTests/RiskCalculatorTests.swift` | Calculator tests |

---

## Device Support (iOS 26)

**Minimum:** A13 Bionic (iPhone 11, SE 2nd gen)

**Dropped:** iPhone XS, XS Max, XR

---

## Timeline Estimate

| Phase | Effort |
|-------|--------|
| Security Fixes | 2-3 days |
| iOS 26 Prep | 1-2 days |
| Logging/Errors | 1-2 days |
| Feature Completion | 2-3 days |
| Testing | 3-5 days |
| HIPAA Compliance | 2-3 days |

**Total:** 11-18 days of development

---

## Sources

- [iOS 26 WWDC 2025 Guide](https://medium.com/@taoufiq.moutaouakil/ios-26-wwdc-2025-complete-developer-guide-to-new-features-performance-optimization-ai-5b0494b7543d)
- [SwiftUI in iOS 26](https://differ.blog/p/swift-ui-in-ios-26-what-s-new-from-wwdc-2025-819b42)
- [Apple Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [iOS 26 Developer Guide](https://www.index.dev/blog/ios-26-developer-guide)
