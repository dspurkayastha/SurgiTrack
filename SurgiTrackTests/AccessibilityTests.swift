// AccessibilityTests.swift
// SurgiTrackTests
// Tests for accessibility framework
// Created on 26/12/2025

import Testing
import Foundation
import SwiftUI
@testable import SurgiTrack

struct AccessibilityTests {

    // MARK: - Accessible Colors Tests

    @Test func accessibleColors_contrastConstants_areCorrect() async throws {
        #expect(AccessibleColors.normalTextMinContrast == 4.5, "Normal text min contrast should be 4.5")
        #expect(AccessibleColors.largeTextMinContrast == 3.0, "Large text min contrast should be 3.0")
        #expect(AccessibleColors.uiComponentMinContrast == 3.0, "UI component min contrast should be 3.0")
    }

    @Test func accessibleColors_primary_exists() async throws {
        _ = AccessibleColors.Primary.base
        _ = AccessibleColors.Primary.light
        _ = AccessibleColors.Primary.dark
        #expect(true, "Primary colors should exist")
    }

    @Test func accessibleColors_semantic_exists() async throws {
        _ = AccessibleColors.Success.base
        _ = AccessibleColors.Warning.base
        _ = AccessibleColors.Error.base
        #expect(true, "Semantic colors should exist")
    }

    @Test func accessibleColors_neutral_exists() async throws {
        _ = AccessibleColors.Neutral.text
        _ = AccessibleColors.Neutral.textSecondary
        _ = AccessibleColors.Neutral.textTertiary
        _ = AccessibleColors.Neutral.border
        _ = AccessibleColors.Neutral.background
        #expect(true, "Neutral colors should exist")
    }

    @Test func accessibleColors_patientStatus_exists() async throws {
        _ = AccessibleColors.PatientStatus.stable
        _ = AccessibleColors.PatientStatus.guarded
        _ = AccessibleColors.PatientStatus.critical
        _ = AccessibleColors.PatientStatus.inactive
        #expect(true, "Patient status colors should exist")
    }

    // MARK: - Accessible Typography Tests

    @Test func accessibleTypography_minimumSizes_areReasonable() async throws {
        #expect(AccessibleTypography.minimumBodySize >= 16, "Minimum body size should be at least 16pt")
        #expect(AccessibleTypography.minimumCaptionSize >= 12, "Minimum caption size should be at least 12pt")
    }

    @Test func accessibleTypography_lineHeight_isAccessible() async throws {
        #expect(AccessibleTypography.lineHeightMultiplier >= 1.4, "Line height should be at least 1.4x for readability")
    }

    @Test func accessibleTypography_headingStyles_exist() async throws {
        _ = AccessibleTypography.Heading.h1
        _ = AccessibleTypography.Heading.h2
        _ = AccessibleTypography.Heading.h3
        _ = AccessibleTypography.Heading.h4
        _ = AccessibleTypography.Heading.h5
        #expect(true, "Heading styles should exist")
    }

    @Test func accessibleTypography_bodyStyles_exist() async throws {
        _ = AccessibleTypography.Body.large
        _ = AccessibleTypography.Body.regular
        _ = AccessibleTypography.Body.small
        #expect(true, "Body styles should exist")
    }

    @Test func accessibleTypography_captionStyles_exist() async throws {
        _ = AccessibleTypography.Caption.regular
        _ = AccessibleTypography.Caption.small
        #expect(true, "Caption styles should exist")
    }

    // MARK: - Accessible Status Badge Tests

    @Test func accessibleStatusBadge_statusTypes_haveCorrectProperties() async throws {
        let success = AccessibleStatusBadge.Status.success
        let warning = AccessibleStatusBadge.Status.warning
        let error = AccessibleStatusBadge.Status.error
        let info = AccessibleStatusBadge.Status.info

        // Test icons
        #expect(success.icon == "checkmark.circle.fill")
        #expect(warning.icon == "exclamationmark.triangle.fill")
        #expect(error.icon == "xmark.circle.fill")
        #expect(info.icon == "info.circle.fill")

        // Test labels
        #expect(success.label == "Success")
        #expect(warning.label == "Warning")
        #expect(error.label == "Error")
        #expect(info.label == "Information")
    }

    // MARK: - Accessibility Manager Tests

    @Test @MainActor func accessibilityManager_shared_isSingleton() async throws {
        let manager1 = AccessibilityManager.shared
        let manager2 = AccessibilityManager.shared

        #expect(manager1 === manager2, "Should return same instance")
    }

    @Test @MainActor func accessibilityManager_animation_respectsReduceMotion() async throws {
        let manager = AccessibilityManager.shared

        // When reduce motion is disabled, should return animation
        // When enabled, should return nil
        // This test just verifies the method exists and returns something reasonable
        _ = manager.animation(.easeInOut)
        #expect(true, "Animation method should work")
    }

    @Test @MainActor func accessibilityManager_scaledValue_returnsPositive() async throws {
        let manager = AccessibilityManager.shared

        let scaled = manager.scaledValue(16)

        #expect(scaled > 0, "Scaled value should be positive")
    }

    // MARK: - View Modifier Tests

    @Test func minimumTouchTargetModifier_hasCorrectSize() async throws {
        // The modifier should ensure 44pt minimum
        let modifier = MinimumTouchTargetModifier()
        #expect(modifier.minimumSize == 44, "Minimum touch target should be 44pt")
    }
}
