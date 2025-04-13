import SwiftUI

// MARK: - Form Template
struct ModernFormTemplate<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding()
        }
    }
}

// MARK: - Form Section
struct ModernFormSection<Content: View>: View {
    let title: String?
    let content: Content
    
    @Environment(\.themeColors) private var colors
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colors.text)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
        }
    }
}

// MARK: - Form Field
struct ModernFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String?
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isRequired: Bool
    let errorMessage: String?
    let isMultiline: Bool
    
    @Environment(\.themeColors) private var colors
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        isMultiline: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        _text = text // Use underscore for Binding
        self.icon = icon
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Use ModernTextField component
            ModernTextField(
                title: title,
                placeholder: placeholder,
                text: $text, // Pass the binding
                icon: icon,
                keyboardType: keyboardType,
                textContentType: textContentType,
                isRequired: isRequired,
                errorMessage: errorMessage
            )
            // Add multiline support if needed (could enhance ModernTextField later)
            // For now, ModernTextField handles single line.
        }
    }
}

// MARK: - Form Date Picker
struct ModernFormDatePicker: View {
    let title: String
    @Binding var selection: Date
    let displayedComponents: DatePickerComponents
    let isRequired: Bool
    
    @Environment(\.themeColors) private var colors
    
    init(
        title: String,
        selection: Binding<Date>,
        displayedComponents: DatePickerComponents = [.date],
        isRequired: Bool = false
    ) {
        self.title = title
        _selection = selection
        self.displayedComponents = displayedComponents
        self.isRequired = isRequired
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                if isRequired {
                    Text("*").foregroundColor(.red)
                }
            }
            DatePicker(
                "",
                selection: $selection,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
            .foregroundColor(colors.text)
            .accentColor(colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Form Picker
struct ModernFormPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let content: Content
    let isRequired: Bool
    
    @Environment(\.themeColors) private var colors
    
    init(
        title: String,
        selection: Binding<SelectionValue>,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        _selection = selection
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                if isRequired {
                    Text("*").foregroundColor(.red)
                }
            }
            Picker("", selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .foregroundColor(colors.text)
            .accentColor(colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ModernFormTemplate() {
            ModernFormSection(title: "Personal Information") {
                ModernFormField(
                    title: "First Name",
                    text: .constant("John")
                )
                ModernFormField(
                    title: "Last Name",
                    text: .constant("Doe")
                )
                ModernFormDatePicker(
                    title: "Date of Birth",
                    selection: .constant(Date())
                )
            }
            
            ModernFormSection {
                ModernButton("Save Patient", style: .primary) {
                    // Save action
                }
            }
        }
        .navigationTitle("Add Patient")
        .navigationBarTitleDisplayMode(.inline)
        .withThemeBridge(appState: AppState(), colorScheme: .light)
    }
} 