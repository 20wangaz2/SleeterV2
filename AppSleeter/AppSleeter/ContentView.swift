//
//  ContentView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var waterTracker = WaterTracker()
    var body: some View
    {

        TabView
        {
            Tab("Home", systemImage: Constants.homeLogo)
            {
                HomeView()
                    .environmentObject(waterTracker)
            }
            
            Tab("Water", systemImage: Constants.waterLogo )
            {
                WaterView()
                    .environmentObject(waterTracker)
            }
            
            Tab("Sleep", systemImage: Constants.sleepLogo)
            {
                Text("GoodEvening")
            }
            Tab("Workout", systemImage: Constants.workoutLogo)
            {
                Text("Good Morning")
            }
            
            
            
        }
        
    }
}

#Preview {
    ContentView()
}
