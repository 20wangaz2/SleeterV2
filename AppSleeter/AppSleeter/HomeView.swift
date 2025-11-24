//
//  HomeView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI
import Charts
import Combine
import UserNotifications
import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

final class AuthManager: ObservableObject {
    @Published var uid: String? = nil
    @Published var displayName: String? = nil
    @Published var photoURL: URL? = nil
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                var top: UIViewController? = root
                while let presented = top?.presentedViewController { top = presented }
                return top
            }
        }
        return nil
    }
    private func ensureGIDConfig() {
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.configuration == nil {
            let iosClient = "982360724962-273u0mnm55m1uebcf3ao4gnm72a7b747.apps.googleusercontent.com"
            var clientID: String? = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
            #if canImport(FirebaseCore)
            if clientID == nil { clientID = FirebaseApp.app()?.options.clientID }
            #endif
            let idToUse = clientID ?? iosClient
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: idToUse)
        }
        #endif
    }
    func signInWithGoogle() {
        #if canImport(GoogleSignIn) && canImport(FirebaseAuth)
        ensureGIDConfig()
        guard let presentingVC = Self.topViewController() else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            guard error == nil, let result = result else { return }
            let user = result.user
            guard let idToken = user.idToken?.tokenString else { return }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let user = authResult?.user {
                    self.uid = user.uid
                    WeekSync.shared.uid = user.uid
                    self.displayName = user.displayName ?? result.user.profile?.name
                    if let url = result.user.profile?.imageURL(withDimension: 96) { self.photoURL = url } else { self.photoURL = user.photoURL }
                }
            }
        }
        #endif
    }
    func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        uid = nil
        WeekSync.shared.uid = nil
        displayName = nil
        photoURL = nil
    }
}

final class WeekSync: ObservableObject {
    static let shared = WeekSync()
    @Published var uid: String? = nil
    func weekISO(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date) }
    func saveWater(weekStart: Date, totals: [Int]) {
        guard let u = uid else { return }
        #if canImport(FirebaseFirestore)
        let iso = weekISO(weekStart)
        let db = Firestore.firestore()
        db.collection("users").document(u).collection("weeks").document(iso).setData([
            "weekStart": iso,
            "waterTotalsML": totals
        ], merge: true)
        #endif
    }
    func saveSleep(weekStart: Date, hours: [Double]) {
        guard let u = uid else { return }
        #if canImport(FirebaseFirestore)
        let iso = weekISO(weekStart)
        let db = Firestore.firestore()
        db.collection("users").document(u).collection("weeks").document(iso).setData([
            "weekStart": iso,
            "sleepHours": hours
        ], merge: true)
        #endif
    }
    func load(uid: String, weekISO: String, completion: @escaping ([String: Any]?) -> Void) {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("weeks").document(weekISO).getDocument { snap, _ in
            completion(snap?.data())
        }
        #else
        completion(nil)
        #endif
    }
}

