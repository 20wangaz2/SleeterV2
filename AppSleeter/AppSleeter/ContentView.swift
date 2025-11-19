//
//  ContentView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI

struct ContentView: View {
    var body: some View
    {

        TabView
        {
            Tab("Home", systemImage: Constants.homeLogo)
            {
                HomeView()
            }
            
            Tab("Water", systemImage: Constants.waterLogo )
            {
                Text("Hello")
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
