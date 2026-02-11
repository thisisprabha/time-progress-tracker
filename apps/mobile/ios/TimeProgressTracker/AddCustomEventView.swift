//
//  AddCustomEventView.swift
//  TimeProgressTracker
//
//  Add/Edit Custom Event View
//

import SwiftUI

struct AddCustomEventView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // Edit Mode support
    var existingEvent: CustomEvent?
    
    @State private var eventName = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var includeTime = false
    @State private var selectedCategory: EventCategory = .personal
    @State private var selectedMode: EventMode = .countdown
    @State private var selectedRecurrence: EventRecurrence = .none
    @State private var selectedReminderOffsets: Set<Int> = []
    @State private var goalCount: String = "90"
    
    init(initialMode: EventMode = .countdown, existingEvent: CustomEvent? = nil) {
        self.existingEvent = existingEvent
        
        if let event = existingEvent {
            _eventName = State(initialValue: event.name)
            _selectedCategory = State(initialValue: event.category)
            _selectedMode = State(initialValue: event.mode)
            _selectedRecurrence = State(initialValue: event.recurrence)
            _goalCount = State(initialValue: "\(event.goalCount ?? 90)")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: event.date) {
                _selectedDate = State(initialValue: date)
            }
            
            if let timeOfDay = event.timeOfDay {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                if let time = timeFormatter.date(from: timeOfDay) {
                    _selectedTime = State(initialValue: time)
                    _includeTime = State(initialValue: true)
                }
            }
            
            let offsets = Set(event.reminders.map { $0.offsetMinutes })
            _selectedReminderOffsets = State(initialValue: offsets)
        } else {
            _selectedMode = State(initialValue: initialMode)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // top Type section
                Section(header: Text("Type")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Divider()
                        
                        Picker("Mode", selection: $selectedMode) {
                            ForEach(EventMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedMode) { newMode in
                            if newMode != .countdown { selectedRecurrence = .none }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text(selectedMode == .habit ? "Habit Details" : "Event Details")) {
                    TextField(selectedMode == .habit ? "Habit Name (e.g. Daily Run)" : "Event Name (e.g. Birthday)", text: $eventName)
                        .onChange(of: eventName) { newValue in
                             if newValue.count > 12 { eventName = String(newValue.prefix(12)) }
                        }
                    
                    DatePicker(
                        (selectedMode == .countup || selectedMode == .habit) ? "Start Date" : "Event Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    
                    if selectedMode == .habit {
                        HStack {
                            Text("Goal Count (Days)")
                            Spacer()
                            TextField("90", text: $goalCount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }
                    
                    if selectedMode != .habit {
                        Toggle("Include Time", isOn: $includeTime)
                        
                        if includeTime {
                             DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                
                // Recurrence only for Countdown
                if selectedMode == .countdown {
                    Section(header: Text("Repeat")) {
                        Picker("Frequency", selection: $selectedRecurrence) {
                            ForEach(EventRecurrence.allCases, id: \.self) { recurrence in
                                Text(recurrence.displayName).tag(recurrence)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                if selectedMode == .countdown {
                    Section(header: Text("Reminders")) {
                         ForEach(ReminderPreset.allCases, id: \.self) { preset in
                             HStack {
                                 Text(preset.title)
                                 Spacer()
                                 if selectedReminderOffsets.contains(preset.minutes) {
                                     Image(systemName: "checkmark").foregroundColor(.accentColor)
                                 }
                             }
                             .contentShape(Rectangle())
                             .onTapGesture {
                                 toggleReminder(preset.minutes)
                             }
                         }
                    }
                }
            }
            .navigationTitle(existingEvent == nil ? "Add Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                    .disabled(eventName.isEmpty)
                }
            }
        }
        .font(.system(.body))
    }
    
    private func save() {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let isoDate = dateFormatter.string(from: selectedDate)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = includeTime ? timeFormatter.string(from: selectedTime) : nil
        let reminders = selectedReminderOffsets.sorted().map { EventReminder(offsetMinutes: $0) }
        let goal = Int(goalCount) ?? 90

        let newEvent = CustomEvent(
            id: existingEvent?.id ?? UUID().uuidString,
            name: eventName,
            date: isoDate,
            startDate: existingEvent?.startDate ?? isoDate,
            category: selectedCategory,
            mode: selectedMode,
            recurrence: (selectedMode == .countup || selectedMode == .habit) ? .none : selectedRecurrence,
            timeOfDay: timeString,
            reminders: selectedMode == .countdown ? reminders : [],
            streakHistory: existingEvent?.streakHistory ?? [],
            goalCount: selectedMode == .habit ? goal : nil
        )
        
        if let existing = existingEvent {
            if let index = appState.customEvents.firstIndex(where: { $0.id == existing.id }) {
                appState.customEvents[index] = newEvent
            }
        } else {
            appState.customEvents.append(newEvent)

            // If it's a habit, mirror it into the habits list so streak views/widgets show it
            if newEvent.mode == .habit {
                appState.addHabit(name: newEvent.name)
            }
            
            // Auto-select this event if less than 5 custom events selected
            let customItem = DisplayItem.customEvent(id: newEvent.id)
            let customCount = appState.selectedDisplayItems.filter { item in
                if case .customEvent = item { return true }
                return false
            }.count
            
            if customCount < 5 && !appState.selectedDisplayItems.contains(customItem) {
                appState.selectedDisplayItems.append(customItem)
            }
        }
        
        appState.saveSettings()
        dismiss()
    }

    private func toggleReminder(_ minutes: Int) {
        if selectedReminderOffsets.contains(minutes) {
            selectedReminderOffsets.remove(minutes)
        } else {
            selectedReminderOffsets.insert(minutes)
        }
    }
}

enum ReminderPreset: Int, CaseIterable {
    case week = 10080  // 7 * 24 * 60
    case day = 1440    // 24 * 60
    case hour = 60
    case atTime = 0

    var title: String {
        switch self {
        case .week: return "1 week before"
        case .day: return "1 day before"
        case .hour: return "1 hour before"
        case .atTime: return "At time"
        }
    }

    var minutes: Int { rawValue }
}
