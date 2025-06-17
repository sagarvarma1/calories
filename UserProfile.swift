import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserProfile: ObservableObject {
    @Published var goals: String = ""
    @Published var height: String = ""
    @Published var currentWeight: String = ""
    @Published var targetWeight: String = ""
    @Published var gender: Gender = .notSpecified
    @Published var hasCompletedOnboarding: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case notSpecified = "Not Specified"
        
        var displayName: String {
            switch self {
            case .male: return "M"
            case .female: return "F"
            case .notSpecified: return "Other"
            }
        }
    }
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if user != nil {
                    self?.loadUserProfile()
                } else {
                    // User signed out, reset profile data
                    self?.resetProfile()
                }
            }
        }
        
        // Load profile if user is already authenticated
        if Auth.auth().currentUser != nil {
            loadUserProfile()
        }
    }
    
    private func resetProfile() {
        goals = ""
        height = ""
        currentWeight = ""
        targetWeight = ""
        gender = .notSpecified
        hasCompletedOnboarding = false
        isLoading = false
        errorMessage = ""
    }
    
    func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                
                if document.exists, let data = document.data() {
                    print("✅ User profile loaded from Firestore")
                    self.goals = data["goals"] as? String ?? ""
                    self.height = data["height"] as? String ?? ""
                    self.currentWeight = data["currentWeight"] as? String ?? ""
                    self.targetWeight = data["targetWeight"] as? String ?? ""
                    self.hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
                    
                    if let genderString = data["gender"] as? String {
                        self.gender = Gender(rawValue: genderString) ?? .notSpecified
                    }
                } else {
                    print("📝 No user profile found, user needs onboarding")
                    self.hasCompletedOnboarding = false
                }
            } catch {
                print("❌ Error loading user profile: \(error)")
                self.errorMessage = "Failed to load profile"
                self.hasCompletedOnboarding = false
            }
            
            self.isLoading = false
        }
    }
    
    func saveUserProfile() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            errorMessage = "User not authenticated"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        let userData: [String: Any] = [
            "goals": goals,
            "height": height,
            "currentWeight": currentWeight,
            "targetWeight": targetWeight,
            "gender": gender.rawValue,
            "hasCompletedOnboarding": true,
            "updatedAt": Timestamp()
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("✅ User profile saved successfully")
            hasCompletedOnboarding = true
            isLoading = false
            return true
        } catch {
            print("❌ Error saving user profile: \(error)")
            errorMessage = "Failed to save profile"
            isLoading = false
            return false
        }
    }
    
    // Calculate BMR using Mifflin-St Jeor Equation
    func calculateBMR() -> Double? {
        guard let heightValue = Double(height),
              let weightValue = Double(currentWeight),
              heightValue > 0 && weightValue > 0 else {
            return nil
        }
        
        let heightInCm = heightValue * 2.54 // Convert inches to cm
        let weightInKg = weightValue * 0.453592 // Convert lbs to kg
        
        switch gender {
        case .male:
            return (10 * weightInKg) + (6.25 * heightInCm) - (5 * 25) + 5 // Assuming age of 25
        case .female:
            return (10 * weightInKg) + (6.25 * heightInCm) - (5 * 25) - 161 // Assuming age of 25
        case .notSpecified:
            return ((10 * weightInKg) + (6.25 * heightInCm) - (5 * 25) + 5 + (10 * weightInKg) + (6.25 * heightInCm) - (5 * 25) - 161) / 2
        }
    }
    
    // Calculate recommended daily calories (BMR * activity factor)
    func calculateDailyCalories(activityLevel: Double = 1.4) -> Double? {
        guard let bmr = calculateBMR() else { return nil }
        return bmr * activityLevel
    }
} 