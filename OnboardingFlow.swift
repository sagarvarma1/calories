import SwiftUI

struct OnboardingFlow: View {
    @ObservedObject var userProfile: UserProfile
    @State private var currentStep = 0
    @State private var showingError = false
    
    let totalSteps = 6
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 16) {
                    HStack {
                        Text("Step \(currentStep + 1) of \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Current Screen
                TabView(selection: $currentStep) {
                    OnboardingIntroView(onNext: nextStep)
                        .tag(0)
                    
                    GenderOnboardingView(userProfile: userProfile, onNext: nextStep)
                        .tag(1)
                    
                    HeightOnboardingView(userProfile: userProfile, onNext: nextStep)
                        .tag(2)
                    
                    CurrentWeightOnboardingView(userProfile: userProfile, onNext: nextStep)
                        .tag(3)
                    
                    TargetWeightOnboardingView(userProfile: userProfile, onNext: nextStep)
                        .tag(4)
                    
                    GoalsOnboardingView(userProfile: userProfile, onNext: completeOnboarding)
                        .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(userProfile.errorMessage)
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            let success = await userProfile.saveUserProfile()
            if !success {
                showingError = true
            }
            // Note: The app will automatically transition to the main view
            // when userProfile.hasCompletedOnboarding becomes true
        }
    }
}

// MARK: - Individual Onboarding Views

struct OnboardingIntroView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 60) {
            Spacer()
            
            VStack(spacing: 32) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Let's get some info to customize your experience")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

struct GoalsOnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    let onNext: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("What are your goals?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Tell us what you want to achieve with your nutrition")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                TextField("e.g., Lose weight, build muscle, maintain health...", text: $userProfile.goals, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .focused($isTextFieldFocused)
                    .font(.body)
                
                Button(action: onNext) {
                    HStack {
                        if userProfile.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Text(userProfile.isLoading ? "Saving..." : "Complete Setup")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userProfile.goals.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(userProfile.goals.isEmpty ? .secondary : .white)
                    .cornerRadius(12)
                }
                .disabled(userProfile.goals.isEmpty || userProfile.isLoading)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct HeightOnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    let onNext: () -> Void
    @State private var selectedFeet: Int = 5
    @State private var selectedInches: Int = 8
    
    let feetOptions = Array(3...8)
    let inchesOptions = Array(0...11)
    
    var totalInches: Int {
        selectedFeet * 12 + selectedInches
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "ruler")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 12) {
                    Text("Height")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select your height")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 32) {
                // Height Display
                VStack(spacing: 8) {
                    Text("\(selectedFeet)' \(selectedInches)\"")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("(\(totalInches) inches total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Height Picker
                HStack(spacing: 0) {
                    // Feet Picker
                    Picker("Feet", selection: $selectedFeet) {
                        ForEach(feetOptions, id: \.self) { feet in
                            Text("\(feet)")
                                .font(.title2)
                                .tag(feet)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80)
                    .clipped()
                    .onChange(of: selectedFeet) { _ in
                        updateHeight()
                    }
                    
                    Text("ft")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    
                    // Inches Picker
                    Picker("Inches", selection: $selectedInches) {
                        ForEach(inchesOptions, id: \.self) { inches in
                            Text("\(inches)")
                                .font(.title2)
                                .tag(inches)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80)
                    .clipped()
                    .onChange(of: selectedInches) { _ in
                        updateHeight()
                    }
                    
                    Text("in")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                }
                .frame(height: 120)
                
                Button(action: onNext) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            loadCurrentHeight()
        }
    }
    
    private func updateHeight() {
        userProfile.height = String(totalInches)
    }
    
    private func loadCurrentHeight() {
        if let currentHeight = Double(userProfile.height), currentHeight > 0 {
            selectedFeet = Int(currentHeight) / 12
            selectedInches = Int(currentHeight) % 12
        } else {
            // Default to 5'8" if no height is set
            selectedFeet = 5
            selectedInches = 8
            updateHeight()
        }
    }
}

struct CurrentWeightOnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    let onNext: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "scalemass")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 12) {
                    Text("Current Weight")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your current weight in pounds")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    TextField("e.g., 150", text: $userProfile.currentWeight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .font(.title2)
                    
                    Text("lbs")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userProfile.currentWeight.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(userProfile.currentWeight.isEmpty ? .secondary : .white)
                        .cornerRadius(12)
                }
                .disabled(userProfile.currentWeight.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct TargetWeightOnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    let onNext: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                VStack(spacing: 12) {
                    Text("Target Weight")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your ideal weight in pounds")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    TextField("e.g., 140", text: $userProfile.targetWeight)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .font(.title2)
                    
                    Text("lbs")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userProfile.targetWeight.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(userProfile.targetWeight.isEmpty ? .secondary : .white)
                        .cornerRadius(12)
                }
                .disabled(userProfile.targetWeight.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

struct GenderOnboardingView: View {
    @ObservedObject var userProfile: UserProfile
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "person.2")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                VStack(spacing: 12) {
                    Text("Gender")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("This helps us calculate your nutritional needs more accurately")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Button(action: {
                        userProfile.gender = .male
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "person")
                                .font(.system(size: 30))
                            Text("M")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(userProfile.gender == .male ? Color.blue : Color(.systemGray6))
                        .foregroundColor(userProfile.gender == .male ? .white : .primary)
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        userProfile.gender = .female
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "person")
                                .font(.system(size: 30))
                            Text("F")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(userProfile.gender == .female ? Color.pink : Color(.systemGray6))
                        .foregroundColor(userProfile.gender == .female ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userProfile.gender == .notSpecified ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(userProfile.gender == .notSpecified ? .secondary : .white)
                        .cornerRadius(12)
                }
                .disabled(userProfile.gender == .notSpecified)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingFlow(userProfile: UserProfile())
} 