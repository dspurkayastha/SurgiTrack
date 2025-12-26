// StateViews.swift
// SurgiTrack
// Comprehensive loading, empty, and error state components
// Created on 26/12/2025

import SwiftUI

// MARK: - Loading State View

/// A professional loading indicator with customizable styles and messages
struct LoadingStateView: View {

    let style: LoadingStyle
    let size: LoadingSize
    var message: String?
    var showMessage: Bool = true

    @State private var isAnimating = false

    enum LoadingStyle {
        case spinner        // Circular spinner
        case dots          // Animated dots
        case pulse         // Pulsing circle
        case bars          // Medical heartbeat bars
    }

    enum LoadingSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 64
            }
        }

        var messageFontSize: Font {
            switch self {
            case .small: return MedicalTypography.bodySmall
            case .medium: return MedicalTypography.bodyMedium
            case .large: return MedicalTypography.bodyLarge
            }
        }
    }

    init(
        style: LoadingStyle = .spinner,
        size: LoadingSize = .medium,
        message: String? = nil,
        showMessage: Bool = true
    ) {
        self.style = style
        self.size = size
        self.message = message
        self.showMessage = showMessage
    }

    var body: some View {
        VStack(spacing: MedicalSpacing.lg) {
            loadingIndicator

            if showMessage, let message = message {
                Text(message)
                    .font(size.messageFontSize)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading" + (message != nil ? ": \(message!)" : ""))
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        switch style {
        case .spinner:
            SpinnerLoader(size: size)
        case .dots:
            DotsLoader(size: size)
        case .pulse:
            PulseLoader(size: size)
        case .bars:
            BarsLoader(size: size)
        }
    }

    // MARK: - Spinner Loader

    private struct SpinnerLoader: View {
        let size: LoadingSize
        @State private var rotation: Double = 0

        var body: some View {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            MedicalColors.Brand.primary,
                            MedicalColors.Brand.primaryLight.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(
                        lineWidth: size == .large ? 5 : (size == .medium ? 4 : 3),
                        lineCap: .round
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }

    // MARK: - Dots Loader

    private struct DotsLoader: View {
        let size: LoadingSize
        @State private var animationPhase = 0

        var body: some View {
            HStack(spacing: size.dimension / 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MedicalColors.Brand.primary)
                        .frame(width: size.dimension / 4, height: size.dimension / 4)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: false),
                            value: animationPhase
                        )
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }

    // MARK: - Pulse Loader

    private struct PulseLoader: View {
        let size: LoadingSize
        @State private var scale: CGFloat = 0.8

        var body: some View {
            Circle()
                .fill(MedicalColors.Brand.primary)
                .frame(width: size.dimension, height: size.dimension)
                .scaleEffect(scale)
                .opacity(2.0 - (scale * 1.5))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        scale = 1.3
                    }
                }
        }
    }

    // MARK: - Bars Loader (Medical Heartbeat Style)

    private struct BarsLoader: View {
        let size: LoadingSize
        @State private var animationPhase = 0

        var body: some View {
            HStack(alignment: .center, spacing: size.dimension / 8) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MedicalColors.Brand.primary)
                        .frame(
                            width: size.dimension / 8,
                            height: barHeight(for: index)
                        )
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: animationPhase
                        )
                }
            }
            .frame(height: size.dimension)
            .onAppear {
                animationPhase = 1
            }
        }

        private func barHeight(for index: Int) -> CGFloat {
            let heights: [CGFloat] = [0.3, 0.5, 0.8, 0.5, 0.3]
            let baseHeight = size.dimension * heights[index]
            return animationPhase == 1 ? baseHeight * 1.5 : baseHeight * 0.5
        }
    }
}

// MARK: - Empty State View

/// A professional empty state view with icons, text, and optional actions
struct EmptyStateView: View {

    let icon: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var iconColor: Color = MedicalColors.Brand.primary

    @State private var isAnimating = false

