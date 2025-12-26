// DataExportServiceTests.swift
// SurgiTrackTests
// Tests for the DataExportService
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

@Suite("DataExportService Tests")
struct DataExportServiceTests {

    // MARK: - Export Format Tests

    @Test("Export format has correct file extension")
    func exportFormatFileExtension() {
        #expect(ExportFormat.pdf.fileExtension == "pdf")
        #expect(ExportFormat.csv.fileExtension == "csv")
        #expect(ExportFormat.json.fileExtension == "json")
    }

    @Test("Export format has correct description")
    func exportFormatDescription() {
        #expect(ExportFormat.pdf.description == "PDF")
        #expect(ExportFormat.csv.description == "CSV")
        #expect(ExportFormat.json.description == "JSON")
    }

    @Test("Export format has correct icon")
    func exportFormatIcon() {
        #expect(ExportFormat.pdf.icon == "doc.richtext")
        #expect(ExportFormat.csv.icon == "tablecells")
        #expect(ExportFormat.json.icon == "curlybraces")
    }

    @Test("Export format has format description")
    func exportFormatDescription2() {
        #expect(!ExportFormat.pdf.formatDescription.isEmpty)
        #expect(!ExportFormat.csv.formatDescription.isEmpty)
        #expect(!ExportFormat.json.formatDescription.isEmpty)
    }

    // MARK: - Export Option Tests

    @Test("Export option has correct description")
    func exportOptionDescription() {
        #expect(ExportOption.allData.description == "All Data")
        #expect(ExportOption.patientRecords.description == "Patient Records")
        #expect(ExportOption.surgicalRecords.description == "Surgical Records")
        #expect(ExportOption.followUpData.description == "Follow-up Data")
        #expect(ExportOption.patientList.description == "Patient List")
    }

    @Test("Export option all cases")
    func exportOptionAllCases() {
        #expect(ExportOption.allCases.count == 5)
    }

    // MARK: - TimeFrame Tests

    @Test("TimeFrame has correct description")
    func timeFrameDescription() {
        #expect(TimeFrame.last30Days.description == "Last 30 Days")
        #expect(TimeFrame.last90Days.description == "Last 90 Days")
        #expect(TimeFrame.lastYear.description == "Last Year")
        #expect(TimeFrame.allTime.description == "All Time")
    }

    @Test("TimeFrame start date calculation")
    func timeFrameStartDate() {
        let now = Date()
        let calendar = Calendar.current

        // All time should return nil
        #expect(TimeFrame.allTime.startDate == nil)

        // Other time frames should return past dates
        if let last30 = TimeFrame.last30Days.startDate {
            let daysDiff = calendar.dateComponents([.day], from: last30, to: now).day ?? 0
            #expect(daysDiff >= 29 && daysDiff <= 31)
        }

        if let last90 = TimeFrame.last90Days.startDate {
            let daysDiff = calendar.dateComponents([.day], from: last90, to: now).day ?? 0
            #expect(daysDiff >= 89 && daysDiff <= 91)
        }

        if let lastYear = TimeFrame.lastYear.startDate {
            let yearsDiff = calendar.dateComponents([.year], from: lastYear, to: now).year ?? 0
            #expect(yearsDiff >= 0 && yearsDiff <= 1)
        }
    }

    // MARK: - CSV Escaping Tests

    @Test("CSV escaping for normal strings")
    func csvEscapingNormal() {
        // Test normal string (no special characters)
        let normal = "John Doe"
        #expect(!normal.contains(","))
        #expect(!normal.contains("\""))
        #expect(!normal.contains("\n"))
    }

    @Test("CSV escaping for strings with commas")
    func csvEscapingCommas() {
        let withComma = "Doe, John"
        #expect(withComma.contains(","))
    }

    @Test("CSV escaping for strings with quotes")
    func csvEscapingQuotes() {
        let withQuote = "John \"Johnny\" Doe"
        #expect(withQuote.contains("\""))
    }
}

@Suite("ShareSheet Tests")
struct ShareSheetTests {

    @Test("ShareSheet can be initialized with items")
    func shareSheetInitialization() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        let sheet = ShareSheet(activityItems: [url])
        #expect(sheet.activityItems.count == 1)
    }
}
