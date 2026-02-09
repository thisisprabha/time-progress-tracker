import SwiftUI

struct QuickCreateEventView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "My next event"
    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    let onCreated: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Create first countdown")
                .font(.sabdeviBold(size: 20))
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Button(action: create) {
                Text("Create")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .presentationDetents([.fraction(0.4)])
    }

    private func create() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let iso = formatter.string(from: date)

        let newEvent = CustomEvent(
            name: name.isEmpty ? "My next event" : name,
            date: iso,
            category: .personal,
            mode: .countdown,
            recurrence: .none,
            reminders: [],
            streakHistory: []
        )
        appState.customEvents.append(newEvent)

        let item = DisplayItem.customEvent(id: newEvent.id)
        if !appState.selectedDisplayItems.contains(item) {
            appState.selectedDisplayItems.insert(item, at: 0)
        }

        appState.saveSettings()
        onCreated()
        dismiss()
    }
}
