import SwiftUI

struct AdaptiveNavigationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var navigationState = NavigationStateManager()

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadNavigationView
        } else {
            iPhoneNavigationView
        }
    }

    // MARK: - iPad Navigation (Split View)
    private var iPadNavigationView: some View {
        NavigationSplitView(columnVisibility: $navigationState.columnVisibility) {
            // Sidebar
            iPadSidebarView(selection: $navigationState.selectedSection)
                .environmentObject(appState)
                .environmentObject(navigationState)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } content: {
            // Content area - shows lists
            contentView(for: navigationState.selectedSection)
                .navigationSplitViewColumnWidth(min: 350, ideal: 400, max: 500)
        } detail: {
            // Detail area - shows selected item details
            detailView(for: navigationState.selectedSection)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - iPhone Navigation (Current Structure)
    private var iPhoneNavigationView: some View {
        MainPageView()
            .environmentObject(appState)
    }

    // MARK: - Content Views
    @ViewBuilder
    private func contentView(for section: NavigationSection?) -> some View {
        Group {
            switch section {
            case .dashboard:
                DashboardContentView()
            case .patients:
                PatientListView()
            case .appointments:
                AppointmentListView()
            case .reports:
                ReportsView()
                    .environmentObject(ReportsNavigationState())
            case .settings:
                SettingsView()
            case .none:
                PlaceholderContentView(message: "Select a section")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if navigationState.columnVisibility == .detailOnly {
                    Button {
                        withAnimation {
                            navigationState.columnVisibility = .all
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(for section: NavigationSection?) -> some View {
        switch section {
        case .dashboard:
            DashboardDetailView()
        case .patients:
            PlaceholderDetailView(
                icon: "person.3.fill",
                title: "No Patient Selected",
                message: "Select a patient from the list to view details"
            )
        case .appointments:
            PlaceholderDetailView(
                icon: "calendar",
                title: "No Appointment Selected",
                message: "Select an appointment from the list to view details"
            )
        case .reports:
            PlaceholderDetailView(
                icon: "doc.text.fill",
                title: "No Report Selected",
                message: "Select a report from the list to view details"
            )
        case .settings:
            PlaceholderDetailView(
                icon: "gear",
                title: "Settings",
                message: "Configure your preferences"
            )
        case .none:
            PlaceholderDetailView(
                icon: "square.stack.3d.up",
                title: "Welcome to SurgiTrack",
                message: "Select a section to get started"
            )
        }
    }
}

// MARK: - Dashboard Content View
struct DashboardContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("Overview") {
                NavigationLink {
                    DashboardDetailView()
                } label: {
                    Label("Dashboard Overview", systemImage: "chart.bar.fill")
                }
                NavigationLink {
                    EnhancedTrendsView()
                        .environmentObject(appState)
                } label: {
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                }
            }

            Section("Quick Access") {
                NavigationLink {
                    PatientListView()
                } label: {
                    Label("All Patients", systemImage: "person.3.fill")
                }
                NavigationLink {
                    AppointmentListView()
                } label: {
                    Label("All Appointments", systemImage: "calendar")
                }
            }
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Dashboard Detail View
struct DashboardDetailView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dashboard")
                        .font(.system(size: 34, weight: .bold))
                    Text("Overview of your practice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    DashboardStatCard(
                        title: "Patients",
                        value: "0",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    DashboardStatCard(
                        title: "Surgeries",
                        value: "0",
                        icon: "cross.case.fill",
                        color: .orange
                    )
                    DashboardStatCard(
                        title: "Today",
                        value: "0",
                        icon: "calendar",
                        color: .green
                    )
                    DashboardStatCard(
                        title: "Follow-ups",
                        value: "0",
                        icon: "list.bullet.clipboard",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Dashboard Stat Card
struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Placeholder Views
struct PlaceholderContentView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(message)
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct PlaceholderDetailView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.5))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("iPad") {
    AdaptiveNavigationView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("iPhone") {
    AdaptiveNavigationView()
        .environmentObject(AppState())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
