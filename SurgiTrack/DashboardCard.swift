//
//  DashboardCard.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// EnhancedPatientDetailComponents.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData


// MARK: - Dashboard Card

struct DashboardCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let gradient: [Color]  // multi-stop array
    let content: Content
    var showExpandButton: Bool = true
    var onExpand: (() -> Void)? = nil
    
    @State private var isHovering = false
    
    init(title: String,
         subtitle: String? = nil,
         iconName: String,
         gradient: [Color],
         showExpandButton: Bool = true,
         onExpand: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.gradient = gradient
        self.showExpandButton = showExpandButton
        self.onExpand = onExpand
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Card Header
            HStack(spacing: 12) {
                // Larger icon w/ subtle drop shadow
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                
                // Title & subtitle with soft glow
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)  // soft glow
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.85))
                            .shadow(color: .white.opacity(0.2), radius: 1, x: 0, y: 0)
                    }
                }
                
                Spacer()
                
                // Expand/collapse button
                if showExpandButton {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onExpand?()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .opacity(isHovering ? 1.0 : 0.8)
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                //  Use your multi-stop array from topLeading to bottomTrailing
                LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // overlay for extra highlight or reflection
            .overlay(
                ZStack {
                    // Subtle diagonal highlight from top-left
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0.3), location: 0.0),
                            .init(color: .clear, location: 0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .blendMode(.screen)
                    
                    // Another from bottom-right
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0.15), location: 0.0),
                            .init(color: .clear, location: 0.4)
                        ]),
                        startPoint: .bottomTrailing,
                        endPoint: .center
                    )
                    .blendMode(.overlay)
                }
                .allowsHitTesting(false)
            )
            
            // MARK: - Card Content
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}


// MARK: - Card Gradients

/// A set of multi-stop metallic-style gradients for each type of card.
/// You can tweak or swap these as you like.
struct CardGradients {
    // 1) Overview: Silver-to-steel
    //   Light silver -> mid steel-blue -> deeper gunmetal
    static let overview = [
        Color(hex: "E8ECF0"), // bright silver top-left
        Color(hex: "A8B2BC"), // moderate steel mid
        Color(hex: "39424C")  // darker gunmetal bottom-right
    ]
    
    // 2) Initial (Plum Metallic):
    //   Light lavender -> vibrant plum -> deep purple
    static let initial = [
        Color(hex: "5A2778"), // pale lavender top-left
        Color(hex: "AC77C2"), // bolder plum mid
        Color(hex: "F0E5F6")  // deep purple bottom-right
    ]
    
    // 3) Operative (Fiery Red):
    //   Light pinkish red -> bright salmon-red -> deep blood red
    static let operative = [
        Color(hex: "8D0A0A"), // pale pink top-left
        Color(hex: "FA6464"), // vibrant salmon mid
        Color(hex: "FFD1D1")  // dark crimson bottom-right
    ]
    
    // 4) Follow-up (Emerald Metallic):
    //   Pale mint -> teal -> deep emerald
    static let followup = [
        Color(hex: "CFF3ED"), // mint top-left
        Color(hex: "30BBA1"), // teal mid
        Color(hex: "006B5E")  // emerald bottom-right
    ]
    
    // 5) Risk (Gold Metallic):
    //   Pale gold -> stronger gold -> deeper brownish gold
    static let risk = [
        Color(hex: "F9E6C2"), // pale gold top-left
        Color(hex: "D0A454"), // bolder gold mid
        Color(hex: "765617")  // deep brown-gold bottom-right
    ]
    
    // 6) Timeline (Dark Indigo Metallic):
    //   Pale lavender -> mid-lilac -> deep indigo
    static let timeline = [
        Color(hex: "D7DAF8"), // light lavender top-left
        Color(hex: "6D6EB0"), // mid-lilac mid
        Color(hex: "181B4D")  // dark indigo bottom-right
    ]
    
    // 7) Discharge (Bronze Metallic):
    //   Pale tan -> richer bronze -> dark brown
    static let discharge = [
        Color(hex: "F1DBC3"), // pale tan top-left
        Color(hex: "BF8750"), // bronze mid
        Color(hex: "703E0F")  // darker brown bottom-right
    ]
    
    // 8) Attachments (Silver Metallic):
    //   Near-white silver -> mid-gray -> deeper gunmetal
    static let attachments = [
        Color(hex: "4B4E52"), // near-white silver top-left
        Color(hex: "A6A9AD"), // mid gray
        Color(hex: "F0F2F4")  // deeper gunmetal bottom-right
    ]
    
    // 9) Reports (Icy Metallic):
    //   Very light baby blue -> aqua -> deeper teal
    static let reports = [
        Color(hex: "E5F9FC"), // near-white baby blue top-left
        Color(hex: "78C8D8"), // bright aqua mid
        Color(hex: "1E5A66")  // deeper teal bottom-right
    ]
    
    // 10) Prescriptions (Copper Metallic):
    //   Pale peach -> copperish mid -> deeper brownish copper
    static let prescriptions = [
        Color(hex: "6E3E2A"), // pale peach top-left
        Color(hex: "CF8E60"), // copper mid
        Color(hex: "F7E1D0")  // deeper brownish copper bottom-right
    ]
}



// MARK: - Info Row Component



// MARK: - Status Badge Component

struct StatusBadgeView: View {
    let text: String
    let color: Color
    let iconName: String?
    
    init(text: String, color: Color, iconName: String? = nil) {
        self.text = text
        self.color = color
        self.iconName = iconName
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.system(size: 10, weight: .bold))
            }
            
            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

// MARK: - Action Button Component

struct ActionButtonView: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Metallic highlight
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                            startPoint: .topLeading,
                            endPoint: UnitPoint(x: 0.5, y: 0.5)
                        ))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}





// MARK: - Timeline Card Component

struct TimelineItemView: View {
    let event: TimelineEvent
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                Circle()
                    .fill(event.color)
                    .frame(width: 14, height: 14)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 50)
                }
            }
            .padding(.top, 4)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header with date
                HStack {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Text(formattedDate(event.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Event type badge
                HStack {
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(event.color)
                    
                    Text(event.type.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(event.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(event.color.opacity(0.1))
                .cornerRadius(6)
                
                // Description
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Risk Assessment Card Component

struct RiskAssessmentItemView: View {
    let calculation: StoredCalculation
    let color: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(calculation.calculatorName ?? "Risk Assessment")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                if let date = calculation.calculationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Risk data
            HStack(spacing: 24) {
                // Score
                if calculation.resultScore > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Score")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f", calculation.resultScore))
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                
                // Risk percentage
                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk Level")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", calculation.resultPercentage))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(calculation.riskColor)
                }
                
                Spacer()
                
                // Risk indicator badge
                Text(calculation.riskLevel.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(calculation.riskColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(calculation.riskColor.opacity(0.15))
                    .cornerRadius(20)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
