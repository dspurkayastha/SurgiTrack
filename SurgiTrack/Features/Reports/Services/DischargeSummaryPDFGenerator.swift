//
//  DischargeSummaryPDFGenerator.swift
//  SurgiTrack
//
//  Created on 10/03/25.
//  Updated for improved fonts, color styling, initial presentation, and addendum
//

import SwiftUI
import PDFKit
import CoreData

class DischargeSummaryPDFGenerator {
    
    // MARK: - Core Model References
    private let dischargeSummary: DischargeSummary
    private let viewContext: NSManagedObjectContext
    private let currentUser: String
    private let userProfile: UserProfile
    
    // MARK: - Hospital / Document Info
    private var hospitalName: String
    private var hospitalAddress: String
    private var departmentName: String
    private var unitName: String
    private let hospitalLogo = UIImage(named: "HospitalLogo")  // optional
    
    // MARK: - Layout & Styling
    /// Page sizes for US Letter
    private let pageWidth: CGFloat = 8.27 * 72.0  // A4 width in inches * 72 dpi
    private let pageHeight: CGFloat = 11.69 * 72.0  // A4 height in inches * 72 dpi
    private let margin: CGFloat = 50  // Margin remains the same
    private var yPosition: CGFloat = 0
    
    /// Larger line spacing for readability
    private let lineSpacing: CGFloat = 4
    
    // Font size hierarchy
    private let titleFontSize: CGFloat = 16   // main doc headings
    private let sectionFontSize: CGFloat = 14 // section headings
    private let subheadingFontSize: CGFloat = 12
    private let bodyFontSize: CGFloat = 11
    private let smallFontSize: CGFloat = 10
    private let footerFontSize: CGFloat = 9
    
