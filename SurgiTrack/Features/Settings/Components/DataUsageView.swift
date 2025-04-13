//
//  DataUsageView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// DataUsageView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct DataUsageView: View {
    @State private var storageUsage: [StorageItem] = [
        StorageItem(category: "Patient Records", size: 267, color: .blue),
        StorageItem(category: "Images & Scans", size: 1458, color: .purple),
        StorageItem(category: "Documents", size: 348, color: .orange),
        StorageItem(category: "Application", size: 186, color: .green),
        StorageItem(category: "Other", size: 42, color: .gray)
    ]
    
    @State private var showingClearDataAlert = false
    @State private var selectedCategory: StorageItem? = nil
    @State private var isOptimizing = false
    @State private var optimizationProgress: Double = 0.0
    @State private var optimizationTimer: Timer? = nil
    
    // Stats for data usage history
    private let dataUsageHistory = [
        DataPoint(month: "Jan", upload: 12.4, download: 45.2),
        DataPoint(month: "Feb", upload: 15.8, download: 38.9),
        DataPoint(month: "Mar", upload: 14.3, download: 52.1)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Storage usage card
                usageCard
                
                // Optimization card
                optimizationCard
                
                // Data limits card
                dataLimitsCard
                
                // Data usage history
                dataHistoryCard
                
                // Data management buttons
                dataManagementButtonsSection
                
                // Information card
                informationCard
            }
            .padding()
        }
        .navigationTitle("Data Usage")
        .alert(isPresented: $showingClearDataAlert) {
            Alert(
                title: Text("Clear Data"),
                message: Text("Are you sure you want to clear \(selectedCategory?.category ?? "all") data? This action cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    if let selected = selectedCategory {
                        clearData(for: selected)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - UI Components
    
    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Usage")
                .font(.headline)
            
            // Storage chart
            VStack(spacing: 12) {
                // Chart
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 16)
                        .frame(width: 200, height: 200)
                    
                    ForEach(0..<storageUsage.count, id: \.self) { index in
                        DataUsagePieSegment(
                            data: storageUsage,
                            index: index
                        )
                        .frame(width: 200, height: 200)
                    }
                    
                    VStack {
                        Text("\(totalStorageGB, specifier: "%.1f") GB")
                            .font(.system(size: 24, weight: .bold))
                        Text("Total")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 200)
                .padding(.bottom, 8)
                
                // Legend
                HStack {
                    ForEach(storageUsage, id: \.id) { item in
                        VStack(alignment: .center) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.category)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(formatStorage(item.size))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var optimizationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Storage Optimization")
                    .font(.headline)
                Spacer()
                if isOptimizing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            
            if isOptimizing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optimizing storage...")
                        .font(.subheadline)
                    
                    ProgressView(value: optimizationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(optimizationProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Button(action: {
                    startOptimization()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Optimize Storage")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var dataLimitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Limits")
                .font(.headline)
            
            HStack(spacing: 0) {
                limitButton(icon: "wifi", text: "Wi-Fi Only", isSelected: true)
                limitButton(icon: "network", text: "Cellular", isSelected: false)
                limitButton(icon: "square.and.arrow.down", text: "Downloads", isSelected: false)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var dataHistoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Usage History")
                .font(.headline)
            
            // Data graph
            VStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 16) {
                    ForEach(dataUsageHistory, id: \.month) { point in
                        VStack(spacing: 8) {
                            // Upload bar
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 20, height: 100)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 20, height: CGFloat(point.upload / 60.0 * 100))
                            }
                            
                            // Download bar
                            ZStack(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: 20, height: 100)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 20, height: CGFloat(point.download / 60.0 * 100))
                            }
                            
                            Text(point.month)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Legend
                HStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("Upload")
                            .font(.caption)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("Download")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var dataManagementButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Management")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(storageUsage) { item in
                    Button(action: {
                        selectedCategory = item
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            Text("Clear \(item.category) Data")
                            
                            Spacer()
                            
                            Text(formatStorage(item.size))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Data Usage")
                .font(.headline)
            
            Text("SurgiTrack uses storage space on your device to keep patient records, images, and other data available offline. We recommend keeping at least 2GB of free space for optimal performance.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "square.and.arrow.down", text: "Downloads are stored for offline access")
                infoRow(icon: "arrow.triangle.2.circlepath.circle", text: "Optimize to free up space periodically")
                infoRow(icon: "wifi", text: "Sync occurs only on Wi-Fi by default")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper UI Components
    
    private func limitButton(icon: String, text: String, isSelected: Bool) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private var totalStorageGB: Double {
        let totalMB = storageUsage.reduce(0) { $0 + $1.size }
        return Double(totalMB) / 1024.0
    }
    
    private func formatStorage(_ sizeMB: Int) -> String {
        if sizeMB < 1000 {
            return "\(sizeMB) MB"
        } else {
            let sizeGB = Double(sizeMB) / 1024.0
            return String(format: "%.1f GB", sizeGB)
        }
    }
    
    private func clearData(for item: StorageItem) {
        // In a real app, this would clear cached data for the specific category
        if let index = storageUsage.firstIndex(where: { $0.id == item.id }) {
            storageUsage[index].size = 0
        }
    }
    
    private func startOptimization() {
        isOptimizing = true
        optimizationProgress = 0.0
        
        // Simulate progress with a timer
        optimizationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if optimizationProgress < 1.0 {
                optimizationProgress += 0.01
            } else {
                timer.invalidate()
                optimizationTimer = nil
                isOptimizing = false
                
                // Simulate optimization by reducing storage usage
                for i in 0..<storageUsage.count {
                    storageUsage[i].size = Int(Double(storageUsage[i].size) * 0.85)
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct StorageItem: Identifiable {
    let id = UUID()
    let category: String
    var size: Int // in MB
    let color: Color
}

struct DataUsagePieSegment: View {
    let data: [StorageItem]
    let index: Int
    
    private var total: Double {
        data.reduce(0) { $0 + Double($1.size) }
    }
    
    private var startAngle: Double {
        if index == 0 { return 0 }
        
        let precedingTotal = data[0..<index].reduce(0) { $0 + Double($1.size) }
        return precedingTotal / total * 360
    }
    
    private var endAngle: Double {
        let currentTotal = data[0...index].reduce(0) { $0 + Double($1.size) }
        return currentTotal / total * 360
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 8 // Subtract stroke width
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(data[index].color)
        }
    }
}

struct DataPoint {
    let month: String
    let upload: Double // in MB
    let download: Double // in MB
}

struct DataUsageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataUsageView()
        }
    }
}
