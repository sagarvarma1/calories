import SwiftUI

struct MealAnalysisResult {
    let mealName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let description: String
}

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
    @State private var selectedImage: UIImage?
    @State private var currentMealDescription: String = ""
    @State private var analyzedMealData: MealAnalysisResult?
    @State private var isAnalyzing: Bool = false
    @State private var lastAddedMeal: MealAnalysisResult?
    @State private var analyzedPhotos: [(UIImage, MealAnalysisResult)] = []
    @State private var analyzedTextMeals: [MealAnalysisResult] = []
    @State private var acceptProgress: Double = 0.0
    @State private var acceptTimer: Timer?
    @State private var flippedPhotoIndices: Set<Int> = []
    @State private var showingDeleteConfirmation = false
    @State private var mealToDelete: (index: Int, meal: MealAnalysisResult, isPhoto: Bool)?
    
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
                    // Dynamic Upload Photo/Description Section
                    VStack(spacing: 0) {
                        if let analyzedMeal = analyzedMealData {
                            // Display Analyzed Meal Mode - Accept/Delete interface
                            VStack(spacing: 20) {
                                // Meal Name
                                Text(analyzedMeal.mealName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                // Macro List
                                VStack(spacing: 8) {
                                    MacroRow(title: "Calories", value: Int(analyzedMeal.calories), unit: "cal", color: .orange)
                                    MacroRow(title: "Protein", value: Int(analyzedMeal.protein), unit: "g", color: .red)
                                    MacroRow(title: "Carbs", value: Int(analyzedMeal.carbs), unit: "g", color: .blue)
                                    MacroRow(title: "Fat", value: Int(analyzedMeal.fat), unit: "g", color: .green)
                                    MacroRow(title: "Fiber", value: Int(analyzedMeal.fiber), unit: "g", color: .brown)
                                    MacroRow(title: "Sugar", value: Int(analyzedMeal.sugar), unit: "g", color: .pink)
                                    MacroRow(title: "Sodium", value: Int(analyzedMeal.sodium), unit: "mg", color: .purple)
                                }
                                
                                // Accept/Delete Buttons
                                HStack(spacing: 16) {
                                    // Delete Button
                                    Button(action: {
                                        deleteMeal()
                                    }) {
                                        Text("Delete")
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                    
                                    // Accept Button with Progress
                                    Button(action: {
                                        acceptMeal()
                                    }) {
                                        ZStack {
                                            // Background
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.green)
                                                .frame(maxWidth: .infinity)
                                            
                                            // Progress overlay
                                            GeometryReader { geometry in
                                                HStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.black.opacity(0.4))
                                                        .frame(width: geometry.size.width * acceptProgress)
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                            
                                            Text("Accept")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        .frame(height: 50)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.top)
                            .onAppear {
                                startAcceptTimer()
                            }
                            .onDisappear {
                                stopAcceptTimer()
                            }
                        } else if isAnalyzing {
                            // Display Analysis Loading Mode
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analyzing your meal...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.top)
                        } else if let selectedImage = selectedImage {
                            // Display Photo Mode
                            VStack(spacing: 16) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipped()
                                        .cornerRadius(16)
                                    
                                    // X button to clear photo
                                    Button(action: {
                                        self.selectedImage = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .padding(12)
                                }
                                
                                // Analyze Button
                                Button(action: {
                                    analyzePhoto()
                                }) {
                                    HStack {
                                        Image(systemName: "camera.viewfinder")
                                            .font(.system(size: 16))
                                        Text("Analyze Photo")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        } else if !currentMealDescription.isEmpty {
                            // Display Description Mode
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Meal Description")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // X button to clear description
                                    Button(action: {
                                        currentMealDescription = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Text(currentMealDescription)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // Analyze Button for Text
                                Button(action: {
                                    analyzeText()
                                }) {
                                    HStack {
                                        Image(systemName: "text.magnifyingglass")
                                            .font(.system(size: 16))
                                        Text("Analyze Meal")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        } else {
                            // Default Two Button Mode
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
                        }
                    }
                    
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
                                color: .orange,
                                lastAdded: lastAddedMeal?.calories
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
                                color: .red,
                                lastAdded: lastAddedMeal?.protein
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
                                color: .blue,
                                lastAdded: lastAddedMeal?.carbs
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
                                color: .green,
                                lastAdded: lastAddedMeal?.fat
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
                                color: .brown,
                                lastAdded: lastAddedMeal?.fiber
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
                                color: .pink,
                                lastAdded: lastAddedMeal?.sugar
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
                                color: .purple,
                                lastAdded: lastAddedMeal?.sodium
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
                                color: .cyan,
                                lastAdded: nil
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
                    
                    // Analyzed Meals History Section
                    if !analyzedPhotos.isEmpty || !analyzedTextMeals.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Today's Meals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Analyzed Photos
                            ForEach(Array(analyzedPhotos.enumerated()), id: \.offset) { index, photoMeal in
                                AnalyzedMealCard(
                                    image: photoMeal.0,
                                    meal: photoMeal.1,
                                    isFlipped: flippedPhotoIndices.contains(index),
                                    onDelete: {
                                        mealToDelete = (index: index, meal: photoMeal.1, isPhoto: true)
                                        showingDeleteConfirmation = true
                                    },
                                    onPhotoTap: {
                                        if flippedPhotoIndices.contains(index) {
                                            flippedPhotoIndices.remove(index)
                                        } else {
                                            flippedPhotoIndices.insert(index)
                                        }
                                    }
                                )
                            }
                            
                            // Analyzed Text Meals
                            ForEach(Array(analyzedTextMeals.enumerated()), id: \.offset) { index, meal in
                                AnalyzedMealCard(
                                    image: nil,
                                    meal: meal,
                                    isFlipped: true, // Always show macro info for text meals
                                    onDelete: {
                                        mealToDelete = (index: index, meal: meal, isPhoto: false)
                                        showingDeleteConfirmation = true
                                    },
                                    onPhotoTap: { } // No photo to tap
                                )
                            }
                        }
                        .padding(.top, 20)
                    }
                    
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
                ImagePicker(sourceType: imageSourceType, selectedImage: $selectedImage)
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
                MealDescriptionView(mealDescription: $mealDescriptionText, currentMealDescription: $currentMealDescription)
            }
            .alert("Delete Meal", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    mealToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    confirmDeleteMeal()
                }
            } message: {
                Text("Are you sure you want to delete this meal? This will remove its macros from your daily total.")
            }
        }
    }
    
    private func addMacros(calories: Double, protein: Double, carbs: Double, fat: Double) {
        caloriesConsumed += calories
        proteinConsumed += protein
        carbsConsumed += carbs
        fatConsumed += fat
    }
    
    private func analyzePhoto() {
        isAnalyzing = true
        
        // Simulate AI analysis delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Mock analysis result - replace with actual AI API call
            let mockResult = MealAnalysisResult(
                mealName: "Grilled Chicken Salad",
                calories: 350,
                protein: 35,
                carbs: 12,
                fat: 18,
                fiber: 8,
                sugar: 6,
                sodium: 420,
                description: "A healthy grilled chicken breast over mixed greens with vegetables and light dressing."
            )
            
            self.analyzedMealData = mockResult
            self.lastAddedMeal = mockResult  // Show "+ X added" during accept phase
            self.isAnalyzing = false
        }
    }
    
    private func analyzeText() {
        isAnalyzing = true
        
        // Simulate AI analysis delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Mock analysis result based on text - replace with actual AI API call
            let mockResult = MealAnalysisResult(
                mealName: "Mixed Bowl Meal",
                calories: 280,
                protein: 22,
                carbs: 25,
                fat: 12,
                fiber: 5,
                sugar: 8,
                sodium: 350,
                description: currentMealDescription
            )
            
            self.analyzedMealData = mockResult
            self.lastAddedMeal = mockResult  // Show "+ X added" during accept phase
            self.isAnalyzing = false
        }
    }
    
    private func startAcceptTimer() {
        acceptProgress = 0.0
        acceptTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            acceptProgress += 0.00667 // Increment to reach 1.0 in 15 seconds (1.0 / 150 intervals)
            
            if acceptProgress >= 1.0 {
                acceptMeal()
            }
        }
    }
    
    private func stopAcceptTimer() {
        acceptTimer?.invalidate()
        acceptTimer = nil
        acceptProgress = 0.0
    }
    
    private func acceptMeal() {
        guard let meal = analyzedMealData else { return }
        
        stopAcceptTimer()
        
        // Add to daily tracking
        addMacros(
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat
        )
        fiberConsumed += meal.fiber
        sugarConsumed += meal.sugar
        sodiumConsumed += meal.sodium
        
        // Save to history
        if let image = selectedImage {
            analyzedPhotos.append((image, meal))
        } else {
            analyzedTextMeals.append(meal)
        }
        
        // Reset state and clear "added" display immediately
        analyzedMealData = nil
        selectedImage = nil
        currentMealDescription = ""
        lastAddedMeal = nil  // Immediately revert to "/ X goal" format
    }
    
    private func deleteMeal() {
        stopAcceptTimer()
        analyzedMealData = nil
        selectedImage = nil
        currentMealDescription = ""
        lastAddedMeal = nil  // Clear "added" display when deleting
    }
    
    private func confirmDeleteMeal() {
        guard let mealToDelete = mealToDelete else { return }
        
        let meal = mealToDelete.meal
        let index = mealToDelete.index
        let isPhoto = mealToDelete.isPhoto
        
        // Subtract macros from daily total
        subtractMacros(
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat
        )
        fiberConsumed = max(0, fiberConsumed - meal.fiber)
        sugarConsumed = max(0, sugarConsumed - meal.sugar)
        sodiumConsumed = max(0, sodiumConsumed - meal.sodium)
        
        // Remove from appropriate array
        if isPhoto {
            analyzedPhotos.remove(at: index)
            flippedPhotoIndices.remove(index)
        } else {
            analyzedTextMeals.remove(at: index)
        }
        
        // Clear selection
        self.mealToDelete = nil
    }
    
    private func subtractMacros(calories: Double, protein: Double, carbs: Double, fat: Double) {
        caloriesConsumed = max(0, caloriesConsumed - calories)
        proteinConsumed = max(0, proteinConsumed - protein)
        carbsConsumed = max(0, carbsConsumed - carbs)
        fatConsumed = max(0, fatConsumed - fat)
    }
}

