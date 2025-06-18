import SwiftUI

struct HistoryView: View {
    @StateObject private var trackingManager = DailyTrackingManager()
    @State private var allDays: [String] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allDays.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start tracking your meals to see them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(allDays, id: \.self) { dateString in
                            NavigationLink(destination: DayDetailView(date: dateString)) {
                                DayRowView(dateString: dateString)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAllDays()
        }
    }
    
    private func loadAllDays() {
        isLoading = true
        Task {
            let days = await trackingManager.getAllDays()
            await MainActor.run {
                self.allDays = days
                self.isLoading = false
            }
        }
    }
}

struct DayRowView: View {
    let dateString: String
    
    private var formattedDate: String {
        guard let date = DailyTrackingManager.parseDate(dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        let today = DailyTrackingManager.formatDate(Date())
        return dateString == today
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.body)
                    .fontWeight(.medium)
                
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DayDetailView: View {
    let date: String
    @StateObject private var trackingManager = DailyTrackingManager()
    @State private var flippedMealIndices: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var mealToDelete: StoredMealData?
    
    private var formattedDate: String {
        guard let dateObj = DailyTrackingManager.parseDate(date) else {
            return date
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: dateObj)
    }
    
    private var isToday: Bool {
        let today = DailyTrackingManager.formatDate(Date())
        return date == today
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Today's Data Section
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(isToday ? "Today's Data" : formattedDate)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if !isToday {
                            Text(date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Macro Numbers - 2 Column Grid Layout
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 2), spacing: 8) {
                        HistoryMacroCard(title: "Calories", consumed: trackingManager.currentDayData.caloriesConsumed, goal: 2000, unit: "cal", color: .orange)
                        HistoryMacroCard(title: "Protein", consumed: trackingManager.currentDayData.proteinConsumed, goal: 150, unit: "g", color: .red)
                        HistoryMacroCard(title: "Carbs", consumed: trackingManager.currentDayData.carbsConsumed, goal: 200, unit: "g", color: .blue)
                        HistoryMacroCard(title: "Fat", consumed: trackingManager.currentDayData.fatConsumed, goal: 65, unit: "g", color: .green)
                        HistoryMacroCard(title: "Fiber", consumed: trackingManager.currentDayData.fiberConsumed, goal: 25, unit: "g", color: .brown)
                        HistoryMacroCard(title: "Sugar", consumed: trackingManager.currentDayData.sugarConsumed, goal: 50, unit: "g", color: .pink)
                        HistoryMacroCard(title: "Sodium", consumed: trackingManager.currentDayData.sodiumConsumed, goal: 2300, unit: "mg", color: .purple)
                        HistoryMacroCard(title: "Vitamins", consumed: trackingManager.currentDayData.vitaminsConsumed, goal: 100, unit: "%", color: .cyan)
                    }
                }
                .padding(.horizontal, 12)
                
                // Meals History Section
                if !trackingManager.currentDayData.analyzedMeals.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Meals")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        ForEach(trackingManager.currentDayData.analyzedMeals) { meal in
                            HistoryMealCard(
                                meal: meal,
                                isFlipped: flippedMealIndices.contains(meal.id),
                                onDelete: isToday ? {
                                    mealToDelete = meal
                                    showingDeleteConfirmation = true
                                } : nil,
                                onPhotoTap: meal.hasPhoto ? {
                                    if flippedMealIndices.contains(meal.id) {
                                        flippedMealIndices.remove(meal.id)
                                    } else {
                                        flippedMealIndices.insert(meal.id)
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
        .navigationTitle(isToday ? "Today" : "History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            trackingManager.loadDataForDate(date)
        }
        .alert("Delete Meal", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    trackingManager.removeMeal(meal.id)
                    mealToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this meal? This will remove its macros from your daily total.")
        }
    }
}

struct HistoryMacroCard: View {
    let title: String
    let consumed: Double
    let goal: Double
    let unit: String
    let color: Color
    
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
                
                Text("/ \(Int(goal)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

struct HistoryMealCard: View {
    let meal: StoredMealData
    let isFlipped: Bool
    let onDelete: (() -> Void)?
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
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
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

#Preview {
    HistoryView()
} 