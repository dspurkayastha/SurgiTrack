//
//  ChartData.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 07/03/25.
//

import SwiftUI

// MARK: - Chart Data Models

struct ChartData: Identifiable {
    let id = UUID()
    let value: Double
    let label: String
    let color: Color
    let date: Date?
}

/// Typealias for backwards compatibility if your view model was using ChartDataPoint.
typealias ChartDataPoint = ChartData

struct LineChartData: Identifiable {
    let id = UUID()
    let value: Double
    let label: String
    let date: Date
}

// MARK: - Bar Chart

struct BarChartView: View {
    var data: [ChartData]
    var title: String = ""
    var maxValue: Double? = nil
    var showLabels: Bool = true
    var showLegend: Bool = false
    
    // Computed maximum for scaling
    private var dataMaximum: Double {
        maxValue ?? (data.map { $0.value }.max() ?? 1.0) * 1.1
    }
    
    // Animation state
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            // Y-axis labels and bars in a horizontal stack
            HStack(alignment: .top) {
                if showLabels {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(String(format: "%.0f", dataMaximum))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f", dataMaximum/2))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 35)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data) { item in
                        VStack {
                            Spacer()
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.color)
                                .frame(height: CGFloat(item.value) / CGFloat(dataMaximum) * 150 * animationProgress)
                            
                            if showLabels {
                                Text(item.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(height: 40)
                                    .rotationEffect(.degrees(-45))
                                    .offset(y: 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, showLabels ? 44 : 0)
                .frame(height: 150)
            }
            
            if showLegend {
                HStack(spacing: 16) {
                    ForEach(data) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            Text(item.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Line Chart

struct LineChartView: View {
    var data: [LineChartData]
    var title: String = ""
    var maxValue: Double? = nil
    var lineColor: Color = .blue
    var showDots: Bool = true
    var showLabels: Bool = true
    
    // Computed properties for scaling
    private var sortedData: [LineChartData] {
        data.sorted { $0.date < $1.date }
    }
    
    private var dataMaximum: Double {
        maxValue ?? (data.map { $0.value }.max() ?? 1.0) * 1.1
    }
    
    // Animation state
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            if sortedData.count > 1 {
                HStack(alignment: .top) {
                    if showLabels {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(String(format: "%.0f", dataMaximum))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f", dataMaximum/2))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 35)
                    }
                    
                    GeometryReader { geometry in
                        ZStack {
                            VStack(spacing: 0) {
                                Color.gray.opacity(0.2)
                                    .frame(height: 1)
                                
                                Spacer()
                                
                                Color.gray.opacity(0.2)
                                    .frame(height: 1)
                                
                                Spacer()
                                
                                Color.gray.opacity(0.2)
                                    .frame(height: 1)
                            }
                            
                            linePath(in: geometry.size)
                                .trim(from: 0, to: animationProgress)
                                .stroke(lineColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            
                            if showDots {
                                ForEach(0..<sortedData.count, id: \.self) { i in
                                    let point = dataPoint(at: i, in: geometry.size)
                                    Circle()
                                        .fill(lineColor)
                                        .frame(width: 8, height: 8)
                                        .position(point)
                                        .opacity(animationProgress >= CGFloat(i) / CGFloat(max(1, sortedData.count - 1)) ? 1 : 0)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
                
                if showLabels {
                    HStack {
                        ForEach(0..<min(sortedData.count, 5), id: \.self) { i in
                            let index = i * max(1, sortedData.count / 5)
                            if index < sortedData.count {
                                Text(dateFormatter.string(from: sortedData[index].date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.leading, 35)
                }
            } else {
                Text("Not enough data to display chart")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func linePath(in size: CGSize) -> Path {
        var path = Path()
        guard sortedData.count > 1 else { return path }
        
        let width = size.width
        let height = size.height
        
        let startPoint = CGPoint(
            x: 0,
            y: height - (CGFloat(sortedData[0].value) / CGFloat(dataMaximum)) * height
        )
        path.move(to: startPoint)
        
        for i in 1..<sortedData.count {
            let point = CGPoint(
                x: width * CGFloat(i) / CGFloat(sortedData.count - 1),
                y: height - (CGFloat(sortedData[i].value) / CGFloat(dataMaximum)) * height
            )
            path.addLine(to: point)
        }
        
        return path
    }
    
    private func dataPoint(at index: Int, in size: CGSize) -> CGPoint {
        guard index < sortedData.count, !sortedData.isEmpty else { return .zero }
        return CGPoint(
            x: size.width * CGFloat(index) / CGFloat(max(1, sortedData.count - 1)),
            y: size.height - (CGFloat(sortedData[index].value) / CGFloat(dataMaximum)) * size.height
        )
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

// MARK: - Pie Chart

struct PieChartView: View {
    var data: [ChartData]
    var title: String = ""
    var showLegend: Bool = true
    
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    @State private var selectedSegment: UUID? = nil
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            ZStack {
                ForEach(0..<data.count, id: \.self) { i in
                    PieSegment(
                        start: startAngle(for: i),
                        end: endAngle(for: i),
                        color: data[i].color,
                        isSelected: selectedSegment == data[i].id
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedSegment = selectedSegment == data[i].id ? nil : data[i].id
                        }
                    }
                }
                
                Circle()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                
                if let selected = selectedSegment, let index = data.firstIndex(where: { $0.id == selected }) {
                    let percentage = data[index].value / total * 100
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f%%", percentage))
                            .font(.headline)
                        Text(data[index].label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(String(format: "%.0f", total))
                        .font(.headline)
                }
            }
            .frame(height: 200)
            .padding(.vertical)
            
            if showLegend {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            Text(item.label)
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f", item.value))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(String(format: "(%.1f%%)", (item.value / total * 100)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let precedingSum = data.prefix(index).reduce(0) { $0 + $1.value }
        let start = precedingSum / total * 360
        return start * animationProgress
    }
    
    private func endAngle(for index: Int) -> Double {
        let precedingSum = data.prefix(index + 1).reduce(0) { $0 + $1.value }
        let end = precedingSum / total * 360
        return end * animationProgress
    }
}

// MARK: - Pie Segment

struct PieSegment: View {
    var start: Double
    var end: Double
    var color: Color
    var isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                let radius = min(geometry.size.width, geometry.size.height)/2 * (isSelected ? 1.05 : 1.0)
                path.move(to: center)
                path.addArc(center: center,
                            radius: radius,
                            startAngle: .degrees(start - 90),
                            endAngle: .degrees(end - 90),
                            clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
            .shadow(color: isSelected ? color.opacity(0.4) : Color.clear, radius: 5)
            .animation(.spring(), value: isSelected)
        }
    }
}

// MARK: - Previews

struct ChartComponents_Previews: PreviewProvider {
    static var sampleBarData: [ChartData] = [
        ChartData(value: 25, label: "Jan", color: .blue, date: Date()),
        ChartData(value: 45, label: "Feb", color: .blue, date: Date()),
        ChartData(value: 35, label: "Mar", color: .blue, date: Date()),
        ChartData(value: 65, label: "Apr", color: .blue, date: Date()),
        ChartData(value: 78, label: "May", color: .blue, date: Date())
    ]
    
    static var sampleLineData: [LineChartData] = {
        let now = Date()
        let calendar = Calendar.current
        return (0..<6).map { i in
            let date = calendar.date(byAdding: .month, value: -i, to: now)!
            return LineChartData(value: Double.random(in: 10...90), label: "", date: date)
        }.reversed()
    }()
    
    static var samplePieData: [ChartData] = [
        ChartData(value: 35, label: "Surgery", color: .blue, date: Date()),
        ChartData(value: 25, label: "Consultation", color: .green,date: Date()),
        ChartData(value: 15, label: "Follow-up", color: .orange, date: Date()),
        ChartData(value: 10, label: "Emergency", color: .red, date: Date()),
        ChartData(value: 15, label: "Other", color: .gray, date: Date())
    ]
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                BarChartView(data: sampleBarData, title: "Monthly Surgeries")
                LineChartView(data: sampleLineData, title: "Patient Growth")
                PieChartView(data: samplePieData, title: "Procedures by Type")
            }
            .padding()
        }
    }
}

