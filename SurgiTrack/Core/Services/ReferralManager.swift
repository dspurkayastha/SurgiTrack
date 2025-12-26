// ReferralManager.swift
// SurgiTrack → MedTrack
// Inter-department referral management system
// Created on 26/12/2025

import Foundation
import SwiftUI
import Combine

// MARK: - Referral Model

/// Inter-department patient referral
struct Referral: Identifiable, Codable {
    let id: UUID
    let patientId: UUID
    let patientName: String
    let patientMRN: String

    let fromDepartmentId: UUID
    let fromDepartmentName: String
    let fromDepartmentType: DepartmentType

    let toDepartmentId: UUID
    let toDepartmentName: String
    let toDepartmentType: DepartmentType

    let referringProviderId: UUID
    let referringProviderName: String

    var acceptingProviderId: UUID?
    var acceptingProviderName: String?

    let reason: String
    let clinicalSummary: String
    let priority: ReferralPriority
    var status: ReferralStatus

    let requestedDate: Date?
    let createdAt: Date
    var reviewedAt: Date?
    var acceptedAt: Date?
    var completedAt: Date?

    var attachmentIds: [UUID]
    var notes: [ReferralNote]

    init(
        id: UUID = UUID(),
        patientId: UUID,
        patientName: String,
        patientMRN: String,
        fromDepartmentId: UUID,
        fromDepartmentName: String,
        fromDepartmentType: DepartmentType,
        toDepartmentId: UUID,
        toDepartmentName: String,
        toDepartmentType: DepartmentType,
        referringProviderId: UUID,
        referringProviderName: String,
        reason: String,
        clinicalSummary: String,
        priority: ReferralPriority = .routine,
        requestedDate: Date? = nil,
        attachmentIds: [UUID] = []
    ) {
        self.id = id
        self.patientId = patientId
        self.patientName = patientName
        self.patientMRN = patientMRN
        self.fromDepartmentId = fromDepartmentId
        self.fromDepartmentName = fromDepartmentName
        self.fromDepartmentType = fromDepartmentType
        self.toDepartmentId = toDepartmentId
        self.toDepartmentName = toDepartmentName
        self.toDepartmentType = toDepartmentType
        self.referringProviderId = referringProviderId
        self.referringProviderName = referringProviderName
        self.reason = reason
        self.clinicalSummary = clinicalSummary
        self.priority = priority
        self.status = .pending
        self.requestedDate = requestedDate
        self.createdAt = Date()
        self.attachmentIds = attachmentIds
        self.notes = []
    }

    var isOverdue: Bool {
        let hoursElapsed = Date().timeIntervalSince(createdAt) / 3600
        return status == .pending && hoursElapsed > Double(priority.responseTimeHours)
    }

    var timeUntilDue: TimeInterval {
        let dueDate = createdAt.addingTimeInterval(TimeInterval(priority.responseTimeHours * 3600))
        return dueDate.timeIntervalSince(Date())
    }
}

struct ReferralNote: Identifiable, Codable {
    let id: UUID
    let authorId: UUID
    let authorName: String
    let content: String
    let createdAt: Date
    let isSystemGenerated: Bool

    init(
        id: UUID = UUID(),
        authorId: UUID,
        authorName: String,
        content: String,
        isSystemGenerated: Bool = false
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = Date()
        self.isSystemGenerated = isSystemGenerated
    }
}

// MARK: - Referral Manager

@MainActor
class ReferralManager: ObservableObject {

    static let shared = ReferralManager()

    // MARK: - Published Properties

    @Published var incomingReferrals: [Referral] = []
    @Published var outgoingReferrals: [Referral] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var pendingIncomingCount: Int {
        incomingReferrals.filter { $0.status == .pending || $0.status == .reviewed }.count
    }

    var urgentReferrals: [Referral] {
        incomingReferrals.filter { $0.priority == .urgent || $0.priority == .emergent || $0.priority == .stat }
    }

    var overdueReferrals: [Referral] {
        incomingReferrals.filter { $0.isOverdue }
    }

    // MARK: - Initialization

