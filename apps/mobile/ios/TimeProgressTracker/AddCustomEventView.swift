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
                        Text("Date")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(appState.isDarkMode ? .white : .black)
                            .environment(\.locale, Locale(identifier: "en_US"))
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
        
        let newEvent = CustomEvent(name: eventName, date: isoDate)
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
}

