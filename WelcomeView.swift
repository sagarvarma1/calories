import SwiftUI

struct FoodItem {
    let imageName: String
    let name: String
    let protein: String
    let fat: String
    let carbs: String
    let calories: String
}

struct WelcomeView: View {
    @State private var showSignInView = false
    @State private var isSignUp = false
    @State private var currentIndex = 0
    
    let foodItems = [
        FoodItem(imageName: "burger.jpg", name: "Big Mac", protein: "25g", fat: "33g", carbs: "46g", calories: "563"),
        FoodItem(imageName: "bowl", name: "Chipotle Steak Bowl", protein: "40g", fat: "35g", carbs: "50g", calories: "700"),
        FoodItem(imageName: "donut", name: "Chocolate Donut", protein: "4g", fat: "14g", carbs: "32g", calories: "280")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Sliding Food Carousel
                VStack(spacing: 0) {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(foodItems.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 20) {
                                // Food Image
                                if let uiImage = UIImage(named: item.imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 280, height: 200)
                                        .clipped()
                                        .cornerRadius(16)
                                        .shadow(radius: 8)
                                } else {
                                    // Fallback placeholder
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.orange.gradient)
                                        .frame(width: 280, height: 200)
                                        .overlay(
                                            VStack {
                                                Image(systemName: "photo")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.white)
                                                Text(item.name)
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            }
                                        )
                                        .shadow(radius: 8)
                                }
                                
                                // Food Name
                                Text(item.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                // Macro Info Grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                    MacroInfoCard(title: "Protein", value: item.protein, color: .red)
                                    MacroInfoCard(title: "Fat", value: item.fat, color: .green)
                                    MacroInfoCard(title: "Carbs", value: item.carbs, color: .blue)
                                    MacroInfoCard(title: "Calories", value: item.calories, color: .orange)
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20) // Extra padding at bottom
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 440)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if value.translation.width < -50 {
                                        // Swipe left - next item (with wrapping)
                                        currentIndex = (currentIndex + 1) % foodItems.count
                                    } else if value.translation.width > 50 {
                                        // Swipe right - previous item (with wrapping)
                                        currentIndex = currentIndex == 0 ? foodItems.count - 1 : currentIndex - 1
                                    }
                                }
                            }
                    )
                    
                    // Space between content and dots
                    Spacer()
                        .frame(height: 16)
                    
                    // Custom Page Dots
                    HStack(spacing: 8) {
                        ForEach(0..<foodItems.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    
                    // Space between dots and buttons
                    Spacer()
                        .frame(height: 20)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        isSignUp = true
                        showSignInView = true
                    }) {
                        Text("Create Account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isSignUp = false
                        showSignInView = true
                    }) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showSignInView) {
            SignInView(isSignUp: isSignUp)
        }
    }
}

struct MacroInfoCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    WelcomeView()
} 