    init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        iconColor: Color = MedicalColors.Brand.primary,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        VStack(spacing: MedicalSpacing.xl) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(iconColor.opacity(0.6))
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)

            // Text Content
            VStack(spacing: MedicalSpacing.sm) {
                Text(title)
                    .font(MedicalTypography.headlineMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 10)

                if let message = message {
                    Text(message)
                        .font(MedicalTypography.bodyMedium)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 10)
                }
            }
            .padding(.horizontal, MedicalSpacing.xl)

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(MedicalTypography.labelLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, MedicalSpacing.xl)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(MedicalColors.Brand.primary)
                        .cornerRadius(MedicalCardStyle.radiusSmall)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 10)
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to \(actionTitle.lowercased())")
            }
        }
        .padding(MedicalSpacing.xxxl)
        .onAppear {
            withAnimation(MedicalAnimation.spring.delay(0.1)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message ?? "")")
    }

    // MARK: - Preset Empty States

    /// Preset for no patients found
    static func noPatients(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "person.2.slash",
            title: "No Patients",
            message: "Add your first patient to get started with SurgiTrack",
            actionTitle: action != nil ? "Add Patient" : nil,
            iconColor: MedicalColors.Brand.primary,
            action: action
        )
    }

    /// Preset for no search results
    static func noResults(searchTerm: String? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: searchTerm != nil
                ? "No results found for '\(searchTerm!)'. Try adjusting your search."
                : "Try adjusting your search or filter criteria",
            iconColor: MedicalColors.Neutral.textSecondary
        )
    }

    /// Preset for no appointments
    static func noAppointments(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "No Appointments",
            message: "Schedule your first appointment",
            actionTitle: action != nil ? "Schedule Appointment" : nil,
            iconColor: MedicalColors.Brand.secondary,
            action: action
        )
    }

    /// Preset for no surgeries
    static func noSurgeries(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "cross.case",
            title: "No Surgeries Scheduled",
            message: "Schedule a surgery to begin tracking",
            actionTitle: action != nil ? "Schedule Surgery" : nil,
            iconColor: MedicalColors.Surgery.scheduled,
            action: action
        )
    }

    /// Preset for no notifications
    static func noNotifications() -> EmptyStateView {
        EmptyStateView(
            icon: "bell.slash",
            title: "No Notifications",
            message: "You're all caught up!",
            iconColor: MedicalColors.Clinical.normal
        )
    }

    /// Preset for no data
    static func noData(message: String = "No data available at this time") -> EmptyStateView {
        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "No Data",
            message: message,
            iconColor: MedicalColors.Neutral.textSecondary
        )
    }
}

// MARK: - Error State View

/// A professional error view with retry functionality
struct ErrorStateView: View {

    let error: Error?
    let message: String
    var showContactSupport: Bool = true
    var onRetry: (() -> Void)?
    var onContactSupport: (() -> Void)?

    @State private var isAnimating = false

    init(
        error: Error? = nil,
        message: String = "Something went wrong",
        showContactSupport: Bool = true,
        onRetry: (() -> Void)? = nil,
        onContactSupport: (() -> Void)? = nil
    ) {
        self.error = error
        self.message = message
        self.showContactSupport = showContactSupport
        self.onRetry = onRetry
        self.onContactSupport = onContactSupport
    }

    var body: some View {
        VStack(spacing: MedicalSpacing.xl) {
            // Error Icon
            ZStack {
                Circle()
                    .fill(MedicalColors.RiskLevel.high.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(MedicalColors.RiskLevel.high)
            }
            .opacity(isAnimating ? 1 : 0)
            .scaleEffect(isAnimating ? 1 : 0.8)

            // Error Message
            VStack(spacing: MedicalSpacing.sm) {
                Text("Error Occurred")
                    .font(MedicalTypography.headlineMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(message)
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .multilineTextAlignment(.center)

                if let error = error {
                    Text(error.localizedDescription)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, MedicalSpacing.xs)
                }
            }
            .padding(.horizontal, MedicalSpacing.xl)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)

            // Action Buttons
            VStack(spacing: MedicalSpacing.md) {
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(MedicalTypography.labelLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(MedicalColors.Brand.primary)
                        .cornerRadius(MedicalCardStyle.radiusSmall)
                    }
                    .accessibilityLabel("Try again")
                    .accessibilityHint("Double tap to retry the failed operation")
                }

                if showContactSupport, let onContactSupport = onContactSupport {
                    Button(action: onContactSupport) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Contact Support")
                        }
                        .font(MedicalTypography.labelLarge)
                        .foregroundColor(MedicalColors.Brand.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                .stroke(MedicalColors.Brand.primary, lineWidth: 1.5)
                        )
                    }
                    .accessibilityLabel("Contact support")
                    .accessibilityHint("Double tap to get help from support team")
                }
            }
            .padding(.horizontal, MedicalSpacing.xl)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)
        }
        .padding(MedicalSpacing.xxxl)
        .onAppear {
            withAnimation(MedicalAnimation.spring.delay(0.1)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Skeleton Loader Components

/// Skeleton loading placeholder views for various content types
struct SkeletonLoader {

    // MARK: - Skeleton Text

    struct SkeletonText: View {
        var width: CGFloat? = nil
        var height: CGFloat = 16

        @State private var isAnimating = false

        var body: some View {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemGray5),
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ],
                        startPoint: isAnimating ? .leading : .trailing,
                        endPoint: isAnimating ? .trailing : .leading
                    )
                )
                .frame(width: width, height: height)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }

    // MARK: - Skeleton Row

    struct SkeletonRow: View {
        var showAvatar: Bool = true
        var showTrailing: Bool = true

        var body: some View {
            HStack(spacing: MedicalSpacing.md) {
                if showAvatar {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 48, height: 48)
                        .shimmer()
                }

                VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
                    SkeletonText(width: 180, height: 16)
                    SkeletonText(width: 120, height: 14)
                }

                Spacer()

                if showTrailing {
                    SkeletonText(width: 60, height: 24)
                }
            }
            .padding(MedicalSpacing.lg)
            .accessibilityLabel("Loading content")
        }
    }

    // MARK: - Skeleton Card

    struct SkeletonCard: View {
        var showHeader: Bool = true
        var lineCount: Int = 3

        var body: some View {
            VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                if showHeader {
                    HStack {
                        SkeletonText(width: 140, height: 20)
                        Spacer()
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 32, height: 32)
                            .shimmer()
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
                    ForEach(0..<lineCount, id: \.self) { index in
                        SkeletonText(
                            width: index == lineCount - 1 ? 100 : nil,
                            height: 14
                        )
                    }
                }
            }
            .padding(MedicalSpacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .subtleElevation()
            .accessibilityLabel("Loading card")
        }
    }

    // MARK: - Skeleton List

    struct SkeletonList: View {
        var rowCount: Int = 5
        var showAvatar: Bool = true

        var body: some View {
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { index in
                    SkeletonRow(showAvatar: showAvatar)
                    if index < rowCount - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .accessibilityLabel("Loading list with \(rowCount) items")
        }
    }
}

