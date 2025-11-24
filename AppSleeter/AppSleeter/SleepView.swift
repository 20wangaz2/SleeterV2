//
//  SleepView.swift
//  AppSleeter
//
//  Created by Kolby Hart on 11/20/25.
//
import SwiftUI
import UserNotifications
import Combine

final class SleepTracker: ObservableObject {
    @Published var targetSleepHours: Double = 8.0
    @Published var wakeUpTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @Published private(set) var weeklySleepHours: [Double] = Array(repeating: 0, count: 7)
    @Published private(set) var weekStart: Date = SleepTracker.mondayStart(for: Date())
    var bedTime: Date {
        Calendar.current.date(byAdding: .minute, value: -Int(targetSleepHours * 60), to: wakeUpTime) ?? wakeUpTime
    }
    var bedTimeToday: Date {
        let bt = bedTime
        if bt <= wakeUpTime {
            return Calendar.current.date(byAdding: .day, value: 1, to: bt) ?? bt
        } else {
            return bt
        }
    }
    init() { loadWeek() }
    func updateTodaySleep(hours: Double) {
        ensureCurrentWeek()
        weeklySleepHours[indexForToday()] = max(0, hours)
        saveWeek()
    }
    func indexForToday() -> Int {
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }
    private func ensureCurrentWeek() {
        let current = SleepTracker.mondayStart(for: Date())
        if !Calendar.current.isDate(weekStart, inSameDayAs: current) {
            weekStart = current
            weeklySleepHours = Array(repeating: 0, count: 7)
            saveWeek()
        }
    }
    private func loadWeek() {
        let current = SleepTracker.mondayStart(for: Date())
        let defaults = UserDefaults.standard
        if let savedStart = defaults.object(forKey: "sleep.week.start") as? Date,
           let hours = defaults.array(forKey: "sleep.week.hours") as? [Double], hours.count == 7,
           Calendar.current.isDate(savedStart, inSameDayAs: current) {
            weekStart = savedStart
            weeklySleepHours = hours
        } else {
            weekStart = current
            weeklySleepHours = Array(repeating: 0, count: 7)
            saveWeek()
        }
    }
    private func saveWeek() {
        let defaults = UserDefaults.standard
        defaults.set(weekStart, forKey: "sleep.week.start")
        defaults.set(weeklySleepHours, forKey: "sleep.week.hours")
    }
    private static func mondayStart(for date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)!.start
    }
    func scheduleBedtimeNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            center.getPendingNotificationRequests { requests in
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd"
                let todayKey = fmt.string(from: Date())
                let ids = requests.filter { $0.identifier.hasPrefix("sleep." + todayKey) }.map { $0.identifier }
                center.removePendingNotificationRequests(withIdentifiers: ids)
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.bedTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let content = UNMutableNotificationContent()
                content.title = "Sleep Reminder"
                content.body = "Time to wind down for bed."
                content.sound = .default
                let id = "sleep." + todayKey + ".bed"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(req)
            }
        }
    }
}

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
