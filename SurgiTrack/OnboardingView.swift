//
//  OnboardingView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 06/03/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0
    
    // Expanded onboarding content to cover more functionalities
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to SurgiTrack",
            subtitle: "Your comprehensive surgical management solution",
            image: "chart.bar.doc.horizontal",
            description: "Streamline patient care, optimize workflows, and improve surgical outcomes."
        ),
        OnboardingPage(
            title: "Patient Management",
            subtitle: "Complete patient records in one place",
            image: "person.text.rectangle",
            description: "Access detailed patient histories, clinical notes, and appointment schedules effortlessly."
        ),
        OnboardingPage(
            title: "Outpatient & Inpatient Tracking",
            subtitle: "Stay updated on patient statuses",
            image: "stethoscope",
            description: "Track outpatient appointments and monitor admitted patient status for timely interventions."
        ),
        OnboardingPage(
            title: "Operative Scheduling",
            subtitle: "Efficient procedure planning",
            image: "calendar.badge.clock",
            description: "Manage operative schedules, allocate resources, and streamline surgical planning."
        ),
        OnboardingPage(
            title: "Test Reports & Risk Assessment",
            subtitle: "Informed clinical decisions",
            image: "doc.text.magnifyingglass",
            description: "Review medical test reports and use risk calculators for both pre and post-operative patients."
        ),
        OnboardingPage(
            title: "Research & Audit",
            subtitle: "Data-driven insights",
            image: "chart.pie",
            description: "Maintain a robust patient database for research, audit, and quality improvement initiatives."
        ),
        OnboardingPage(
            title: "Patient Summaries & Discharge",
            subtitle: "Efficient and accurate",
            image: "checkmark.circle",
            description: "Prepare concise patient summaries and discharge documents with ease and accuracy."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient with subtle opacity adjustments
            LinearGradient(
                colors: [
                    appState.currentTheme.primaryColor.opacity(0.12),
                    appState.currentTheme.secondaryColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with progress indicators and skip button
                topBar
                
                // Onboarding content using a TabView
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .transition(.slide)
                
                // Navigation buttons (back, next / get started)
                navigationButtons
                    .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Top Bar with Progress and Skip
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage >= index ? appState.currentTheme.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    appState.completeOnboarding()
                }
            }) {
                Text("Skip")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Individual Page View
    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Image(systemName: page.image)
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            appState.currentTheme.primaryColor.opacity(0.8),
                            appState.currentTheme.secondaryColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 30)
            
            VStack(spacing: 8) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                Button(action: {
                    withAnimation {
                        currentPage = max(currentPage - 1, 0)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding()
                        .background(Circle().fill(Color.gray.opacity(0.15)))
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        appState.completeOnboarding()
                    }
                }
            }) {
                HStack {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                    Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "checkmark")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(appState.currentTheme.primaryColor)
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let image: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AppState())
    }
}