    private init() {
        loadSampleReferrals()
    }

    // MARK: - Public Methods

    /// Create a new referral
    func createReferral(_ referral: Referral) async throws {
        Logger.info("Creating referral to \(referral.toDepartmentName)", category: .general)

        // In production, this would save to CoreData
        var newReferral = referral
        outgoingReferrals.insert(newReferral, at: 0)

        // Add system note
        let note = ReferralNote(
            authorId: referral.referringProviderId,
            authorName: "System",
            content: "Referral created by \(referral.referringProviderName)",
            isSystemGenerated: true
        )
        newReferral.notes.append(note)

        // Send notification to receiving department
        await sendNotification(for: newReferral, type: .newReferral)

        AuditLogger.shared.log(
            action: .create,
            resourceType: .referral,
            resourceId: referral.id.uuidString,
            details: ["to_department": referral.toDepartmentName, "priority": referral.priority.rawValue]
        )
    }

    /// Accept a referral
    func acceptReferral(_ referralId: UUID, acceptingProviderId: UUID, acceptingProviderName: String) async throws {
        guard let index = incomingReferrals.firstIndex(where: { $0.id == referralId }) else {
            throw ReferralError.notFound
        }

        incomingReferrals[index].status = .accepted
        incomingReferrals[index].acceptingProviderId = acceptingProviderId
        incomingReferrals[index].acceptingProviderName = acceptingProviderName
        incomingReferrals[index].acceptedAt = Date()

        let note = ReferralNote(
            authorId: acceptingProviderId,
            authorName: "System",
            content: "Referral accepted by \(acceptingProviderName)",
            isSystemGenerated: true
        )
        incomingReferrals[index].notes.append(note)

        await sendNotification(for: incomingReferrals[index], type: .accepted)

        Logger.info("Referral \(referralId) accepted", category: .general)
    }

    /// Decline a referral
    func declineReferral(_ referralId: UUID, reason: String, declinedBy: UUID, declinedByName: String) async throws {
        guard let index = incomingReferrals.firstIndex(where: { $0.id == referralId }) else {
            throw ReferralError.notFound
        }

        incomingReferrals[index].status = .declined
        incomingReferrals[index].reviewedAt = Date()

        let note = ReferralNote(
            authorId: declinedBy,
            authorName: declinedByName,
            content: "Referral declined: \(reason)",
            isSystemGenerated: false
        )
        incomingReferrals[index].notes.append(note)

        await sendNotification(for: incomingReferrals[index], type: .declined)

        Logger.info("Referral \(referralId) declined", category: .general)
    }

    /// Schedule an appointment for an accepted referral
    func scheduleReferral(_ referralId: UUID, scheduledDate: Date) async throws {
        guard let index = incomingReferrals.firstIndex(where: { $0.id == referralId }) else {
            throw ReferralError.notFound
        }

        guard incomingReferrals[index].status == .accepted else {
            throw ReferralError.invalidStatus
        }

        incomingReferrals[index].status = .scheduled

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let note = ReferralNote(
            authorId: incomingReferrals[index].acceptingProviderId ?? UUID(),
            authorName: "System",
            content: "Appointment scheduled for \(dateFormatter.string(from: scheduledDate))",
            isSystemGenerated: true
        )
        incomingReferrals[index].notes.append(note)

        await sendNotification(for: incomingReferrals[index], type: .scheduled)

        Logger.info("Referral \(referralId) scheduled", category: .general)
    }

    /// Complete a referral
    func completeReferral(_ referralId: UUID, summary: String, completedBy: UUID, completedByName: String) async throws {
        guard let index = incomingReferrals.firstIndex(where: { $0.id == referralId }) else {
            throw ReferralError.notFound
        }

        incomingReferrals[index].status = .completed
        incomingReferrals[index].completedAt = Date()

        let note = ReferralNote(
            authorId: completedBy,
            authorName: completedByName,
            content: "Consultation completed: \(summary)",
            isSystemGenerated: false
        )
        incomingReferrals[index].notes.append(note)

        await sendNotification(for: incomingReferrals[index], type: .completed)

        Logger.info("Referral \(referralId) completed", category: .general)
    }