struct AnalyzedMealCard: View {
    let image: UIImage?
    let meal: MealAnalysisResult
    let isFlipped: Bool
    let onDelete: () -> Void
    let onPhotoTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with meal name and delete button
            HStack {
                Text(meal.mealName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
            
            // Photo or Macro List (flippable for photos)
            if let image = image {
                if isFlipped {
                    // Show Macro List
                    VStack(spacing: 8) {
                        MacroRow(title: "Calories", value: Int(meal.calories), unit: "cal", color: .orange)
                        MacroRow(title: "Protein", value: Int(meal.protein), unit: "g", color: .red)
                        MacroRow(title: "Carbs", value: Int(meal.carbs), unit: "g", color: .blue)
                        MacroRow(title: "Fat", value: Int(meal.fat), unit: "g", color: .green)
                        MacroRow(title: "Fiber", value: Int(meal.fiber), unit: "g", color: .brown)
                        MacroRow(title: "Sugar", value: Int(meal.sugar), unit: "g", color: .pink)
                        MacroRow(title: "Sodium", value: Int(meal.sodium), unit: "mg", color: .purple)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .onTapGesture {
                        onPhotoTap()
                    }
                } else {
                    // Show Photo
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        .onTapGesture {
                            onPhotoTap()
                        }
                }
            } else {
                // Text meals always show macro list
                VStack(spacing: 8) {
                    MacroRow(title: "Calories", value: Int(meal.calories), unit: "cal", color: .orange)
                    MacroRow(title: "Protein", value: Int(meal.protein), unit: "g", color: .red)
                    MacroRow(title: "Carbs", value: Int(meal.carbs), unit: "g", color: .blue)
                    MacroRow(title: "Fat", value: Int(meal.fat), unit: "g", color: .green)
                    MacroRow(title: "Fiber", value: Int(meal.fiber), unit: "g", color: .brown)
                    MacroRow(title: "Sugar", value: Int(meal.sugar), unit: "g", color: .pink)
                    MacroRow(title: "Sodium", value: Int(meal.sodium), unit: "mg", color: .purple)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct MacroRow: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
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
    let lastAdded: Double?
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
                    
                    if let lastAdded = lastAdded {
                        Text("+ \(Int(lastAdded)) \(unit) added")
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                    Text("/ \(Int(goal)) \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }
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
    @Binding var selectedImage: UIImage?
    
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
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
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
    @Binding var currentMealDescription: String
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
                        currentMealDescription = tempDescription
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
                        currentMealDescription = tempDescription
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