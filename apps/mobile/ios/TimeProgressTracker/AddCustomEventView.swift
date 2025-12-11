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
    
    var body: some View {
        NavigationView {
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
                        .accentColor(.black)
                        .environment(\.locale, Locale(identifier: "en_US"))
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.sabdeviRegular(size: 14))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addEvent()
                    }
                    .font(.sabdeviBold(size: 14))
                    .disabled(eventName.isEmpty)
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
        
        // Auto-select this event if less than 3 items selected
        let customItem = DisplayItem.customEvent(id: newEvent.id)
        if appState.selectedDisplayItems.count < 3 && !appState.selectedDisplayItems.contains(customItem) {
            appState.selectedDisplayItems.append(customItem)
        }
        
        appState.saveSettings()
        dismiss()
    }
}

