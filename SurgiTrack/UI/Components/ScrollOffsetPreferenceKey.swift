//
//  ScrollOffsetPreferenceKey.swift
//  SurgiTrack
//  Created by Devraj Shome Purkayastha on 10/03/25.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
// Note: QuickAction enum is defined in NavigationSection.swift
// Note: Patient.initials is defined in Patient+Extensions.swift

struct DashboardStats {
    var patientCount: Int = 0
    var surgeryCount: Int = 0
    var todayAppointments: Int = 0
    var pendingFollowUps: Int = 0
}
