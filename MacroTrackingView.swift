import SwiftUI

struct MacroTrackingView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var caloriesConsumed: Double = 0
    @State private var proteinConsumed: Double = 0
    @State private var carbsConsumed: Double = 0
    @State private var fatConsumed: Double = 0
    @State private var fiberConsumed: Double = 0
    @State private var sugarConsumed: Double = 0
    @State private var sodiumConsumed: Double = 0
    @State private var vitaminsConsumed: Double = 0
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedMacro: MacroDetail?
    @State private var showingMacroDetail = false
    @State private var showingMealDescription = false
    @State private var mealDescriptionText = ""
    
    // Daily goals (can be made customizable later)
    private let calorieGoal: Double = 2000
    private let proteinGoal: Double = 150
    private let carbGoal: Double = 200
    private let fatGoal: Double = 65
    private let fiberGoal: Double = 25
    private let sugarGoal: Double = 50
    private let sodiumGoal: Double = 2300
    private let vitaminsGoal: Double = 100
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Upload Photo Section
                    HStack(spacing: 12) {
                        // Upload Photo Button (Left Half)
                        Button(action: {
                            showingImageSourcePicker = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                                
                                Text("Upload Photo of Meal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                
                                Text("Take a photo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                            )
                        }
                        .frame(height: 140)
                        
                        // OR Separator
                        VStack {
                            Text("OR")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 30)
                        
                        // Describe Meal Button (Right Half)
                        Button(action: {
                            showingMealDescription = true
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                
                                Text("Describe Meal")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                
                                Text("Type what you ate")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                            )
                        }
                        .frame(height: 140)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Today's Data Section
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Today's Data")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(Date(), style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Macro Numbers - 2 Column Grid Layout
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 2), spacing: 8) {
                            SimpleMacroCard(
                                title: "Calories",
                                consumed: caloriesConsumed,
                                goal: calorieGoal,
                                unit: "cal",
                                color: .orange
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Calories",
                                    subcomponents: [
                                        ("From Carbs", carbsConsumed * 4, "cal"),
                                        ("From Protein", proteinConsumed * 4, "cal"),
                                        ("From Fat", fatConsumed * 9, "cal")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Protein",
                                consumed: proteinConsumed,
                                goal: proteinGoal,
                                unit: "g",
                                color: .red
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Protein",
                                    subcomponents: [
                                        ("Complete Protein", proteinConsumed * 0.7, "g"),
                                        ("Incomplete Protein", proteinConsumed * 0.3, "g"),
                                        ("Essential Amino Acids", proteinConsumed * 0.4, "g")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Carbs",
                                consumed: carbsConsumed,
                                goal: carbGoal,
                                unit: "g",
                                color: .blue
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Carbohydrates",
                                    subcomponents: [
                                        ("Total Sugar", sugarConsumed, "g"),
                                        ("  • Sucrose", sugarConsumed * 0.4, "g"),
                                        ("  • Fructose", sugarConsumed * 0.3, "g"),
                                        ("  • Glucose", sugarConsumed * 0.3, "g"),
                                        ("Fiber", fiberConsumed, "g"),
                                        ("Starch", carbsConsumed - sugarConsumed - fiberConsumed, "g")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Fat",
                                consumed: fatConsumed,
                                goal: fatGoal,
                                unit: "g",
                                color: .green
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Fats",
                                    subcomponents: [
                                        ("Saturated Fat", fatConsumed * 0.3, "g"),
                                        ("Monounsaturated Fat", fatConsumed * 0.4, "g"),
                                        ("Polyunsaturated Fat", fatConsumed * 0.2, "g"),
                                        ("Trans Fat", fatConsumed * 0.1, "g")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Fiber",
                                consumed: fiberConsumed,
                                goal: fiberGoal,
                                unit: "g",
                                color: .brown
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Fiber",
                                    subcomponents: [
                                        ("Soluble Fiber", fiberConsumed * 0.4, "g"),
                                        ("Insoluble Fiber", fiberConsumed * 0.6, "g")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Sugar",
                                consumed: sugarConsumed,
                                goal: sugarGoal,
                                unit: "g",
                                color: .pink
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Sugar",
                                    subcomponents: [
                                        ("Sucrose", sugarConsumed * 0.4, "g"),
                                        ("Fructose", sugarConsumed * 0.3, "g"),
                                        ("Glucose", sugarConsumed * 0.2, "g"),
                                        ("Lactose", sugarConsumed * 0.1, "g")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Sodium",
                                consumed: sodiumConsumed,
                                goal: sodiumGoal,
                                unit: "mg",
                                color: .purple
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Sodium",
                                    subcomponents: [
                                        ("Table Salt", sodiumConsumed * 0.6, "mg"),
                                        ("Natural Sources", sodiumConsumed * 0.2, "mg"),
                                        ("Processed Foods", sodiumConsumed * 0.2, "mg")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                            
                            SimpleMacroCard(
                                title: "Vitamins",
                                consumed: vitaminsConsumed,
                                goal: vitaminsGoal,
                                unit: "%",
                                color: .cyan
                            ) {
                                selectedMacro = MacroDetail(
                                    title: "Vitamins",
                                    subcomponents: [
                                        ("Vitamin A", vitaminsConsumed * 0.15, "% DV"),
                                        ("Vitamin C", vitaminsConsumed * 0.20, "% DV"),
                                        ("Vitamin D", vitaminsConsumed * 0.12, "% DV"),
                                        ("Vitamin E", vitaminsConsumed * 0.10, "% DV"),
                                        ("Vitamin K", vitaminsConsumed * 0.08, "% DV"),
                                        ("B-Complex", vitaminsConsumed * 0.25, "% DV"),
                                        ("  • B12", vitaminsConsumed * 0.08, "% DV"),
                                        ("  • Folate", vitaminsConsumed * 0.10, "% DV")
                                    ]
                                )
                                showingMacroDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .fullScreenCover(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: imageSourceType)
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingImageSourcePicker) {
                Button("Take Photo") {
                    imageSourceType = .camera
                    showingImagePicker = true
                }
                Button("Choose from Library") {
                    imageSourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingMacroDetail) {
                if let macro = selectedMacro {
                    MacroDetailView(macro: macro)
                }
            }
            .sheet(isPresented: $showingMealDescription) {
                MealDescriptionView(mealDescription: $mealDescriptionText)
            }
        }
    }
    
    private func addMacros(calories: Double, protein: Double, carbs: Double, fat: Double) {
        caloriesConsumed += calories
        proteinConsumed += protein
        carbsConsumed += carbs
        fatConsumed += fat
    }
}

struct MacroDetail {
    let title: String
    let subcomponents: [(String, Double, String)] // (name, amount, unit)
}

struct SimpleMacroCard: View {
    let title: String
    let consumed: Double
    let goal: Double
    let unit: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Macro Name on Top
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Numbers in Middle
                VStack(spacing: 3) {
                    Text("\(Int(consumed))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("/ \(Int(goal)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // Small chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.5)
            }
            .frame(height: 75)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
        .aspectRatio(1.0, contentMode: .fit)
    }
}

struct MacroDetailView: View {
    let macro: MacroDetail
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(macro.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Breakdown")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 12) {
                    ForEach(macro.subcomponents.indices, id: \.self) { index in
                        let component = macro.subcomponents[index]
                        HStack {
                            Text(component.0)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(component.1.formatted(.number.precision(.fractionLength(1)))) \(component.2)")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Fullscreen Camera without extra buttons
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        // Only set fullScreen for camera, photo library uses default presentation
        if sourceType == .camera {
            picker.modalPresentationStyle = .fullScreen
            picker.navigationBar.isHidden = true
            picker.toolbar.isHidden = true
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle the selected image here
            picker.dismiss(animated: true)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.dismiss()
        }
    }
}

struct MealDescriptionView: View {
    @Binding var mealDescription: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempDescription: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Describe Your Meal")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tell us what you ate and we'll estimate your macros")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $tempDescription)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onAppear {
                            tempDescription = mealDescription
                        }
                    
                    Text("Example: \"I had a grilled chicken breast with steamed broccoli and brown rice\"")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        mealDescription = tempDescription
                        // Here you would typically process the description and estimate macros
                        dismiss()
                    }) {
                        Text("Analyze Meal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(tempDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        mealDescription = tempDescription
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MacroTrackingView()
} 