import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

struct DailyTrackingData: Codable {
    let date: String // Format: "YYYY-MM-DD"
    var caloriesConsumed: Double
    var proteinConsumed: Double
    var carbsConsumed: Double
    var fatConsumed: Double
    var fiberConsumed: Double
    var sugarConsumed: Double
    var sodiumConsumed: Double
    var vitaminsConsumed: Double
    var analyzedMeals: [StoredMealData]
    var createdAt: Timestamp
    var updatedAt: Timestamp
    
    init(date: String) {
        self.date = date
        self.caloriesConsumed = 0
        self.proteinConsumed = 0
        self.carbsConsumed = 0
        self.fatConsumed = 0
        self.fiberConsumed = 0
        self.sugarConsumed = 0
        self.sodiumConsumed = 0
        self.vitaminsConsumed = 0
        self.analyzedMeals = []
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
}

struct StoredMealData: Codable, Identifiable {
    let id: String
    let mealName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let description: String
    let hasPhoto: Bool
    let photoURL: String? // Will store Firebase Storage URL if photo exists
    let createdAt: Timestamp
    
    init(from meal: MealAnalysisResult, hasPhoto: Bool = false, photoURL: String? = nil) {
        self.id = UUID().uuidString
        self.mealName = meal.mealName
        self.calories = meal.calories
        self.protein = meal.protein
        self.carbs = meal.carbs
        self.fat = meal.fat
        self.fiber = meal.fiber
        self.sugar = meal.sugar
        self.sodium = meal.sodium
        self.description = meal.description
        self.hasPhoto = hasPhoto
        self.photoURL = photoURL
        self.createdAt = Timestamp()
    }
    
    func toMealAnalysisResult() -> MealAnalysisResult {
        return MealAnalysisResult(
            mealName: mealName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            description: description
        )
    }
}

@MainActor
class DailyTrackingManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentDayData: DailyTrackingData
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        let today = Self.formatDate(Date())
        self.currentDayData = DailyTrackingData(date: today)
        loadTodaysData()
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func loadTodaysData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let today = Self.formatDate(Date())
        loadDataForDate(today)
    }
    
    func loadDataForDate(_ date: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        Task {
            do {
                let document = try await db.collection("users").document(userId)
                    .collection("dailyTracking").document(date).getDocument()
                
                if document.exists, let data = try? document.data(as: DailyTrackingData.self) {
                    self.currentDayData = data
                } else {
                    // Create new day data
                    self.currentDayData = DailyTrackingData(date: date)
                }
            } catch {
                print("❌ Error loading daily data: \(error)")
                self.errorMessage = "Failed to load daily data"
                self.currentDayData = DailyTrackingData(date: date)
            }
            
            self.isLoading = false
        }
    }
    
    func saveTodaysData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        currentDayData.updatedAt = Timestamp()
        
        Task {
            do {
                try db.collection("users").document(userId)
                    .collection("dailyTracking").document(currentDayData.date)
                    .setData(from: currentDayData)
                print("✅ Daily data saved successfully")
            } catch {
                print("❌ Error saving daily data: \(error)")
                self.errorMessage = "Failed to save daily data"
            }
        }
    }
    
    func addMeal(_ meal: MealAnalysisResult, hasPhoto: Bool = false, photoURL: String? = nil) {
        let storedMeal = StoredMealData(from: meal, hasPhoto: hasPhoto, photoURL: photoURL)
        currentDayData.analyzedMeals.append(storedMeal)
        
        // Add to macro totals
        currentDayData.caloriesConsumed += meal.calories
        currentDayData.proteinConsumed += meal.protein
        currentDayData.carbsConsumed += meal.carbs
        currentDayData.fatConsumed += meal.fat
        currentDayData.fiberConsumed += meal.fiber
        currentDayData.sugarConsumed += meal.sugar
        currentDayData.sodiumConsumed += meal.sodium
        
        saveTodaysData()
    }
    
    func removeMeal(_ mealId: String) {
        guard let mealIndex = currentDayData.analyzedMeals.firstIndex(where: { $0.id == mealId }) else { return }
        
        let meal = currentDayData.analyzedMeals[mealIndex]
        
        // Subtract from macro totals
        currentDayData.caloriesConsumed = max(0, currentDayData.caloriesConsumed - meal.calories)
        currentDayData.proteinConsumed = max(0, currentDayData.proteinConsumed - meal.protein)
        currentDayData.carbsConsumed = max(0, currentDayData.carbsConsumed - meal.carbs)
        currentDayData.fatConsumed = max(0, currentDayData.fatConsumed - meal.fat)
        currentDayData.fiberConsumed = max(0, currentDayData.fiberConsumed - meal.fiber)
        currentDayData.sugarConsumed = max(0, currentDayData.sugarConsumed - meal.sugar)
        currentDayData.sodiumConsumed = max(0, currentDayData.sodiumConsumed - meal.sodium)
        
        currentDayData.analyzedMeals.remove(at: mealIndex)
        saveTodaysData()
    }
    
    func getAllDays() async -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("dailyTracking").getDocuments()
            
            let dates = snapshot.documents.compactMap { doc -> String? in
                return doc.documentID
            }.sorted(by: >) // Most recent first
            
            return dates
        } catch {
            print("❌ Error fetching all days: \(error)")
            return []
        }
    }
} 