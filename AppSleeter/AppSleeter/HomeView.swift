//
//  HomeView.swift
//  AppSleeter
//
//  Created by Andrew Wang on R 7/11/13.
//

import SwiftUI
import Charts
import Combine

final class WaterTracker: ObservableObject {
    struct WaterSlot: Identifiable {
        let id = UUID()
        let hour: Int
        let liters: Double
        var isCompleted: Bool
    }
    @Published var targetLiters: Double = 3.0
    @Published var schedule: [WaterSlot] = []
    var consumedLiters: Double { schedule.filter { $0.isCompleted }.map { $0.liters }.reduce(0, +) }
    var progress: Double { guard targetLiters > 0 else { return 0 }; return min(1, max(0, consumedLiters / targetLiters)) }
    func generateSchedule() {
        let hours = Array(9...21)
        let perSlot = targetLiters / Double(hours.count)
        schedule = hours.map { WaterSlot(hour: $0, liters: perSlot, isCompleted: false) }
    }
}

struct HomeView: View
{
    @EnvironmentObject var waterTracker: WaterTracker
    @State private var sleepPercentage = 0.70
    struct WaterIntake: Identifiable { let id = UUID(); let day: String; let ml: Int }
    @State private var weeklyWater: [WaterIntake] = [
        .init(day: "Mon", ml: 1200),
        .init(day: "Tue", ml: 900),
        .init(day: "Wed", ml: 1500),
        .init(day: "Thu", ml: 800),
        .init(day: "Fri", ml: 1300),
        .init(day: "Sat", ml: 1600),
        .init(day: "Sun", ml: 1100)
    ]
    @State private var selectedDay: String? = nil
    struct SleepEntry: Identifiable { let id = UUID(); let day: String; let hours: Int }
    @State private var weeklySleep: [SleepEntry] = [
        .init(day: "Mon", hours: 7),
        .init(day: "Tue", hours: 6),
        .init(day: "Wed", hours: 8),
        .init(day: "Thu", hours: 5),
        .init(day: "Fri", hours: 7),
        .init(day: "Sat", hours: 9),
        .init(day: "Sun", hours: 8)
    ]
    @State private var selectedSleepDay: String? = nil
    
    var body: some View
    {
        VStack (){
            VStack(spacing: 24) {
            
                
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
                    Text("Average")
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
                
                Chart(weeklyWater) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("mL", item.ml)
                    )
                    .foregroundStyle(.cyan)
                    .cornerRadius(4)
                    .opacity(selectedDay == nil || selectedDay == item.day ? 1.0 : 0.5)
                    .annotation(position: .top) {
                        if selectedDay == item.day {
                            Text("\(item.ml) mL")
                                .font(.caption2)
                                .bold()
                        }
                    }
                }
                .frame(height: 200)
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
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let day: String = proxy.value(atX: value.location.x) {
                                        selectedDay = day
                                    }
                                }
                                .onEnded { _ in
                                    selectedDay = nil
                                }
                            )
                    }
                }
                .scaleEffect(0.8)
                
                Chart(weeklySleep) { item in
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
                                .bold()
                        }
                    }
                }
                .frame(height: 200)
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
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let day: String = proxy.value(atX: value.location.x) {
                                        selectedSleepDay = day
                                    }
                                }
                                .onEnded { _ in
                                    selectedSleepDay = nil
                                }
                            )
                    }
                }
                .scaleEffect(0.8)
                
            }
            .padding(.top, 100)
            Button
            {
                
            }label: {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.black)
        }
        
    }
}

#Preview {
    HomeView()
        .environmentObject(WaterTracker())
}
