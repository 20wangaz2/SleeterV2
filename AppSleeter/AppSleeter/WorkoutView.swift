import SwiftUI

struct Sport: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let litersPerHour: Double
}

struct WorkoutView: View {
    @EnvironmentObject var waterTracker: WaterTracker
    @EnvironmentObject var sleepTracker: SleepTracker
    @State private var selectedSport: Sport? = nil
    @State private var hours: Double = 0
    @State private var didUpdate = false
    private var sports: [Sport] {
        [
            Sport(name: "Running", litersPerHour: 0.8),
            Sport(name: "Cycling", litersPerHour: 0.7),
            Sport(name: "Soccer", litersPerHour: 0.8),
            Sport(name: "Basketball", litersPerHour: 0.8),
            Sport(name: "Swimming", litersPerHour: 1.0),
            Sport(name: "Tennis", litersPerHour: 0.7),
            Sport(name: "Football", litersPerHour: 0.9),
            Sport(name: "Hiking", litersPerHour: 0.6),
            Sport(name: "CrossFit", litersPerHour: 0.9),
            Sport(name: "Yoga", litersPerHour: 0.4),
            Sport(name: "Pilates", litersPerHour: 0.4),
            Sport(name: "Rowing", litersPerHour: 0.9),
            Sport(name: "Boxing", litersPerHour: 0.9),
            Sport(name: "Dance", litersPerHour: 0.6),
            Sport(name: "Skiing", litersPerHour: 0.7)
        ]
    }
    private var recommendedLiters: Double {
        guard let s = selectedSport else { return 0 }
        return max(0, s.litersPerHour * hours)
    }
    private var suggestedDailyTarget: Double {
        let base = 3.0
        let total = base + recommendedLiters
        return min(3.9, max(3.0, total))
    }
    var body: some View {
        VStack(spacing: 24) {
            Text("Workout")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)

            HStack(spacing: 6) {
                Image(systemName: "drop")
                    .foregroundStyle(.cyan)
                Text("Current target: \(waterTracker.targetLiters, specifier: "%.1f") L")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Menu {
                ForEach(sports) { sport in
                    Button(sport.name) { selectedSport = sport }
                }
            } label: {
                HStack {
                    Image(systemName: Constants.workoutLogo)
                    Text(selectedSport?.name ?? "Select Sport")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Hours")
                    .font(.headline)
                HStack(spacing: 12) {
                    Stepper(value: $hours, in: 0...12, step: 0.5) { Text("\(hours, specifier: "%.1f") h") }
                    Spacer()
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            if selectedSport != nil {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill").foregroundStyle(.cyan)
                        Text("Extra hydration: \(recommendedLiters, specifier: "%.1f") L")
                            .font(.headline)
                    }
                    Text("Suggested daily target: \(suggestedDailyTarget, specifier: "%.1f") L")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                let available = max(0, 3.9 - waterTracker.targetLiters)
                let extra = min(recommendedLiters, available)
                guard extra > 0 else { return }
                waterTracker.targetLiters += extra
                waterTracker.applyExtraLitersEvenly(extra)
                withAnimation { didUpdate = true }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text("Update Water Schedule")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.cyan.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedSport == nil)

            if didUpdate {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Updated: target \(waterTracker.targetLiters, specifier: "%.1f") L, schedule regenerated")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WaterTracker())
}
