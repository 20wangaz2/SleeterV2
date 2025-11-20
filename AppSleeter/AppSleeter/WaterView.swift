//
//  WaterView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/17.
//
import SwiftUI

struct WaterView: View
{
    @EnvironmentObject var waterTracker: WaterTracker
    @State private var isEditing = false
    private func hourLabel(_ hour: Int) -> String {
        var h = hour
        let suffix = h >= 12 ? "PM" : "AM"
        if h == 0 { h = 12 }
        let display = h > 12 ? h - 12 : h
        return "\(display) \(suffix)"
    }
    var body: some View
    {
        ScrollView {
            VStack(spacing: 56)
            {
                Gauge(value: waterTracker.progress) { }
                currentValueLabel: {
                    Text("\(Int(waterTracker.progress * 100))%")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.cyan)
                .controlSize(.large)
                .scaleEffect(2.0)
                
                Text(String(format: "%.1f L", waterTracker.targetLiters))
                    .font(.system(size: 32, weight: .bold))
                
                Slider(
                    value: Binding(get: { waterTracker.targetLiters }, set: { waterTracker.targetLiters = $0 }),
                    in: 3...5,
                    step: 0.1
                ) {
                    Text("Target Daily Water")
                } minimumValueLabel: {
                    Text("2.7L")
                } maximumValueLabel: {
                    Text("4.0L")
                } onEditingChanged: { editing in
                    isEditing = editing
                }
                .padding(.horizontal, 24)

                Button("Schedule") {
                    waterTracker.generateSchedule()
                }
                .font(.headline)
                .padding(.top, 12)

                Spacer(minLength: 80)

                if !waterTracker.schedule.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today’s Water Schedule")
                            .font(.title3)
                            .bold()
                        ForEach(Array(waterTracker.schedule.enumerated()), id: \.element.id) { index, entry in
                            HStack(spacing: 12) {
                                Button {
                                    waterTracker.schedule[index].isCompleted.toggle()
                                } label: {
                                    Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(entry.isCompleted ? .green : .gray)
                                        .imageScale(.large)
                                }
                                Text(hourLabel(entry.hour))
                                    .frame(width: 60, alignment: .leading)
                                Spacer()
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(.cyan)
                                    .imageScale(.medium)
                                Text("\(Int(entry.liters * 1000)) mL")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 40)
        }
        
    }
}

#Preview
{
    WaterView()
        .environmentObject(WaterTracker())
}
