//
//  ContentView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var waterTracker = WaterTracker()
    @StateObject private var sleepTracker = SleepTracker()
    @StateObject private var authManager = AuthManager()
    var body: some View
    {

        TabView
        {
            Tab("Home", systemImage: Constants.homeLogo)
            {
                NavigationStack {
                    HomeView()
                        .environmentObject(waterTracker)
                        .environmentObject(sleepTracker)
                        .environmentObject(authManager)
                        .navigationTitle("Home")
                }
            }
            
            Tab("Water", systemImage: Constants.waterLogo )
            {
                WaterView()
                    .environmentObject(waterTracker)
                    .environmentObject(sleepTracker)
            }
            
            Tab("Sleep", systemImage: Constants.sleepLogo)
            {
                SleepView()
                    .environmentObject(sleepTracker)
            }
            Tab("Workout", systemImage: Constants.workoutLogo)
            {
                WorkoutView()
                    .environmentObject(waterTracker)
                    .environmentObject(sleepTracker)
            }
            
            
            
        }
        
    }
}

#Preview {
    ContentView()
}
