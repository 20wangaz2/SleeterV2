//
//  SleepView.swift
//  AppSleeter
//
//  Created by Kolby Hart on 11/20/25.
//
import SwiftUI

struct SleepView: View {
    @EnvironmentObject var sleepTracker: SleepTracker
    @State private var isEditingHours = false
    @State private var todaySleepInput: Double = 0
    
    private func timeLabel(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour24 = comps.hour ?? 0
        let minute = comps.minute ?? 0
        let suffix = hour24 >= 12 ? "PM" : "AM"
        let displayHour = hour24 % 12 == 0 ? 12 : hour24 % 12
        let minuteStr = String(format: "%02d", minute)
        return "\(displayHour):\(minuteStr) \(suffix)"
    }
    
    //used to convert decimal hours into a more readable hours and minutes format
    private func hoursLabel(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if m == 0 {
            return "\(h) h"
        } else {
            return "\(h) h \(m) m"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 56)
            {
                
                VStack(spacing: 8) {
                    Text(hoursLabel(sleepTracker.targetSleepHours))
                        .font(.system(size: 32, weight: .bold))
                    Text("Target Sleep")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Sleep Amount")
                        .font(.headline)
                    Slider(
                        value: Binding(
                            get: { sleepTracker.targetSleepHours },
                            set: { sleepTracker.targetSleepHours = $0 }
                        ),
                        in: 7...10,
                        step: 0.25
                    ) {
                        Text("Target Sleep")
                    } minimumValueLabel: {
                        Text("7h")
                    } maximumValueLabel: {
                        Text("10h")
                    } onEditingChanged: { editing in
                        isEditingHours = editing
                    }
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 12) {
                    DatePicker("Wake Up Time", selection: $sleepTracker.wakeUpTime, displayedComponents: .hourAndMinute)
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 8) {
                    Text("Target bedtime for \(hoursLabel(sleepTracker.targetSleepHours))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(timeLabel(sleepTracker.bedTime))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.brown)
                }
                .padding(.vertical, 16)
                
                Button("Set Bedtime Reminder") {
                    sleepTracker.scheduleBedtimeNotification()
                }
                .font(.headline)
                
                Divider()
                    .padding(.vertical, 24)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Log Today's Sleep")
                        .font(.title3)
                        .bold()
                    
                    HStack {
                        Text(hoursLabel(todaySleepInput))
                            .font(.title2)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                    }
                    
                    Slider(
                        value: $todaySleepInput,
                        in: 0...12,
                        step: 0.25
                    ) {
                        Text("Hours Slept")
                    } minimumValueLabel: {
                        Text("0h")
                    } maximumValueLabel: {
                        Text("12h")
                    }
                    
                    Button("Save Today's Sleep") {
                        sleepTracker.updateTodaySleep(hours: todaySleepInput)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 80)
            }
            .padding(.top, 40)
        }
        .onAppear {
            todaySleepInput = sleepTracker.weeklySleepHours[sleepTracker.indexForToday()]
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(SleepTracker())
}
