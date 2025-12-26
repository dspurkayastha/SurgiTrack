import SwiftUI
import CoreData

struct iPadSidebarView: View {
    @Binding var selection: NavigationSection?
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch current user profile
    @FetchRequest(
        entity: UserProfile.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "isCurrentUser == YES")
    ) private var currentUserProfiles: FetchedResults<UserProfile>

    @State private var isShowingProfile = false
    @State private var isShowingAddPatient = false
    @State private var isShowingSchedule = false
    @State private var showingQuickAction: QuickAction?

    private var currentUserProfile: UserProfile? {
        return currentUserProfiles.first
    }

    var body: some View {
        List(selection: $selection) {
            // User Profile Header
            Section {
                userProfileHeader
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            // Main Navigation
            Section("Navigation") {
                ForEach(NavigationSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label {
                            Text(section.title)
                                .font(.system(size: 16, weight: .medium))
                        } icon: {
                            Image(systemName: section.icon)
                                .font(.system(size: 18))
                                .foregroundColor(section.color)
                                .frame(width: 28)
                        }
                    }
                }
            }

            // Quick Actions
            Section("Quick Actions") {
                ForEach(QuickAction.allCases) { action in
                    Button {
                        handleQuickAction(action)
                    } label: {
                        Label {
                            Text(action.title)
                                .font(.system(size: 15))
                        } icon: {
                            Image(systemName: action.icon)
                                .font(.system(size: 16))
                                .foregroundColor(action.color)
                                .frame(width: 28)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("SurgiTrack")
        .sheet(isPresented: $isShowingProfile) {
            UserProfileView()
        }
        .sheet(isPresented: $isShowingAddPatient) {
            AddPatientView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $showingQuickAction) { action in
            quickActionSheet(for: action)
        }
    }

    // MARK: - User Profile Header
    private var userProfileHeader: some View {
        Button {
            isShowingProfile = true
        } label: {
            HStack(spacing: 16) {
                // Profile Image
                if let imageData = currentUserProfile?.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(appState.currentTheme.primaryColor, lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    appState.currentTheme.primaryColor,
                                    appState.currentTheme.secondaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(currentUserProfile?.initials ?? "SU")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let firstName = currentUserProfile?.firstName,
                       let lastName = currentUserProfile?.lastName {
                        Text("Dr. \(firstName) \(lastName)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text("Surgeon")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("View Profile")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods
    private func handleQuickAction(_ action: QuickAction) {
        Haptics.shared.play(.light)

        switch action {
        case .newPatient:
            isShowingAddPatient = true
        case .scheduleAppointment:
            showingQuickAction = action
        case .riskCalculator:
            showingQuickAction = action
        case .operativeNote:
            showingQuickAction = action
        }
    }

    @ViewBuilder
    private func quickActionSheet(for action: QuickAction) -> some View {
        switch action {
        case .newPatient:
            AddPatientView()
                .environment(\.managedObjectContext, viewContext)
        case .scheduleAppointment:
            NavigationView {
                AppointmentListView()
            }
        case .riskCalculator:
            NavigationView {
                RiskCalculatorListView()
            }
        case .operativeNote:
            NavigationView {
                OperativeNotesView()
            }
        }
    }
}

#Preview {
    NavigationSplitView {
        iPadSidebarView(selection: .constant(.dashboard))
            .environmentObject(AppState())
    } detail: {
        Text("Detail")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