    /// Add a note to a referral
    func addNote(to referralId: UUID, content: String, authorId: UUID, authorName: String) {
        if let index = incomingReferrals.firstIndex(where: { $0.id == referralId }) {
            let note = ReferralNote(authorId: authorId, authorName: authorName, content: content)
            incomingReferrals[index].notes.append(note)
        } else if let index = outgoingReferrals.firstIndex(where: { $0.id == referralId }) {
            let note = ReferralNote(authorId: authorId, authorName: authorName, content: content)
            outgoingReferrals[index].notes.append(note)
        }
    }

    // MARK: - Private Methods

    private func sendNotification(for referral: Referral, type: NotificationType) async {
        // In production, this would send push notifications
        Logger.info("Sending \(type.rawValue) notification for referral \(referral.id)", category: .general)
    }

    private func loadSampleReferrals() {
        // Sample incoming referrals
        incomingReferrals = [
            Referral(
                patientId: UUID(),
                patientName: "John Smith",
                patientMRN: "MRN-2024-00123",
                fromDepartmentId: UUID(),
                fromDepartmentName: "Emergency Department",
                fromDepartmentType: .emergencyMedicine,
                toDepartmentId: UUID(),
                toDepartmentName: "General Surgery",
                toDepartmentType: .generalSurgery,
                referringProviderId: UUID(),
                referringProviderName: "Dr. Sarah Johnson",
                reason: "Acute appendicitis",
                clinicalSummary: "45-year-old male with RLQ pain, elevated WBC, CT showing appendicitis. Surgical evaluation requested.",
                priority: .urgent
            ),
            Referral(
                patientId: UUID(),
                patientName: "Mary Williams",
                patientMRN: "MRN-2024-00456",
                fromDepartmentId: UUID(),
                fromDepartmentName: "Internal Medicine",
                fromDepartmentType: .internalMedicine,
                toDepartmentId: UUID(),
                toDepartmentName: "Cardiology",
                toDepartmentType: .cardiology,
                referringProviderId: UUID(),
                referringProviderName: "Dr. Michael Chen",
                reason: "Chest pain evaluation",
                clinicalSummary: "68-year-old female with exertional chest pain. ECG shows ST changes. Rule out ACS.",
                priority: .emergent
            )
        ]

        // Sample outgoing referrals
        outgoingReferrals = [
            Referral(
                patientId: UUID(),
                patientName: "Robert Brown",
                patientMRN: "MRN-2024-00789",
                fromDepartmentId: UUID(),
                fromDepartmentName: "General Surgery",
                fromDepartmentType: .generalSurgery,
                toDepartmentId: UUID(),
                toDepartmentName: "Physical Therapy",
                toDepartmentType: .physicalTherapy,
                referringProviderId: UUID(),
                referringProviderName: "Dr. James Wilson",
                reason: "Post-operative rehabilitation",
                clinicalSummary: "Post knee replacement, requires PT for mobility training.",
                priority: .routine
            )
        ]
    }

    enum NotificationType: String {
        case newReferral = "new_referral"
        case accepted = "referral_accepted"
        case declined = "referral_declined"
        case scheduled = "referral_scheduled"
        case completed = "referral_completed"
    }
}

// MARK: - Referral Errors

enum ReferralError: LocalizedError {
    case notFound
    case invalidStatus
    case permissionDenied
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Referral not found"
        case .invalidStatus:
            return "Cannot perform this action with current referral status"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .validationFailed(let message):
            return message
        }
    }
}

// MARK: - Referral Card View

struct ReferralCard: View {

