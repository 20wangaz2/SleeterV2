//
//  WaterView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/17.
//
import SwiftUI

struct WaterView: View
{
    var body: some View
    {
        VStack()
        {
            HStack()
            {
                Gauge(value: 0.25) { }
                currentValueLabel: {
                    Text("99")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.cyan)
                .controlSize(.large)
                .scaleEffect(2.0)
                
            }
            
        }
    }
}

#Preview
{
    
    WaterView()
}
