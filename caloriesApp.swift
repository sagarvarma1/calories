//
//  caloriesApp.swift
//  calories
//
//  Created by Sagar Varma on 6/17/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct LoadingDataView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("Getting Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Loading your profile...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🔥 Configuring Firebase...")
        
        // Check if GoogleService-Info.plist exists in bundle
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("✅ GoogleService-Info.plist found at: \(path)")
            
            if let plist = NSDictionary(contentsOfFile: path) {
                print("✅ Plist loaded successfully")
                print("✅ Bundle ID from plist: \(plist["BUNDLE_ID"] as? String ?? "Not found")")
                print("✅ Project ID from plist: \(plist["PROJECT_ID"] as? String ?? "Not found")")
            } else {
                print("❌ Could not load plist file")
            }
        } else {
            print("❌ GoogleService-Info.plist NOT FOUND in bundle!")
        }
        
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        
        // Check if Firebase is working
        if let app = FirebaseApp.app() {
            print("✅ Firebase app instance exists: \(app.name)")
            print("✅ Firebase project ID: \(app.options.projectID ?? "No project ID")")
        } else {
            print("❌ Firebase app instance is nil!")
        }
        
        return true
    }
}

@main
struct caloriesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var userProfile = UserProfile()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                if userProfile.isLoading {
                    LoadingDataView()
                        .environmentObject(authManager)
                        .environmentObject(userProfile)
                } else if userProfile.hasCompletedOnboarding {
                MacroTrackingView()
                    .environmentObject(authManager)
                        .environmentObject(userProfile)
                } else {
                    OnboardingFlow(userProfile: userProfile)
                        .environmentObject(authManager)
                        .environmentObject(userProfile)
                }
            } else {
                WelcomeView()
                    .environmentObject(authManager)
            }
        }
    }
}
