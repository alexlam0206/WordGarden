// All changes after that commit have been discarded, and the working directory is now at that state.
import SwiftUI

struct LogView: View {
    @EnvironmentObject var wordStorage: WordStorage
    @Environment(\.editMode) var editMode
    @State private var selectedDate: Date = Date()

    var availableDates: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
    }

    var selectedLog: DailyLog? {
        let calendar = Calendar.current
        return wordStorage.dailyLogs.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, in: availableDates.first!...availableDates.last!, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()

            if let log = selectedLog {
                VStack(alignment: .leading) {
                    Text("Total logs: \(log.logs.count)")
                        .font(.headline)
                        .padding(.horizontal)
                    List {
                        ForEach(log.logs, id: \.self) { logEntry in
                            Text(logEntry)
                                .font(.body)
                        }
                    }
                }
                .animation(.default, value: selectedDate)
            } else {
                Text("No logs for selected date")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Activity Logs")
        .navigationBarItems(leading: EditButton(), trailing: Group {
            if editMode?.wrappedValue.isEditing == true {
                Button("Delete Selected", role: .destructive) {
                    if let log = selectedLog {
                        wordStorage.dailyLogs.removeAll { $0.id == log.id }
                    }
                }
                .disabled(selectedLog == nil)
            } else {
                Button("Export Selected Log") {
                    // Trigger export for selected date
                    // Since export is in SettingsView, perhaps navigate back or use environment
                    // For now, perhaps add a state or something
                }
            }
        })
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}