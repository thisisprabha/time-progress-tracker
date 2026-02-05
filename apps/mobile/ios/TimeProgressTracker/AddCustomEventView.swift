//
//  AddCustomEventView.swift
//  TimeProgressTracker
//
//  Add Custom Event View with Calendar
//

import SwiftUI

struct AddCustomEventView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var eventName = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var includeTime = false
    @State private var selectedCategory: EventCategory = .personal
    @State private var selectedMode: EventMode = .countdown
    @State private var selectedRecurrence: EventRecurrence = .none
    @State private var selectedReminderOffsets: Set<Int> = []
    
    init() {
        // Customize Navigation Bar Font
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        // Title Font
        if let font = UIFont(name: "Sabdevi-Bold", size: 18) {
            appearance.titleTextAttributes = [.font: font]
        }
        
        // Button Fonts
        if let font = UIFont(name: "Sabdevi-Regular", size: 16) {
            let buttonAppearance = UIBarButtonItemAppearance()
            buttonAppearance.normal.titleTextAttributes = [.font: font]
            buttonAppearance.highlighted.titleTextAttributes = [.font: font]
            appearance.buttonAppearance = buttonAppearance
            appearance.doneButtonAppearance = buttonAppearance
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Name")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                        
                        TextField("e.g., Birthday, Wedding", text: $eventName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.sabdeviRegular(size: 14))
                            .onChange(of: eventName) { newValue in
                                // Limit to 12 characters
                                if newValue.count > 12 {
                                    eventName = String(newValue.prefix(12))
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text((selectedMode == .countup || selectedMode == .habit) ? "Start Date" : "Event Date")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(appState.theme.accentColor(isDark: appState.isDarkMode))
                            .environment(\.locale, Locale(identifier: "en_US"))
                        
                        Toggle(isOn: $includeTime) {
                            Text("Include Time")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .tint(appState.theme.accentColor(isDark: appState.isDarkMode))
                        
                        if includeTime {
                            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .accentColor(appState.theme.accentColor(isDark: appState.isDarkMode))
                                .environment(\.locale, Locale(identifier: "en_US"))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Text(category.displayName)
                                    .font(.sabdeviRegular(size: 12))
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mode")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)

                        Picker("Mode", selection: $selectedMode) {
                            ForEach(EventMode.allCases, id: \.self) { mode in
                                Text(mode.displayName)
                                    .font(.sabdeviRegular(size: 12))
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedMode) { newMode in
                            if newMode == .countup || newMode == .habit {
                                selectedRecurrence = .none
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repeat")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)

                        Picker("Repeat", selection: $selectedRecurrence) {
                            ForEach(EventRecurrence.allCases, id: \.self) { recurrence in
                                Text(recurrence.displayName)
                                    .font(.sabdeviRegular(size: 12))
                                    .tag(recurrence)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(selectedMode == .countup || selectedMode == .habit)
                        .opacity((selectedMode == .countup || selectedMode == .habit) ? 0.5 : 1.0)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminders")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)

                        if selectedMode == .countup || selectedMode == .habit {
                            Text("Reminders are available for countdown events.")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(ReminderPreset.allCases, id: \.self) { preset in
                                Button(action: {
                                    toggleReminder(preset.minutes)
                                }) {
                                    HStack {
                                        Text(preset.title)
                                            .font(.sabdeviRegular(size: 12))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedReminderOffsets.contains(preset.minutes) {
                                            Image(systemName: "checkmark")
                                                .font(.sabdeviBold(size: 12))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    // Font handled by appearance proxy above
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addEvent()
                    }
                    .disabled(eventName.isEmpty)
                    // Font handled by appearance proxy above
                }
            }
        }
    }
    
    private func addEvent() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let isoDate = dateFormatter.string(from: selectedDate)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = includeTime ? timeFormatter.string(from: selectedTime) : nil
        let reminders = selectedReminderOffsets.sorted().map { EventReminder(offsetMinutes: $0) }

        let newEvent = CustomEvent(
            name: eventName,
            date: isoDate,
            startDate: selectedMode == .countup ? isoDate : nil,
            category: selectedCategory,
            mode: selectedMode,
            recurrence: (selectedMode == .countup || selectedMode == .habit) ? .none : selectedRecurrence,
            timeOfDay: timeString,
            reminders: selectedMode == .countdown ? reminders : []
        )
        appState.customEvents.append(newEvent)
        
        // Auto-select this event if less than 5 custom events selected
        let customItem = DisplayItem.customEvent(id: newEvent.id)
        
        // Count currently selected custom events
        let customCount = appState.selectedDisplayItems.filter { item in
            if case .customEvent = item { return true }
            return false
        }.count
        
        if customCount < 5 && !appState.selectedDisplayItems.contains(customItem) {
            appState.selectedDisplayItems.append(customItem)
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