final class WaterTracker: ObservableObject {
    struct WaterSlot: Identifiable {
        let id = UUID()
        let date: Date
        var liters: Double
        var isCompleted: Bool
    }
    struct WeeklyItem: Identifiable { let id = UUID(); let day: String; let ml: Int }
    @Published var targetLiters: Double = 3.0
    @Published var wakeTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @Published var sleepTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
    @Published var schedule: [WaterSlot] = []
    @Published var weeklyTotalsML: [Int] = Array(repeating: 0, count: 7)
    @Published private(set) var weekStart: Date = WaterTracker.mondayStart(for: Date())
    var consumedLiters: Double { schedule.filter { $0.isCompleted }.map { $0.liters }.reduce(0, +) }
    var progress: Double { guard targetLiters > 0 else { return 0 }; return min(1, max(0, consumedLiters / targetLiters)) }
    var weeklyWaterItems: [WeeklyItem] {
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return days.enumerated().map { WeeklyItem(day: $1, ml: weeklyTotalsML[$0]) }
    }
    init() {
        loadWeek()
    }
    func generateSchedule(from start: Date, to end: Date) {
        ensureCurrentWeek()
        guard start < end else {
            schedule = []
            return
        }
        var times: [Date] = []
        var t = start
        while t < end {
            times.append(t)
            t = Calendar.current.date(byAdding: .hour, value: 1, to: t)!
        }
        let byDate = Dictionary(uniqueKeysWithValues: schedule.map { ($0.date, $0) })
        let uncompletedTimes = times.filter { byDate[$0]?.isCompleted != true }
        let remainingLiters = max(0, targetLiters - consumedLiters)
        let perSlot = uncompletedTimes.isEmpty ? 0 : remainingLiters / Double(uncompletedTimes.count)
        schedule = times.map { d in
            if let old = byDate[d], old.isCompleted { return old }
            else { return WaterSlot(date: d, liters: perSlot, isCompleted: false) }
        }
        scheduleNotificationsForToday()
    }
    func toggleSlot(at index: Int) {
        ensureCurrentWeek()
        guard schedule.indices.contains(index) else { return }
        schedule[index].isCompleted.toggle()
        let delta = Int((schedule[index].liters * 1000).rounded())
        let todayIdx = indexForToday()
        weeklyTotalsML[todayIdx] = max(0, weeklyTotalsML[todayIdx] + (schedule[index].isCompleted ? delta : -delta))
        saveWeek()
        rebalanceRemaining()
    }
    private func indexForToday() -> Int {
        let cal = Calendar(identifier: .gregorian)
        let weekday = cal.component(.weekday, from: Date())
        return (weekday + 5) % 7 
    }
    private func ensureCurrentWeek() {
        let current = WaterTracker.mondayStart(for: Date())
        if !Calendar.current.isDate(weekStart, inSameDayAs: current) {
            weekStart = current
            weeklyTotalsML = Array(repeating: 0, count: 7)
            saveWeek()
        }
    }
    private func loadWeek() {
        let current = WaterTracker.mondayStart(for: Date())
        let defaults = UserDefaults.standard
        if let savedStart = defaults.object(forKey: "water.week.start") as? Date,
           let totals = defaults.array(forKey: "water.week.totals") as? [Int], totals.count == 7,
           Calendar.current.isDate(savedStart, inSameDayAs: current) {
            weekStart = savedStart
            weeklyTotalsML = totals
        } else {
            weekStart = current
            weeklyTotalsML = Array(repeating: 0, count: 7)
            saveWeek()
        }
        if schedule.isEmpty && consumedLiters == 0 && weeklyTotalsML.contains(where: { $0 != 0 }) {
            weeklyTotalsML = Array(repeating: 0, count: 7)
            saveWeek()
        }
    }
    private func saveWeek() {
        let defaults = UserDefaults.standard
        defaults.set(weekStart, forKey: "water.week.start")
        defaults.set(weeklyTotalsML, forKey: "water.week.totals")
        WeekSync.shared.saveWater(weekStart: weekStart, totals: weeklyTotalsML)
    }
    func clearLocalWeek() {
        weeklyTotalsML = Array(repeating: 0, count: 7)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "water.week.start")
        defaults.removeObject(forKey: "water.week.totals")
    }
    private static func mondayStart(for date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
        return start
    }
    private func dateKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
    private func notificationId(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd.HHmm"
        return "water." + fmt.string(from: date)
    }
    func scheduleNotificationsForToday() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            center.getPendingNotificationRequests { requests in
                let todayPrefix = "water." + self.dateKey()
                let ids = requests.filter { $0.identifier.hasPrefix(todayPrefix) }.map { $0.identifier }
                center.removePendingNotificationRequests(withIdentifiers: ids)
                for slot in self.schedule where slot.date >= Date() && !slot.isCompleted {
                    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: slot.date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let content = UNMutableNotificationContent()
                    content.title = "Hydration Reminder"
                    content.body = "it's time to drinky drinky!"
                    content.sound = .default
                    let req = UNNotificationRequest(identifier: self.notificationId(for: slot.date), content: content, trigger: trigger)
                    center.add(req)
                }
            }
        }
    }
    func applyExtraLitersEvenly(_ extra: Double) {
        ensureCurrentWeek()
        guard extra > 0 else { return }
        let indices = schedule.indices.filter { !schedule[$0].isCompleted }
        guard !indices.isEmpty else { return }
        let per = extra / Double(indices.count)
        for i in indices { schedule[i].liters += per }
        scheduleNotificationsForToday()
    }
    func rebalanceRemaining() {
        ensureCurrentWeek()
        let indices = schedule.indices.filter { !schedule[$0].isCompleted }
        guard !indices.isEmpty else { return }
        let remainingLiters = max(0, targetLiters - consumedLiters)
        let per = remainingLiters / Double(indices.count)
        for i in indices { schedule[i].liters = per }
        scheduleNotificationsForToday()
    }
}

struct HomeView: View
{
    @EnvironmentObject var waterTracker: WaterTracker
    @EnvironmentObject var sleepTracker: SleepTracker
    @EnvironmentObject var authManager: AuthManager
    private var sleepPercentage: Double {
        let h = todayHours
        if h < 5 { return 0.25 }
        if h >= 6 && h <= 7 { return 0.5 }
        if h > 8 { return 1.0 }
        if h > 7 { return 0.75 }
        return 0.5
    }
    @State private var selectedDayIndex: Int? = nil
    struct SleepEntry: Identifiable { let id = UUID(); let day: String; let hours: Int }
    var weeklySleepItems: [SleepEntry] {
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        return days.enumerated().map { SleepEntry(day: $1, hours: Int(round(sleepTracker.weeklySleepHours[$0]))) }
    }
    @State private var selectedSleepDay: String? = nil
    private func sleepConditionLabel(_ hours: Int) -> String {
        if hours < 5 { return "Poor" }
        if hours >= 6 && hours <= 7 { return "Average" }
        if hours > 8 { return "Excellent" }
        if hours > 7 { return "Good" }
        return "Average"
    }
    private var todayHours: Int {
        Int(round(sleepTracker.weeklySleepHours[sleepTracker.indexForToday()]))
    }
    