// MARK: - Shimmer Effect Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - View Modifiers for Easy Integration

extension View {

    /// Shows a loading overlay when isLoading is true
    func loadingOverlay(
        isLoading: Bool,
        style: LoadingStateView.LoadingStyle = .spinner,
        message: String? = nil
    ) -> some View {
        ZStack {
            self
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                LoadingStateView(style: style, size: .large, message: message)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(MedicalAnimation.spring, value: isLoading)
    }

    /// Shows an empty state when isEmpty is true
    func emptyState(
        isEmpty: Bool,
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        ZStack {
            if isEmpty {
                EmptyStateView(
                    icon: icon,
                    title: title,
                    message: message,
                    actionTitle: actionTitle,
                    action: action
                )
                .transition(.opacity.combined(with: .scale))
            } else {
                self
            }
        }
        .animation(MedicalAnimation.spring, value: isEmpty)
    }

    /// Shows an empty state using a preset
    func emptyState(isEmpty: Bool, preset: EmptyStateView) -> some View {
        ZStack {
            if isEmpty {
                preset
                    .transition(.opacity.combined(with: .scale))
            } else {
                self
            }
        }
        .animation(MedicalAnimation.spring, value: isEmpty)
    }

    /// Shows an error state when error is present
    func errorState(
        error: Error?,
        message: String = "Something went wrong",
        onRetry: (() -> Void)? = nil,
        onContactSupport: (() -> Void)? = nil
    ) -> some View {
        ZStack {
            if error != nil {
                ErrorStateView(
                    error: error,
                    message: message,
                    onRetry: onRetry,
                    onContactSupport: onContactSupport
                )
                .transition(.opacity.combined(with: .scale))
            } else {
                self
            }
        }
        .animation(MedicalAnimation.spring, value: error != nil)
    }
}

// MARK: - Previews

#Preview("Loading States") {
    ScrollView {
        VStack(spacing: MedicalSpacing.xxxl) {
            VStack(spacing: MedicalSpacing.lg) {
                Text("Spinner Styles")
                    .font(MedicalTypography.headlineMedium)

                HStack(spacing: MedicalSpacing.xl) {
                    LoadingStateView(style: .spinner, size: .small, showMessage: false)
                    LoadingStateView(style: .spinner, size: .medium, showMessage: false)
                    LoadingStateView(style: .spinner, size: .large, showMessage: false)
                }
            }

            Divider()

            VStack(spacing: MedicalSpacing.lg) {
                Text("Other Loading Styles")
                    .font(MedicalTypography.headlineMedium)

                LoadingStateView(style: .dots, size: .medium, message: "Loading patients...")
                LoadingStateView(style: .pulse, size: .medium, message: "Syncing data...")
                LoadingStateView(style: .bars, size: .medium, message: "Processing...")
            }

            Divider()

            VStack(spacing: MedicalSpacing.lg) {
                Text("Skeleton Loaders")
                    .font(MedicalTypography.headlineMedium)

                SkeletonLoader.SkeletonCard()
                    .padding(.horizontal)

                SkeletonLoader.SkeletonList(rowCount: 3)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, MedicalSpacing.xxl)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: MedicalSpacing.xxxl) {
            EmptyStateView.noPatients(action: {})
            Divider()
            EmptyStateView.noResults(searchTerm: "John Doe")
            Divider()
            EmptyStateView.noAppointments(action: {})
            Divider()
            EmptyStateView.noSurgeries()
            Divider()
            EmptyStateView.noNotifications()
        }
        .padding(.vertical, MedicalSpacing.xxl)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Error State") {
    ErrorStateView(
        message: "Failed to load patient data",
        onRetry: {},
        onContactSupport: {}
    )
    .background(Color(.systemGroupedBackground))
}

#Preview("View Modifiers") {
    VStack {
        // Example list
        List(0..<5, id: \.self) { index in
            Text("Patient \(index + 1)")
        }
        .emptyState(
            isEmpty: false,
            icon: "person.3",
            title: "No Patients",
            message: "Add your first patient to get started"
        )
    }
}
