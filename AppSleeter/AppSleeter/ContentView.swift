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
    var body: some View
    {

        TabView
        {
            Tab("Home", systemImage: Constants.homeLogo)
            {
                HomeView()
                    .environmentObject(waterTracker)
                    .environmentObject(sleepTracker)
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