    var body: some View
    {
        ScrollView {
            VStack(spacing: 40) {
                Gauge(value: waterTracker.progress) {
                  
                }
                currentValueLabel: {
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .imageScale(.small)
                            .foregroundStyle(.cyan)
                        Text("\(Int(waterTracker.progress * 100))%")
                            .font(.caption)
                            .bold()
                    }
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(.cyan)
                .controlSize(.large)
                .scaleEffect(2.0)
                .padding(.bottom, 70)
                
                
                
                Gauge(value: sleepPercentage) {
                    Image(systemName: Constants.sleepLogo)
                        .font(.system(size: 24))
                        .foregroundColor(.brown)
                } currentValueLabel: {
                    Text(sleepConditionLabel(todayHours))
                        .font(.system(size: 18))
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } minimumValueLabel: {
                    Text("Bad")
                        .font(.caption2)
                           .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } maximumValueLabel: {
                    Text("Excellent")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .gaugeStyle(.linearCapacity)
                .tint(Gradient(colors: [.red, .yellow, .green]))
                .frame(width: 220)
                .scaleEffect(1.5)
                
                Chart(waterTracker.weeklyWaterItems) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("mL", item.ml)
                    )
                    .foregroundStyle(.cyan)
                    .cornerRadius(4)
                    .opacity(selectedDayIndex == ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"].firstIndex(of: item.day) ? 1.0 : 0.5)
                    .annotation(position: .top) {
                        if selectedDayIndex == ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"].firstIndex(of: item.day) {
                            Text("\(item.ml) mL")
                                .font(.caption2)
                                .bold()
                        }
                    }
                }
                .frame(height: 240)
                .padding(.bottom, 16)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisTick()
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v) mL")
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        if let day: String = proxy.value(atX: value.location.x) {
                                            if let idx = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"].firstIndex(of: day) {
                                                selectedDayIndex = idx
                                            }
                                        }
                                    }
                            )
                    }
                }
                
                Chart(weeklySleepItems) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(.brown)
                    .cornerRadius(4)
                    .opacity(selectedSleepDay == nil || selectedSleepDay == item.day ? 1.0 : 0.5)
                    .annotation(position: .top) {
                        if selectedSleepDay == item.day {
                            Text("\(item.hours) h")
                                .font(.caption2)
                        }
                    }
                }
                .frame(height: 240)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisTick()
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v) h")
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        if let day: String = proxy.value(atX: value.location.x) {
                                            selectedSleepDay = day
                                        }
                                    }
                            )
                    }
                }
                
            }
            .padding(.top, 100)
        }
        .onChange(of: authManager.uid) { oldValue, newValue in
            let zeroWater = Array(repeating: 0, count: 7)
            guard let u = newValue, !u.isEmpty else {
                DispatchQueue.main.async {
                    waterTracker.clearLocalWeek()
                    sleepTracker.showBlankForSignedOut()
                }
                return
            }
            var cal = Calendar(identifier: .gregorian)
            cal.firstWeekday = 2
            let start = cal.dateInterval(of: .weekOfYear, for: Date())!.start
            let iso = WeekSync.shared.weekISO(start)
            WeekSync.shared.load(uid: u, weekISO: iso) { data in
                let d = data ?? [:]
                let totals = d["waterTotalsML"] as? [Int]
                let hours = d["sleepHours"] as? [Double]
                DispatchQueue.main.async {
                    waterTracker.weeklyTotalsML = (totals?.count == 7) ? totals! : zeroWater
                    sleepTracker.replaceWeekFromRemote(hours: (hours?.count == 7) ? hours! : Array(repeating: 0.0, count: 7))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let uid = authManager.uid, !uid.isEmpty {
                    Menu {
                        HStack(spacing: 8) {
                            if let url = authManager.photoURL {
                                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { Image(systemName: "person.crop.circle") }
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            }
                            Text(authManager.displayName ?? "Account")
                                .font(.subheadline)
                        }
                        Button(role: .destructive) { authManager.signOut() } label: { Text("Sign out") }
                    } label: {
                        HStack(spacing: 6) {
                            if let url = authManager.photoURL {
                                AsyncImage(url: url) { img in img.resizable().scaledToFill() } placeholder: { Image(systemName: "person.crop.circle") }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                            }
                            Text(authManager.displayName ?? "Account")
                                .font(.subheadline)
                        }
                    }
                } else {
                    Button { authManager.signInWithGoogle() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Sign in")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

}

#Preview {
    HomeView()
        .environmentObject(WaterTracker())
}
