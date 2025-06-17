//
//  caloriesApp.swift
//  calories
//
//  Created by Sagar Varma on 6/17/25.
//

import SwiftUI
import FirebaseCore

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
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MacroTrackingView()
                    .environmentObject(authManager)
            } else {
                WelcomeView()
                    .environmentObject(authManager)
            }
        }
    }
}
