import Foundation
import FirebaseAuth

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        // Check if user is already signed in
        self.currentUser = Auth.auth().currentUser
        self.isAuthenticated = currentUser != nil
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔥 Attempting to create user with email: \(email)")
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ User created successfully: \(result.user.email ?? "no email")")
            currentUser = result.user
            isAuthenticated = true
        } catch {
            print("❌ Firebase Auth Error: \(error)")
            print("❌ Error localizedDescription: \(error.localizedDescription)")
            if let authError = error as NSError? {
                print("❌ Error code: \(authError.code)")
                print("❌ Error domain: \(authError.domain)")
                print("❌ Error userInfo: \(authError.userInfo)")
            }
            
            // Provide user-friendly error messages for sign up
            if let authError = error as NSError? {
                switch authError.code {
                case 17007: // Email already in use
                    errorMessage = "An account with this email already exists"
                case 17026: // Weak password
                    errorMessage = "Password should be at least 6 characters"
                case 17008: // Invalid email
                    errorMessage = "Please enter a valid email address"
                case 17999: // Internal error (configuration issues)
                    errorMessage = "Service temporarily unavailable. Please try again later"
                default:
                    errorMessage = "Unable to create account. Please try again"
                }
            } else {
                errorMessage = "Unable to create account. Please try again"
            }
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔥 Attempting to sign in with email: \(email)")
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully: \(result.user.email ?? "no email")")
            currentUser = result.user
            isAuthenticated = true
        } catch {
            print("❌ Firebase Auth Error: \(error)")
            print("❌ Error localizedDescription: \(error.localizedDescription)")
            if let authError = error as NSError? {
                print("❌ Error code: \(authError.code)")
                print("❌ Error domain: \(authError.domain)")
                print("❌ Error userInfo: \(authError.userInfo)")
            }
            
            // Provide user-friendly error messages for sign in
            if let authError = error as NSError? {
                switch authError.code {
                case 17011: // User not found
                    errorMessage = "Invalid Username/Password"
                case 17009: // Wrong password
                    errorMessage = "Invalid Username/Password"
                case 17020: // Network error
                    errorMessage = "Network error. Please check your connection"
                case 17999: // Internal error (configuration issues)
                    errorMessage = "Service temporarily unavailable. Please try again later"
                default:
                    errorMessage = "Invalid Username/Password"
                }
            } else {
                errorMessage = "Invalid Username/Password"
            }
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
} 