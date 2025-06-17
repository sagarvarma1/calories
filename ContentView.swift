//
//  ContentView.swift
//  calories
//
//  Created by Sagar Varma on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            
            Text("MacroTracker")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Track your daily macronutrients")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