    let referral: Referral
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    var onView: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.md) {
            // Header
            HStack {
                // Priority indicator
                Circle()
                    .fill(referral.priority.color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

                Text(referral.priority.rawValue)
                    .font(MedicalTypography.captionBold)
                    .foregroundColor(referral.priority.color)
                    .accessibilityLabel("Priority: \(referral.priority.rawValue)")

                Spacer()

                // Status badge
                Text(referral.status.rawValue)
                    .font(MedicalTypography.captionBold)
                    .foregroundColor(referral.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(referral.status.color.opacity(0.15))
                    .clipShape(Capsule())
                    .accessibilityLabel("Status: \(referral.status.rawValue)")

                if referral.isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(MedicalColors.Clinical.criticalValue)
                        .accessibilityLabel("Overdue")
                }
            }

            // Patient info
            HStack(spacing: MedicalSpacing.md) {
                ZStack {
                    Circle()
                        .fill(MedicalColors.Brand.primary.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(referral.patientName.prefix(2).uppercased())
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(MedicalColors.Brand.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(referral.patientName)
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    Text(referral.patientMRN)
                        .font(MedicalTypography.monoSmall)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                }

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Patient: \(referral.patientName), \(referral.patientMRN)")

            Divider()
                .accessibilityHidden(true)

            // Referral details
            VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
                HStack {
                    Image(systemName: referral.fromDepartmentType.icon)
                        .foregroundColor(referral.fromDepartmentType.color)
                        .accessibilityHidden(true)
                    Text(referral.fromDepartmentName)
                        .font(MedicalTypography.bodySmall)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                        .accessibilityHidden(true)

                    Image(systemName: referral.toDepartmentType.icon)
                        .foregroundColor(referral.toDepartmentType.color)
                        .accessibilityHidden(true)
                    Text(referral.toDepartmentName)
                        .font(MedicalTypography.bodySmall)
                }
                .foregroundColor(MedicalColors.Neutral.textSecondary)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("From \(referral.fromDepartmentName) to \(referral.toDepartmentName)")

                Text(referral.reason)
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)
                    .accessibilityLabel("Reason: \(referral.reason)")

                Text(referral.clinicalSummary)
                    .font(MedicalTypography.bodySmall)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .lineLimit(2)
                    .accessibilityLabel("Summary: \(referral.clinicalSummary)")
            }

            // Footer with actions
            HStack {
                Text("From: \(referral.referringProviderName)")
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textTertiary)

                Spacer()

                Text(timeAgo(from: referral.createdAt))
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Referred by \(referral.referringProviderName), \(timeAgo(from: referral.createdAt))")

            // Action buttons (for pending referrals)
            if referral.status == .pending && (onAccept != nil || onDecline != nil) {
                HStack(spacing: MedicalSpacing.md) {
                    if let onDecline = onDecline {
                        Button(action: onDecline) {
                            Text("Decline")
                                .font(MedicalTypography.labelMedium)
                                .foregroundColor(MedicalColors.Clinical.criticalValue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MedicalSpacing.sm)
                                .background(MedicalColors.Clinical.criticalValue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Decline referral")
                        .accessibilityHint("Double tap to decline this referral")
                    }

                    if let onAccept = onAccept {
                        Button(action: onAccept) {
                            Text("Accept")
                                .font(MedicalTypography.labelMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MedicalSpacing.sm)
                                .background(MedicalColors.Brand.primary)
                                .cornerRadius(8)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("Accept referral")
                        .accessibilityHint("Double tap to accept this referral")
                    }
                }
            }
        }
        .padding(MedicalSpacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
        .subtleElevation()
        .onTapGesture {
            onView?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Referral for \(referral.patientName)")
        .accessibilityHint(onView != nil ? "Double tap to view referral details" : "")
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Referral Card") {
    VStack(spacing: MedicalSpacing.lg) {
        ReferralCard(
            referral: Referral(
                patientId: UUID(),
                patientName: "John Smith",
                patientMRN: "MRN-2024-00123",
                fromDepartmentId: UUID(),
                fromDepartmentName: "Emergency Department",
                fromDepartmentType: .emergencyMedicine,
                toDepartmentId: UUID(),
                toDepartmentName: "General Surgery",
                toDepartmentType: .generalSurgery,
                referringProviderId: UUID(),
                referringProviderName: "Dr. Sarah Johnson",
                reason: "Acute appendicitis",
                clinicalSummary: "45-year-old male with RLQ pain, elevated WBC, CT showing appendicitis.",
                priority: .urgent
            ),
            onAccept: {},
            onDecline: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
