import SwiftUI
import UIKit
import FirebaseAuth

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
    @ObservedObject var userProfile: UserProfile
    @StateObject private var trackingManager = DailyTrackingManager()
    @State private var uploadedImage: UIImage?
    @State private var writtenDescription: String = ""
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var isAnalyzing = false
    @State private var currentAnalysis: MealAnalysisResult?
    @State private var showingAcceptDeleteView = false
    @State private var lastAddedMeal: MealAnalysisResult?
    @State private var autoAcceptTimer: Timer?
    @State private var acceptTimerProgress: CGFloat = 0
    @State private var flippedPhotoMealIndices: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var mealToDelete: StoredMealData?
    @State private var showingHistory = false
    @State private var showingMealDescription = false
    @State private var currentMealDescription: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Dynamic Upload Photo/Description Section
                    VStack(spacing: 0) {
                        if let analyzedMeal = currentAnalysis {
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
                                                        .frame(width: geometry.size.width * acceptTimerProgress)
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
                                startAutoAcceptTimer()
                            }
                            .onDisappear {
                                stopAutoAcceptTimer()
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
                        } else if let selectedImage = uploadedImage {
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
                                        self.uploadedImage = nil
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
                                    analyzeDescription()
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
                            MacroCard(title: "Calories", consumed: trackingManager.currentDayData.caloriesConsumed, goal: userProfile.calorieGoal, unit: "cal", color: .orange, lastAdded: lastAddedMeal?.calories)
                            MacroCard(title: "Protein", consumed: trackingManager.currentDayData.proteinConsumed, goal: userProfile.proteinGoal, unit: "g", color: .red, lastAdded: lastAddedMeal?.protein)
                            MacroCard(title: "Carbs", consumed: trackingManager.currentDayData.carbsConsumed, goal: userProfile.carbGoal, unit: "g", color: .blue, lastAdded: lastAddedMeal?.carbs)
                            MacroCard(title: "Fat", consumed: trackingManager.currentDayData.fatConsumed, goal: userProfile.fatGoal, unit: "g", color: .green, lastAdded: lastAddedMeal?.fat)
                            MacroCard(title: "Fiber", consumed: trackingManager.currentDayData.fiberConsumed, goal: 25, unit: "g", color: .brown, lastAdded: lastAddedMeal?.fiber)
                            MacroCard(title: "Sugar", consumed: trackingManager.currentDayData.sugarConsumed, goal: 50, unit: "g", color: .pink, lastAdded: lastAddedMeal?.sugar)
                            MacroCard(title: "Sodium", consumed: trackingManager.currentDayData.sodiumConsumed, goal: 2300, unit: "mg", color: .purple, lastAdded: lastAddedMeal?.sodium)
                            MacroCard(title: "Vitamins", consumed: trackingManager.currentDayData.vitaminsConsumed, goal: 100, unit: "%", color: .cyan, lastAdded: nil)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    // Today's Meals Section
                    if !trackingManager.currentDayData.analyzedMeals.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Today's Meals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(trackingManager.currentDayData.analyzedMeals) { meal in
                                TodayMealCard(
                                    meal: meal,
                                    isFlipped: flippedPhotoMealIndices.contains(meal.id),
                                    onDelete: {
                                        mealToDelete = meal
                                        showingDeleteConfirmation = true
                                    },
                                    onPhotoTap: meal.hasPhoto ? {
                                        if flippedPhotoMealIndices.contains(meal.id) {
                                            flippedPhotoMealIndices.remove(meal.id)
                                        } else {
                                            flippedPhotoMealIndices.insert(meal.id)
                                        }
                                    } : nil
                                )
                        }
                    }
                        .padding(.top, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Macro Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        signOut()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save data when app goes to background
            trackingManager.saveTodaysData()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imagePickerSourceType, selectedImage: $uploadedImage)
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingImageSourcePicker) {
                Button("Take Photo") {
                imagePickerSourceType = .camera
                    showingImagePicker = true
                }
                Button("Choose from Library") {
                imagePickerSourceType = .photoLibrary
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        .sheet(isPresented: $showingMealDescription) {
            MealDescriptionView(mealDescription: $writtenDescription, currentMealDescription: $currentMealDescription)
            }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .alert("Delete Meal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    trackingManager.removeMeal(meal.id)
                    mealToDelete = nil
                    
                    // Clear last added meal if it was the one being deleted
                    if let lastMeal = lastAddedMeal,
                       lastMeal.mealName == meal.mealName {
                        clearLastAddedMeal()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this meal? This will remove its macros from your daily total.")
        }
        .onAppear {
            startAutoAcceptTimerIfNeeded()
        }
    }
    
    private func analyzePhoto() {
        isAnalyzing = true
        
        // Simulate analysis (replace with real API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let mockAnalysis = MealAnalysisResult(
                mealName: "Grilled Chicken Salad",
                calories: 350,
                protein: 35,
                carbs: 12,
                fat: 18,
                fiber: 8,
                sugar: 6,
                sodium: 450,
                description: "A healthy grilled chicken breast served over mixed greens with tomatoes and cucumber"
            )
            
            currentAnalysis = mockAnalysis
            isAnalyzing = false
        }
    }
    
    private func analyzeDescription() {
        isAnalyzing = true
        
        // Simulate analysis (replace with real API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let mockAnalysis = MealAnalysisResult(
                mealName: "Pasta with Marinara",
                calories: 420,
                protein: 12,
                carbs: 75,
                fat: 8,
                fiber: 4,
                sugar: 12,
                sodium: 680,
                description: currentMealDescription
            )
            
            currentAnalysis = mockAnalysis
            isAnalyzing = false
        }
    }
    
    private func acceptMeal() {
        guard let analysis = currentAnalysis else { return }
        
        // Add meal to tracking manager
        let hasPhoto = uploadedImage != nil
        trackingManager.addMeal(analysis, hasPhoto: hasPhoto)
        
        // Set last added meal for preview display
        lastAddedMeal = analysis
        
        // Clear temporary preview after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            clearLastAddedMeal()
}

        // Clean up
        resetToDefaultState()
        stopAutoAcceptTimer()
    }
    
    private func deleteMeal() {
        resetToDefaultState()
        stopAutoAcceptTimer()
    }
    
    private func resetToDefaultState() {
        uploadedImage = nil
        writtenDescription = ""
        currentAnalysis = nil
        currentMealDescription = ""
        showingAcceptDeleteView = false
        isAnalyzing = false
    }
    
    private func clearLastAddedMeal() {
        lastAddedMeal = nil
    }
    
    private func startAutoAcceptTimer() {
        stopAutoAcceptTimer()
        acceptTimerProgress = 0
        
        autoAcceptTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            acceptTimerProgress += 0.1 / 15.0 // 15 seconds total
            
            if acceptTimerProgress >= 1.0 {
                acceptMeal()
    }
        }
    }
    
    private func stopAutoAcceptTimer() {
        autoAcceptTimer?.invalidate()
        autoAcceptTimer = nil
        acceptTimerProgress = 0
    }
    
    private func startAutoAcceptTimerIfNeeded() {
        if currentAnalysis != nil {
            startAutoAcceptTimer()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// Add the missing MealDescriptionView
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
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(tempDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TodayMealCard: View {
    let meal: StoredMealData
    let isFlipped: Bool
    let onDelete: () -> Void
    let onPhotoTap: (() -> Void)?
    
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
            
            // Photo placeholder or Macro List (flippable for photos)
            if meal.hasPhoto {
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
                        onPhotoTap?()
                    }
                } else {
                    // Show Photo Placeholder (in real app, would load from Firebase Storage)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                Text("Photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .onTapGesture {
                            onPhotoTap?()
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

struct MacroCard: View {
    let title: String
    let consumed: Double
    let goal: Double
    let unit: String
    let color: Color
    let lastAdded: Double?
    
    var body: some View {
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
                
                if let added = lastAdded, added > 0 {
                    Text("+ \(Int(added)) added")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
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
        }
        .frame(height: 75)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

struct MacroRow: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    MacroTrackingView(userProfile: UserProfile())
} 