    // Colors for theming
    private let primaryColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 1.0)
    private let secondaryColor = UIColor(red: 0.2, green: 0.6, blue: 0.4, alpha: 1.0)
    private let accentColor = UIColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1.0)
    
    // Light fill for background boxes
    private let boxFillColor = UIColor.lightGray.withAlphaComponent(0.1)
    
    // Pagination
    private var pageNumber = 1
    private var totalPages = 1
    
    // For date formatting
    private let dateFormatter: DateFormatter
    
    // MARK: - Init
    init(dischargeSummary: DischargeSummary,
         viewContext: NSManagedObjectContext,
         currentUser: String = "System User",
         userProfile: UserProfile) {
        
        self.dischargeSummary = dischargeSummary
        self.viewContext = viewContext
        self.currentUser = currentUser
        self.userProfile = userProfile  // store the user profile
        
        // Set hospital details from UserProfile attributes
        self.hospitalName = userProfile.hospitalName ?? "Default Hospital Name"
        self.hospitalAddress = userProfile.hospitalAddress ?? "Default Hospital Address"
        self.departmentName = userProfile.departmentName ?? "Default Department"
        self.unitName = userProfile.unitName ?? "Default Unit"
        
        // Date formatter remains unchanged
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
    }
    
    // MARK: - Public Method: Generate PDF
    func generatePDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        
        // PDF metadata
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "SurgiTrack Medical System",
            kCGPDFContextAuthor as String: currentUser,
            kCGPDFContextTitle as String: "Discharge Summary",
            kCGPDFContextSubject as String: "Patient Discharge Documentation",
            kCGPDFContextKeywords as String: "discharge, medical, summary, patient care"
        ]
        format.documentInfo = pdfMetaData
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { context in
            // 1) estimate content to handle pagination
            let estimatedHeight = calculateContentHeight()
            totalPages = Int(ceil(estimatedHeight / (pageHeight - 150))) // some overhead for header/footer
            
            // 2) Actually draw the content
            drawPage(context: context)
        }
    }
    
    // MARK: - Main Page Flow
    private func drawPage(context: UIGraphicsPDFRendererContext) {
        // Create first page
        context.beginPage()
        pageNumber = 1
        yPosition = margin
        
        // Header
        drawDocumentHeader()
        
        // Patient Info
        drawPatientInfo()
        drawSeparator()
        
        // NEW: Initial Presentation
        drawInitialPresentation()
        drawSeparator()
        
        // Diagnoses
        drawDiagnoses()
        drawSeparator()
        
        // Treatment
        checkAndStartNewPageIfNeeded(context: context, neededHeight: 300)
        drawTreatment()
        drawSeparator()
        
        // Operative
        let operativeDataList = getPatientOperativeData()
        if !operativeDataList.isEmpty {
            checkAndStartNewPageIfNeeded(context: context, neededHeight: 250)
            drawOperativeNotes(operativeDataList: operativeDataList)
            drawSeparator()
        }
        
        // Medications
        checkAndStartNewPageIfNeeded(context: context, neededHeight: 250)
        drawMedications()
        drawSeparator()
        
        // Relevant test results
        let testResults = getPatientTestResults()
        if !testResults.isEmpty {
            checkAndStartNewPageIfNeeded(context: context, neededHeight: 250)
            drawRelevantReports(testResults: testResults)
            drawSeparator()
        }
        
        // Follow-up
        checkAndStartNewPageIfNeeded(context: context, neededHeight: 300)
        drawFollowUpInstructions()
        drawSeparator()
        
        // Checklist
        checkAndStartNewPageIfNeeded(context: context, neededHeight: 200)
        drawChecklist()
        drawSeparator()
        
        // Additional notes
        if let notes = dischargeSummary.additionalNotes, !notes.isEmpty {
            checkAndStartNewPageIfNeeded(context: context, neededHeight: 200)
            drawAdditionalNotes()
            drawSeparator()
        }
        
        // Signature / Prepared By
        checkAndStartNewPageIfNeeded(context: context, neededHeight: 200)
        drawSignatureSection()
        
        // Addendum - Detailed test parameters in 10pt, on new page(s)
        drawAddendum(context: context, tests: testResults)
    }
    
    // MARK: - 1) Document Header
    private func drawDocumentHeader() {
        // Draw hospital logo if available
        if let logo = hospitalLogo {
            let logoRect = CGRect(x: margin, y: yPosition, width: 60, height: 60)
            logo.draw(in: logoRect)
        }
        
        // Hospital info to the right
        let hospitalFont = UIFont.boldSystemFont(ofSize: bodyFontSize)
        let addressFont = UIFont.systemFont(ofSize: smallFontSize)
        let deptFont = UIFont.italicSystemFont(ofSize: smallFontSize)
        
        let hospitalNameString = hospitalName as NSString
        hospitalNameString.draw(
            at: CGPoint(x: pageWidth - margin - 250, y: yPosition),
            withAttributes: [.font: hospitalFont, .foregroundColor: primaryColor]
        )
        
        let addressString = hospitalAddress as NSString
        addressString.draw(
            at: CGPoint(x: pageWidth - margin - 250, y: yPosition + 16),
            withAttributes: [.font: addressFont, .foregroundColor: UIColor.darkGray]
        )
        
        let departmentString = departmentName as NSString
        departmentString.draw(
            at: CGPoint(x: pageWidth - margin - 250, y: yPosition + 32),
            withAttributes: [.font: deptFont, .foregroundColor: UIColor.darkGray]
        )
        let unitString = unitName as NSString
        unitString.draw(
            at: CGPoint(x: pageWidth - margin - 250, y: yPosition + 48),
            withAttributes: [.font: deptFont, .foregroundColor: UIColor.darkGray]
        )
        yPosition += 70
        
        // Title box
        let titleRect = CGRect(x: margin, y: yPosition, width: pageWidth - (margin * 2), height: 32)
        UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
        UIBezierPath(roundedRect: titleRect, cornerRadius: 5).fill()
        
        primaryColor.setStroke()
        UIBezierPath(roundedRect: titleRect, cornerRadius: 5).stroke()
        
        // Centered Title
        let titleStr = "DISCHARGE SUMMARY" as NSString
        let titleFont = UIFont.boldSystemFont(ofSize: titleFontSize)
        let titleAttribs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primaryColor
        ]
        let titleSize = titleStr.size(withAttributes: titleAttribs)
        let titleX = (pageWidth - titleSize.width) / 2
        titleStr.draw(
            at: CGPoint(x: titleX, y: yPosition + 6),
            withAttributes: titleAttribs
        )
        
        // Additional doc info
        let smallF = UIFont.systemFont(ofSize: smallFontSize)
        let genDate = "Generated: \(dateFormatter.string(from: Date()))" as NSString
        genDate.draw(
            at: CGPoint(x: margin + 10, y: yPosition + 40),
            withAttributes: [.font: smallF, .foregroundColor: UIColor.darkGray]
        )
        
        let docID = "Doc ID: DS-\(dischargeSummary.id?.uuidString.prefix(8) ?? "N/A")" as NSString
        docID.draw(
            at: CGPoint(x: pageWidth - margin - 150, y: yPosition + 40),
            withAttributes: [.font: smallF, .foregroundColor: UIColor.darkGray]
        )
        
        yPosition += 80
    }
    
    // MARK: - 2) Patient Info
    private func drawPatientInfo() {
        guard let patient = dischargeSummary.patient else { return }
        
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("PATIENT INFORMATION", font: sectionF, iconName: "person.circle.fill")
        yPosition += 8
        
        let labelFont = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let valueFont = UIFont.systemFont(ofSize: bodyFontSize)
        
        let leftX = margin
        let rightX = margin + 280
        let labelW: CGFloat = 100
        
        // Name & MRN
        drawInfoRow(label: "Name:", value: patient.fullName, labelX: leftX, valueX: leftX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        drawInfoRow(label: "MRN:", value: patient.medicalRecordNumber ?? "Unknown",
                    labelX: rightX, valueX: rightX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        yPosition += 20
        
        // DOB & Gender
        drawInfoRow(label: "DOB:", value: formatDate(patient.dateOfBirth),
                    labelX: leftX, valueX: leftX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        drawInfoRow(label: "Gender:", value: patient.gender ?? "Unknown",
                    labelX: rightX, valueX: rightX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        yPosition += 20
        
        // Admission / Discharge
        drawInfoRow(label: "Admission Date:", value: formatDate(patient.dateCreated),
                    labelX: leftX, valueX: leftX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        drawInfoRow(label: "Discharge Date:", value: formatDate(dischargeSummary.dischargeDate),
                    labelX: rightX, valueX: rightX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        yPosition += 20
        
        // LOS, contact
        let los = calculateLengthOfStay()
        drawInfoRow(label: "Length of Stay:", value: "\(los) day\(los == 1 ? "" : "s")",
                    labelX: leftX, valueX: leftX + labelW, y: yPosition,
                    labelFont: labelFont, valueFont: valueFont)
        
        if let phone = patient.phone, !phone.isEmpty {
            drawInfoRow(label: "Contact:", value: phone,
                        labelX: rightX, valueX: rightX + labelW, y: yPosition,
                        labelFont: labelFont, valueFont: valueFont)
        } else if let contact = patient.contactInfo, !contact.isEmpty {
            drawInfoRow(label: "Contact:", value: contact,
                        labelX: rightX, valueX: rightX + labelW, y: yPosition,
                        labelFont: labelFont, valueFont: valueFont)
        }
        yPosition += 30
    }
    
    // MARK: - 2.5) Initial Presentation
    private func drawInitialPresentation() {
        guard let initial = dischargeSummary.patient?.initialPresentation else { return }
        
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("INITIAL PRESENTATION", font: sectionF, iconName: "staroflife.fill")
        yPosition += 10
        
        let boxStartY = yPosition
        var boxHeight: CGFloat = 0
        
        let subF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let bodyF = UIFont.systemFont(ofSize: bodyFontSize)
        
        // History of Present Illness
        let hpiLabel = "History of Present Illness:" as NSString
        hpiLabel.draw(at: CGPoint(x: margin, y: yPosition),
                      withAttributes: [.font: subF, .foregroundColor: primaryColor])
        yPosition += 27; boxHeight += 20
        
        let hpiText = initial.historyOfPresentIllness ?? "N/A"
        let hpiH = drawWrappedText(text: hpiText, font: bodyF, x: margin + 20, y: &yPosition,
                                  width: pageWidth - (margin * 2) - 40)
        boxHeight += hpiH + 10
        yPosition += 10
        
        // Past Medical
        let pmhLabel = "Past Medical History:" as NSString
        pmhLabel.draw(at: CGPoint(x: margin, y: yPosition),
                      withAttributes: [.font: subF, .foregroundColor: primaryColor])
        yPosition += 20; boxHeight += 20
        let pmhText = initial.pastMedicalHistory ?? "N/A"
        let pmhH = drawWrappedText(text: pmhText, font: bodyF, x: margin + 20, y: &yPosition,
                                  width: pageWidth - (margin * 2) - 40)
        boxHeight += pmhH + 10
        yPosition += 10
        
        // Past Surgical (placeholder if you have no direct field)
        let pshLabel = "Past Surgical History:" as NSString
        pshLabel.draw(at: CGPoint(x: margin, y: yPosition),
                      withAttributes: [.font: subF, .foregroundColor: primaryColor])
        yPosition += 20; boxHeight += 20
        // For now, we just show "N/A"
        let pshText = "N/A"
        let pshH = drawWrappedText(text: pshText, font: bodyF, x: margin + 20, y: &yPosition,
                                  width: pageWidth - (margin * 2) - 40)
        boxHeight += pshH + 10
        yPosition += 10
        
        // Draw background box
        let rect = CGRect(x: margin, y: boxStartY, width: pageWidth - (margin * 2), height: (boxHeight + 30))
        boxFillColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
        
        UIColor.gray.withAlphaComponent(0.4).setStroke()
        UIBezierPath(roundedRect: rect, cornerRadius: 5).stroke()
        
        // Slightly move y
        yPosition += 20
    }
    
    // MARK: - 3) Diagnoses
    private func drawDiagnoses() {
        // (similar to your existing code, just sure to unify the font usage)
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("DIAGNOSES", font: sectionF, iconName: "stethoscope")
        yPosition += 15
        
        let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let valueF = UIFont.systemFont(ofSize: bodyFontSize)
        
        // Box
        let diagBoxHeight = 120.0 // or dynamically measure
        let diagRect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: diagBoxHeight)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: diagRect, cornerRadius: 5).fill()
        
        // Primary
        drawInfoRow(label: "Primary Diagnosis:", value: dischargeSummary.primaryDiagnosis ?? "N/A",
                    labelX: margin + 10, valueX: margin + 140, y: yPosition + 10,
                    labelFont: labelF, valueFont: valueF)
        yPosition += 30
        
        // Secondary
        if let second = dischargeSummary.secondaryDiagnoses, !second.isEmpty {
            drawInfoRow(label: "Secondary Diagnoses:", value: dischargeSummary.secondaryDiagnoses ?? "N/A",
                        labelX: margin + 10, valueX: margin + 180, y: yPosition + 10,
                        labelFont: labelF, valueFont: valueF)
            yPosition += 30
        }
        yPosition += 15
    }
    
    // MARK: - 4) Treatment
    private func drawTreatment() {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("TREATMENT SUMMARY", font: sectionF, iconName: "cross.case")
        yPosition += 15
        
        let bodyF = UIFont.systemFont(ofSize: bodyFontSize)
        let summary = dischargeSummary.treatmentSummary ?? "Not specified"
        _ = drawWrappedText(text: summary, font: bodyF, x: margin, y: &yPosition,
                            width: pageWidth - (margin * 2))
        yPosition += 15
        
        if let procedures = dischargeSummary.procedures, !procedures.isEmpty {
            let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
            let label = "Procedures Performed:" as NSString
            label.draw(at: CGPoint(x: margin, y: yPosition),
                       withAttributes: [.font: labelF, .foregroundColor: primaryColor])
            yPosition += 20
            let lines = procedures.components(separatedBy: "\n")
            for line in lines {
                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    drawBulletPoint(text: line.trimmingCharacters(in: .whitespaces),
                                    x: margin + 15, y: &yPosition,
                                    width: pageWidth - (margin * 2) - 15,
                                    font: bodyF)
                }
            }
        }
        yPosition += 10
    }
    
    // MARK: - 5) Operative
    private func drawOperativeNotes(operativeDataList: [OperativeData]) {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("OPERATIVE DETAILS", font: sectionF, iconName: "scalpel")
        yPosition += 10
        
        let subheadingF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let valueF = UIFont.systemFont(ofSize: bodyFontSize)
        
        for opData in operativeDataList {
            let procedureName = opData.procedureName ?? "Unspecified Procedure"
            let dateStr = formatDate(opData.operationDate)
            let fullTitle = "\(procedureName) (\(dateStr))" as NSString
            
            fullTitle.draw(at: CGPoint(x: margin, y: yPosition),
                           withAttributes: [.font: subheadingF, .foregroundColor: primaryColor])
            yPosition += 20
            
            let boxStartY = yPosition
            var localHeight: CGFloat = 0
            
            // Anesthesia
            if let anesthesia = opData.anaesthesiaType {
                drawInfoRow(label: "Anesthesia:", value: anesthesia,
                            labelX: margin + 10, valueX: margin + 100, y: yPosition,
                            labelFont: labelF, valueFont: valueF)
                yPosition += 20; localHeight += 20
            }
            
            // Surgeon
            let surgeon = opData.surgeonName ?? "Unknown"
            drawInfoRow(label: "Surgeon:", value: surgeon,
                        labelX: margin + 10, valueX: margin + 100, y: yPosition,
                        labelFont: labelF, valueFont: valueF)
            yPosition += 20; localHeight += 20
            
            // Duration / Blood
            let duration = "\(Int(opData.duration)) minutes"
            let blood = "\(Int(opData.estimatedBloodLoss)) mL"
            drawInfoRow(label: "Duration:", value: duration,
                        labelX: margin + 10, valueX: margin + 100, y: yPosition,
                        labelFont: labelF, valueFont: valueF)
            drawInfoRow(label: "Blood Loss:", value: blood,
                        labelX: margin + 250, valueX: margin + 330, y: yPosition,
                        labelFont: labelF, valueFont: valueF)
            yPosition += 20; localHeight += 20
            
            // Notes
            if let notes = opData.operativeNotes, !notes.isEmpty {
                drawInfoRow(label: "Notes:", value: "", labelX: margin + 10, valueX: margin + 100,
                            y: yPosition, labelFont: labelF, valueFont: valueF)
                yPosition += 20; localHeight += 20
                let noteH = drawWrappedText(text: notes, font: valueF, x: margin + 25, y: &yPosition,
                                            width: pageWidth - margin * 2 - 50)
                yPosition += 20; localHeight += noteH
            }
            
            // Findings
            if let findings = opData.operativeFindings, !findings.isEmpty {
                drawInfoRow(label: "Findings:", value: "", labelX: margin + 10, valueX: margin + 100,
                            y: yPosition, labelFont: labelF, valueFont: valueF)
                yPosition += 20; localHeight += 20
                let findH = drawWrappedText(text: findings, font: valueF, x: margin + 25, y: &yPosition,
                                            width: pageWidth - margin * 2 - 50)
                yPosition += 20; localHeight += findH
            }
            
            // Gray box behind
            let rect = CGRect(x: margin, y: boxStartY,
                              width: pageWidth - (margin * 2),
                              height: localHeight + 60)
            boxFillColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
            yPosition += 30
        }
    }
    
    // MARK: - 6) Medications
    private func drawMedications() {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("MEDICATIONS", font: sectionF, iconName: "pills")
        yPosition += 15
        
        let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let valueF = UIFont.systemFont(ofSize: bodyFontSize)
        
        // Current
        let currentLabel = "Current Medications:" as NSString
        currentLabel.draw(
            at: CGPoint(x: margin, y: yPosition),
            withAttributes: [.font: labelF, .foregroundColor: primaryColor]
        )
        yPosition += 20
        let currentMeds = dischargeSummary.medicationsAtDischarge ?? "None"
        let boxRect1 = CGRect(x: margin + 15, y: yPosition, width: pageWidth - margin * 2 - 30, height: 60)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: boxRect1, cornerRadius: 5).fill()
        _ = drawWrappedText(text: currentMeds, font: valueF, x: margin + 25, y: &yPosition,
                            width: pageWidth - margin * 2 - 50)
        yPosition += 20
        
        // Discharge
        let dchLabel = "Discharge Prescriptions:" as NSString
        dchLabel.draw(
            at: CGPoint(x: margin, y: yPosition),
            withAttributes: [.font: labelF, .foregroundColor: primaryColor]
        )
        yPosition += 20
        let dischargeRx = dischargeSummary.dischargeMedications ?? "None"
        let boxRect2 = CGRect(x: margin + 15, y: yPosition, width: pageWidth - margin * 2 - 30, height: 60)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: boxRect2, cornerRadius: 5).fill()
        _ = drawWrappedText(text: dischargeRx, font: valueF, x: margin + 25, y: &yPosition,
                            width: pageWidth - margin * 2 - 50)
        yPosition += 20
    }
    
    // MARK: - 7) Relevant Reports
    private func drawRelevantReports(testResults: [MedicalTest]) {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("RELEVANT REPORTS", font: sectionF, iconName: "doc.text.magnifyingglass")
        yPosition += 15
        
        let subF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let labelF = UIFont.systemFont(ofSize: bodyFontSize)
        
        if testResults.isEmpty {
            let noStr = "No test reports available" as NSString
            noStr.draw(at: CGPoint(x: margin, y: yPosition),
                       withAttributes: [.font: labelF, .foregroundColor: UIColor.gray])
            yPosition += 20
            return
        }
        
        // Group by category
        let grouped = Dictionary(grouping: testResults) { $0.testCategory ?? "Other" }
        
        for (cat, tests) in grouped.sorted(by: { $0.key < $1.key }) {
            let catStr = cat as NSString
            catStr.draw(at: CGPoint(x: margin, y: yPosition),
                        withAttributes: [.font: subF, .foregroundColor: primaryColor])
            yPosition += 20
            
            for test in tests.sorted(by: { ($0.testDate ?? Date.distantPast) < ($1.testDate ?? Date.distantPast) }) {
                // Title
                let testTitle = "\(test.testType ?? "Unknown Test") (\(formatDate(test.testDate)))" as NSString
                let color = test.isAbnormal ? accentColor : UIColor.black
                testTitle.draw(at: CGPoint(x: margin + 15, y: yPosition),
                               withAttributes: [.font: labelF, .foregroundColor: color])
                yPosition += 20
                
                if let summary = test.summary, !summary.isEmpty {
                    let sumStr = summary as NSString
                    sumStr.draw(at: CGPoint(x: margin + 30, y: yPosition),
                                withAttributes: [.font: labelF, .foregroundColor: UIColor.darkGray])
                    yPosition += 20
                }
                yPosition += 5
            }
            yPosition += 10
        }
        yPosition += 10
    }
    
    // MARK: - 8) Follow-up
    private func drawFollowUpInstructions() {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("FOLLOW-UP INSTRUCTIONS", font: sectionF, iconName: "calendar.badge.clock")
        yPosition += 15
        
        let bodyF = UIFont.systemFont(ofSize: bodyFontSize)
        
        // Background box
        let boxRect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: 150)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 5).fill()
        
        let instructions = dischargeSummary.followUpInstructions ?? "No instructions"
        let neededH = drawWrappedText(text: instructions, font: bodyF, x: margin + 15, y: &yPosition,
                                      width: pageWidth - margin * 2 - 30)
        yPosition += 10
        
        // Activity restrictions
        if let restrict = dischargeSummary.activityRestrictions, !restrict.isEmpty {
            let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
            let lab = "Activity Restrictions:" as NSString
            lab.draw(at: CGPoint(x: margin + 15, y: yPosition),
                     withAttributes: [.font: labelF, .foregroundColor: primaryColor])
            yPosition += 20
            drawWrappedText(text: restrict, font: bodyF, x: margin + 25, y: &yPosition,
                            width: pageWidth - margin * 2 - 40)
        }
        
        if let diet = dischargeSummary.dietaryInstructions, !diet.isEmpty {
            yPosition += 10
            let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
            let lab = "Dietary Instructions:" as NSString
            lab.draw(at: CGPoint(x: margin + 15, y: yPosition),
                     withAttributes: [.font: labelF, .foregroundColor: primaryColor])
            yPosition += 20
            drawWrappedText(text: diet, font: bodyF, x: margin + 25, y: &yPosition,
                            width: pageWidth - margin * 2 - 40)
        }
        
        yPosition += 30
        
        // Return Precautions
        if let precautions = dischargeSummary.returnPrecautions, !precautions.isEmpty {
            drawSectionTitle("RETURN PRECAUTIONS", font: sectionF, iconName: "exclamationmark.triangle")
            yPosition += 10
            drawAlertBox(title: "Return Immediately If:", content: precautions)
        }
    }
    
    private func drawAlertBox(title: String, content: String) {
        let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let bodyF = UIFont.systemFont(ofSize: bodyFontSize)
        
        let contentHeight = estimateTextHeight(text: content, font: bodyF, width: pageWidth - margin * 2 - 40) + 40
        
        let boxRect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: contentHeight)
        accentColor.withAlphaComponent(0.1).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 5).fill()
        
        accentColor.withAlphaComponent(0.4).setStroke()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 5).stroke()
        
        // Title + icon
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let icon = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config) {
            icon.withTintColor(accentColor).draw(in: CGRect(x: margin + 10, y: yPosition + 10, width: 14, height: 14))
        }
        let titleStr = title as NSString
        titleStr.draw(
            at: CGPoint(x: margin + 30, y: yPosition + 10),
            withAttributes: [.font: labelF, .foregroundColor: accentColor]
        )
        
        var cY = yPosition + 35
        drawWrappedText(text: content, font: bodyF, x: margin + 15, y: &cY,
                        width: pageWidth - margin*2 - 30, color: UIColor.darkGray)
        
        yPosition = boxRect.maxY + 10
    }
    
    // MARK: - 9) Checklist
    private func drawChecklist() {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("DISCHARGE CHECKLIST", font: sectionF, iconName: "checkmark.square.fill")
        yPosition += 15
        
        let boxRect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: 140)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 5).fill()
        yPosition += 10
        
        let leftX = margin + 20
        let rightX = margin + 320
        
        drawChecklistItem("Patient education completed", isChecked: dischargeSummary.patientEducationCompleted, x: leftX, y: &yPosition)
        drawChecklistItem("Medications reconciled", isChecked: dischargeSummary.medicationsReconciled, x: leftX, y: &yPosition)
        drawChecklistItem("Follow-up appointment scheduled", isChecked: dischargeSummary.followUpAppointmentScheduled, x: leftX, y: &yPosition)
        
        yPosition -= 60
        
        drawChecklistItem("Medical devices provided", isChecked: dischargeSummary.medicalDevicesProvided, x: rightX, y: &yPosition)
        drawChecklistItem("Transportation arranged", isChecked: dischargeSummary.transportationArranged, x: rightX, y: &yPosition)
        
        yPosition = boxRect.maxY + 10
    }
    
    private func drawChecklistItem(_ text: String, isChecked: Bool, x: CGFloat, y: inout CGFloat) {
        let itemF = UIFont.systemFont(ofSize: bodyFontSize)
        let size: CGFloat = 16
        let rect = CGRect(x: x, y: y, width: size, height: size)
        UIColor.gray.withAlphaComponent(0.3).setStroke()
        UIBezierPath(roundedRect: rect, cornerRadius: 3).stroke()
        
        if isChecked {
            primaryColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 3).fill()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x+3, y: y + size/2))
            path.addLine(to: CGPoint(x: x + size/3, y: y + size - 3))
            path.addLine(to: CGPoint(x: x + size - 3, y: y + 3))
            path.lineWidth = 2
            UIColor.white.setStroke()
            path.stroke()
        }
        
        let textX = x + size + 10
        let tStr = text as NSString
        let tColor = isChecked ? primaryColor : UIColor.darkGray
        tStr.draw(
            at: CGPoint(x: textX, y: y + 2),
            withAttributes: [.font: itemF, .foregroundColor: tColor]
        )
        y += 20
    }
    
    // MARK: - 10) Additional Notes
    private func drawAdditionalNotes() {
        guard let notes = dischargeSummary.additionalNotes, !notes.isEmpty else { return }
        
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("ADDITIONAL NOTES", font: sectionF, iconName: "note.text")
        yPosition += 15
        
        let valueF = UIFont.systemFont(ofSize: bodyFontSize)
        
        let boxH = estimateTextHeight(text: notes, font: valueF, width: pageWidth - margin*2 - 20) + 20
        let rect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: boxH)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 5).fill()
        
        _ = drawWrappedText(text: notes, font: valueF, x: margin + 15, y: &yPosition,
                            width: pageWidth - margin*2 - 30)
        yPosition += 20
    }
    
    // MARK: - 11) Signature + Prepared By
    private func drawSignatureSection() {
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("AUTHORIZATION & SIGNATURES", font: sectionF, iconName: "signature")
        yPosition += 20
        
        let labelF = UIFont.boldSystemFont(ofSize: subheadingFontSize)
        let valueF = UIFont.systemFont(ofSize: bodyFontSize)
        
        // Main signature area with updated label "V.S. Signature"
        let sigRect = CGRect(x: margin, y: yPosition, width: 300, height: 100)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: sigRect, cornerRadius: 5).fill()
        
        let lineY = yPosition + 70
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin + 20, y: lineY))
        linePath.addLine(to: CGPoint(x: margin + 280, y: lineY))
        UIColor.black.setStroke()
        linePath.stroke()
        
        // Change the label to "V.S. Signature"
        let labelStr = "V.S. Signature" as NSString
        labelStr.draw(
            at: CGPoint(x: margin + 20, y: yPosition + 15),
            withAttributes: [.font: labelF]
        )
        
        let docName = dischargeSummary.dischargingPhysician ?? "Unknown"
        docName.draw(
            at: CGPoint(x: margin + 20, y: lineY + 10),
            withAttributes: [.font: valueF, .foregroundColor: UIColor.black]
        )
        
        // Date box (unchanged)
        let dateRect = CGRect(x: margin + 350, y: yPosition, width: 150, height: 70)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: dateRect, cornerRadius: 5).fill()
        
        let dateLabel = "Date:" as NSString
        dateLabel.draw(
            at: CGPoint(x: margin + 360, y: yPosition + 15),
            withAttributes: [.font: labelF, .foregroundColor: UIColor.darkGray]
        )
        
        let dStr = dateFormatter.string(from: Date()) as NSString
        dStr.draw(
            at: CGPoint(x: margin + 360, y: yPosition + 40),
            withAttributes: [.font: valueF, .foregroundColor: UIColor.black]
        )
        
        yPosition += 120
        
        // Updated "Prepared By" section with added doctor's name
        let prepRect = CGRect(x: margin, y: yPosition, width: 300, height: 80)
        boxFillColor.setFill()
        UIBezierPath(roundedRect: prepRect, cornerRadius: 5).fill()
        
        let prepLabel = "Prepared By:" as NSString
        prepLabel.draw(
            at: CGPoint(x: margin + 10, y: yPosition + 10),
            withAttributes: [.font: labelF, .foregroundColor: UIColor.darkGray]
        )
        
        // Add doctor's name from UserProfile (concatenating first and last name)
        let doctorName = "Dr \(String(describing: userProfile.firstName)) \(userProfile.lastName ?? "")"
        let doctorNameStr = doctorName as NSString
        doctorNameStr.draw(
            at: CGPoint(x: margin + 150, y: yPosition + 10),
            withAttributes: [.font: labelF, .foregroundColor: UIColor.darkGray]
        )
        
        // Draw a separator line for the signature area instead of underscore text
        let sigLineY = yPosition + 55
        let sigLinePath = UIBezierPath()
        sigLinePath.move(to: CGPoint(x: margin + 10, y: sigLineY))
        sigLinePath.addLine(to: CGPoint(x: margin + 290, y: sigLineY))
        sigLinePath.lineWidth = 1
        UIColor.black.setStroke()
        sigLinePath.stroke()
        
        yPosition += 80
    }
    // MARK: - 12) Addendum with 10pt test parameters
    private func drawAddendum(context: UIGraphicsPDFRendererContext, tests: [MedicalTest]) {
        // Gather all param counts
        let paramCount = tests.reduce(0) { $0 + ($1.testParameters?.count ?? 0) }
        guard paramCount > 0 else { return }
        
        // Start a new page
        drawPageFooter()
        context.beginPage()
        pageNumber += 1
        yPosition = margin
        drawDocumentHeader()
        
        let sectionF = UIFont.boldSystemFont(ofSize: sectionFontSize)
        drawSectionTitle("DETAILED TEST PARAMETERS", font: sectionF, iconName: "doc.text.magnifyingglass")
        yPosition += 20
        
        let paramFont = UIFont.systemFont(ofSize: smallFontSize) // 10pt
        let sortedTests = tests.sorted { ($0.testDate ?? Date.distantPast) < ($1.testDate ?? Date.distantPast) }
        
        for test in sortedTests {
            guard let params = test.testParameters as? Set<TestParameter>, !params.isEmpty else { continue }
            
            // Safely coalesce test.testType and format the date
            let safeTestType = test.testType ?? "Unknown Test"
            let dateString = formatDate(test.testDate) // returns a String (e.g. "Unknown" if nil)
            
            // Convert to NSString with the combined text
            let combinedTitle = "\(safeTestType) - \(dateString)"
            let testTitle = NSString(string: combinedTitle)
            
            // Draw test title
            testTitle.draw(
                at: CGPoint(x: margin, y: yPosition),
                withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: smallFontSize + 1),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray
                ]
            )
            yPosition += 15
            
            // Sort parameters by name
            let paramList = params.sorted { ($0.parameterName ?? "") < ($1.parameterName ?? "") }
            for param in paramList {
                checkAndStartNewPageIfNeeded(context: context, neededHeight: 40)
                drawAddendumParameter(param: param, font: paramFont)
            }
            
            yPosition += 15
        }
    }
    
    private func drawAddendumParameter(param: TestParameter, font: UIFont) {
        let labelX = margin + 20
        let valueX = margin + 180
        
        // Safely coalesce parameterName
        let paramName = param.parameterName ?? "UnnamedParam"
        let nameString = NSString(string: paramName + ":")
        
        // Draw parameter name
        nameString.draw(at: CGPoint(x: labelX, y: yPosition),
                        withAttributes: [
                            NSAttributedString.Key.font: font,
                            NSAttributedString.Key.foregroundColor: UIColor.darkGray
                        ])
        
        // Value
        let valText = param.value ?? "--"
        let valColor = param.isAbnormal ? accentColor : UIColor.black
        let valString = NSString(string: valText)
        valString.draw(at: CGPoint(x: valueX, y: yPosition),
                       withAttributes: [
                           NSAttributedString.Key.font: font,
                           NSAttributedString.Key.foregroundColor: valColor
                       ])
        
        // “ABNORMAL” if needed
        if param.isAbnormal {
            let abStr = NSString(string: "ABNORMAL")
            abStr.draw(at: CGPoint(x: valueX + 100, y: yPosition),
                       withAttributes: [
                           NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize - 1),
                           NSAttributedString.Key.foregroundColor: accentColor
                       ])
        }
        
        yPosition += 14
        
        // Reference Range
        if let low = param.referenceRangeLow as Double?,
           let high = param.referenceRangeHigh as Double? {
            let refUnit = param.unit ?? ""
            let refText = "(Ref: \(low)-\(high) \(refUnit))"
            let refString = NSString(string: refText)
            refString.draw(at: CGPoint(x: valueX, y: yPosition),
                           withAttributes: [
                               NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: font.pointSize - 1),
                               NSAttributedString.Key.foregroundColor: UIColor.gray
                           ])
            yPosition += 12
        }
        
        // Notes
        if let notes = param.notes, !notes.isEmpty {
            // Draw “Notes:” label
            let noteLabel = NSString(string: "Notes:")
            noteLabel.draw(at: CGPoint(x: labelX, y: yPosition),
                           withAttributes: [
                               NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: font.pointSize - 1),
                               NSAttributedString.Key.foregroundColor: UIColor.gray
                           ])
            yPosition += 12
            
            var localY = yPosition
            
            // Use your “drawWrappedText” (which should accept an NSAttributedString keys dict)
            _ = drawWrappedText(
                text: notes,
                font: UIFont.systemFont(ofSize: font.pointSize),
                x: labelX + 10,
                y: &localY,
                width: pageWidth - margin * 2 - 40,
                color: UIColor.darkGray
            )
            
            yPosition = localY + 4
        }
    }

    
    // MARK: - Utility & Layout Methods
    
    private func checkAndStartNewPageIfNeeded(context: UIGraphicsPDFRendererContext, neededHeight: CGFloat) {
        if yPosition + neededHeight > pageHeight - margin {
            drawPageFooter()
            context.beginPage()
            pageNumber += 1
            yPosition = margin
            drawDocumentHeader()
        }
    }
    
    private func calculateContentHeight() -> CGFloat {
        var total: CGFloat = 0
        
        // Header + patient info
        total += 200
        
        // Initial Presentation
        total += 150
        
        // Diagnoses
        total += 150
        
        // Treatment
        total += 200
        
        // Operative
        let ops = getPatientOperativeData()
        if !ops.isEmpty {
            total += CGFloat(ops.count) * 100 + 50
        }
        
        // Meds
        total += 200
        
        // Basic test results
        let testResults = getPatientTestResults()
        if !testResults.isEmpty {
            total += CGFloat(testResults.count) * 80 + 50
        }
        
        // Follow up
        total += 250
        
        // Checklist
        total += 150
        
        // Additional
        if let notes = dischargeSummary.additionalNotes, !notes.isEmpty {
            total += 100
        }
        
        // Signature
        total += 150
        
        // Addendum
        let paramCount = testResults.reduce(0) { $0 + ($1.testParameters?.count ?? 0) }
        if paramCount > 0 {
            total += CGFloat(paramCount) * 40 + 200
        }
        
        return total
    }
    
    private func drawPageFooter() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        let footerLineY = pageHeight - 50
        let footPath = UIBezierPath()
        footPath.move(to: CGPoint(x: margin, y: footerLineY))
        footPath.addLine(to: CGPoint(x: pageWidth - margin, y: footerLineY))
        UIColor.gray.withAlphaComponent(0.3).setStroke()
        footPath.stroke()
        
        // line1: hospital info
        let footerFont = UIFont.systemFont(ofSize: footerFontSize)
        let hospInfo = NSString(string: "\(hospitalName) • \(hospitalAddress) • \(departmentName)")
        hospInfo.draw(
            at: CGPoint(x: margin, y: footerLineY + 5),
            withAttributes: [
                NSAttributedString.Key.font: footerFont,
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
        )
        
        // line2: confidentiality
        let conf = NSString(string: "CONFIDENTIAL: This document contains PHI. Unauthorized disclosure prohibited.")
        conf.draw(
            at: CGPoint(x: margin, y: footerLineY + 15),
            withAttributes: [
                NSAttributedString.Key.font: footerFont,
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
        )
        
        // line3: page number
        let pageStr = NSString(string: "Page \(pageNumber) of \(totalPages)")
        pageStr.draw(
            at: CGPoint(x: margin, y: footerLineY + 25),
            withAttributes: [
                NSAttributedString.Key.font: footerFont,
                NSAttributedString.Key.foregroundColor: UIColor.gray
            ]
        )
        
        // generated line
        let genStr = NSString(string: "Generated by SurgiTrack Systems")
        let genAttr: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        let genSize = genStr.size(withAttributes: genAttr)
        let genX = pageWidth - margin - genSize.width
        
        genStr.draw(at: CGPoint(x: genX, y: footerLineY + 25), withAttributes: genAttr)
        
        context.restoreGState()
    }

    
    private func drawSeparator() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
        UIColor.gray.withAlphaComponent(0.5).setStroke()
        path.stroke()
        yPosition += 15
    }
    
    private func drawSectionTitle(_ title: String, font: UIFont, iconName: String) {
        let height: CGFloat = 25
        let rect = CGRect(x: margin, y: yPosition, width: pageWidth - margin*2, height: height)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        path.addClip()
        
        // Subtle gradient
        let c1 = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0).cgColor
        let c2 = UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1.0).cgColor
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [c1, c2] as CFArray, locations: [0.0, 1.0]) {
            context.drawLinearGradient(grad,
                                       start: CGPoint(x: rect.minX, y: rect.minY),
                                       end: CGPoint(x: rect.maxX, y: rect.maxY),
                                       options: [])
        }
        context.restoreGState()
        
        primaryColor.withAlphaComponent(0.5).setStroke()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).stroke()
        
        // Icon + text
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let icon = UIImage(systemName: iconName, withConfiguration: config) {
            icon.withTintColor(primaryColor).draw(in: CGRect(x: margin + 8, y: yPosition + 5, width: 14, height: 14))
            let tStr = title as NSString
            tStr.draw(
                at: CGPoint(x: margin + 30, y: yPosition + 5),
                withAttributes: [.font: font, .foregroundColor: primaryColor]
            )
        } else {
            let tStr = title as NSString
            tStr.draw(at: CGPoint(x: margin + 10, y: yPosition + 5),
                      withAttributes: [.font: font, .foregroundColor: primaryColor])
        }
        yPosition += height
    }
    
    private func drawBulletPoint(text: String, x: CGFloat, y: inout CGFloat, width: CGFloat, font: UIFont) {
        let bullet: NSString = "•"
        let bulletAttr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: primaryColor]
        bullet.draw(at: CGPoint(x: x - 10, y: y), withAttributes: bulletAttr)
        
        let textHeight = drawWrappedText(text: text, font: font, x: x, y: &y, width: width, color: UIColor.black)
        y += 5
    }
    
    private func drawInfoRow(label: String, value: String,
                             labelX: CGFloat, valueX: CGFloat, y: CGFloat,
                             labelFont: UIFont, valueFont: UIFont,
                             labelColor: UIColor = .darkGray, valueColor: UIColor = .darkGray) {
        let lbl = label as NSString
        lbl.draw(at: CGPoint(x: labelX, y: y),
                 withAttributes: [.font: labelFont, .foregroundColor: labelColor])
        
        let val = value as NSString
        val.draw(at: CGPoint(x: valueX, y: y),
                 withAttributes: [.font: valueFont, .foregroundColor: valueColor])
    }
    
    private func drawWrappedText(text: String, font: UIFont,
                                 x: CGFloat, y: inout CGFloat,
                                 width: CGFloat,
                                 color: UIColor = UIColor.black) -> CGFloat {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.lineSpacing = lineSpacing
        
        let attr: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: pStyle
        ]
        
        let boundingRect = CGRect(x: x, y: y, width: width, height: 1000)
        let textHeight = text.boundingRect(with: CGSize(width: width, height: 1000),
                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                           attributes: attr,
                                           context: nil).height
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: textHeight), withAttributes: attr)
        y += textHeight
        return textHeight
    }
    
    private func estimateTextHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.lineSpacing = lineSpacing
        
        let attr: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: pStyle]
        return text.boundingRect(with: CGSize(width: width, height: 1000),
                                 options: [.usesLineFragmentOrigin, .usesFontLeading],
                                 attributes: attr,
                                 context: nil).height
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let d = date else { return "Unknown" }
        return dateFormatter.string(from: d)
    }
    
    private func calculateLengthOfStay() -> Int {
        guard let patient = dischargeSummary.patient,
              let admit = patient.dateCreated,
              let disc = dischargeSummary.dischargeDate else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: admit, to: disc).day ?? 0
    }
    
    // MARK: - Data Fetch Helpers
    private func getPatientOperativeData() -> [OperativeData] {
        guard let patient = dischargeSummary.patient,
              let ops = patient.operativeData as? Set<OperativeData> else { return [] }
        return ops.sorted { ($0.operationDate ?? Date.distantPast) > ($1.operationDate ?? Date.distantPast) }
    }
    
    private func getPatientTestResults() -> [MedicalTest] {
        guard let patient = dischargeSummary.patient,
              let allTests = patient.medicalTests as? Set<MedicalTest> else { return [] }
        
        let cal = Calendar.current
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: Date()) ?? Date.distantPast
        let recent = allTests.filter { ($0.testDate ?? Date.distantPast) >= threeMonthsAgo }
        return recent.sorted { ($0.testDate ?? Date.distantPast) > ($1.testDate ?? Date.distantPast) }
    }
}

