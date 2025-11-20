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
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var sleepTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
    private func timeLabel(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour24 = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let suffix = hour24 >= 12 ? "PM" : "AM"
        let displayHour = hour24 % 12 == 0 ? 12 : hour24 % 12
        let minuteStr = String(format: "%02d", minute)
        return "\(displayHour):\(minuteStr) \(suffix)"
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
                    in: 2.7...4,
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

                VStack(spacing: 12) {
                    DatePicker("Wake Up", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
                }
                .padding(.horizontal, 24)

                Button("Schedule") {
                    waterTracker.generateSchedule(from: wakeTime, to: sleepTime)
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
                                    waterTracker.toggleSlot(at: index)
                                } label: {
                                    Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(entry.isCompleted ? .green : .gray)
                                        .imageScale(.large)
                                }
                                Text(timeLabel(entry.date))
                                    .frame(width: 90, alignment: .leading)
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
