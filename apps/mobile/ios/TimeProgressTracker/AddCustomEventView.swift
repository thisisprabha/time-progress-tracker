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
                }
                
                Spacer()
                
                Button(action: {
                    addEvent()
                }) {
                    Text("Add Event")
                        .font(.sabdeviBold(size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                        )
                }
                .disabled(eventName.isEmpty)
                .opacity(eventName.isEmpty ? 0.5 : 1.0)
            }
            .padding(20)
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.sabdeviRegular(size: 14))
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

