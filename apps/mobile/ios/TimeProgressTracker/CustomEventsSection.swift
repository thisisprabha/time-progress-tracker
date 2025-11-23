//
//  CustomEventsSection.swift
//  TimeProgressTracker
//
//  Custom Events Section in Settings
//

import SwiftUI

struct CustomEventsSection: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddEvent = false
    @State private var eventName = ""
    @State private var eventDate = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Events")
                .font(.sabdeviBold(size: 15 * 1.2))
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Button(action: {
                showAddEvent = true
            }) {
                HStack {
                    Text("Add Event")
                        .font(.sabdeviBold(size: 15 * 1.2))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.black)
                )
            }
            
            ForEach(appState.customEvents) { event in
                CustomEventRow(event: event)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView(eventName: $eventName, eventDate: $eventDate) {
                addEvent()
            }
        }
    }
    
    private func addEvent() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        if let date = dateFormatter.date(from: eventDate) {
            let isoFormatter = DateFormatter()
            isoFormatter.dateFormat = "yyyy-MM-dd"
            let isoDate = isoFormatter.string(from: date)
            
            let newEvent = CustomEvent(name: eventName, date: isoDate)
            appState.customEvents.append(newEvent)
            appState.saveSettings()
            
            eventName = ""
            eventDate = ""
            showAddEvent = false
        }
    }
}

struct CustomEventRow: View {
    let event: CustomEvent
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.sabdeviRegular(size: 15 * 1.2))
                    .foregroundColor(.primary)
                
                Text(event.calculateProgress().formattedDate)
                    .font(.sabdeviRegular(size: 13 * 1.2))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                appState.customEvents.removeAll { $0.id == event.id }
                appState.saveSettings()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddEventView: View {
    @Binding var eventName: String
    @Binding var eventDate: String
    let onAdd: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Name")
                        .font(.sabdeviBold(size: 15 * 1.2))
                        .foregroundColor(.primary)
                    
                    TextField("e.g., Birthday, Wedding", text: $eventName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.sabdeviRegular(size: 17 * 1.2))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date (DD/MM/YYYY)")
                        .font(.sabdeviBold(size: 15 * 1.2))
                        .foregroundColor(.primary)
                    
                    TextField("DD/MM/YYYY", text: $eventDate)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.sabdeviRegular(size: 17 * 1.2))
                        .keyboardType(.numbersAndPunctuation)
                }
                
                Spacer()
                
                Button(action: {
                    onAdd()
                    dismiss()
                }) {
                    Text("Add Event")
                        .font(.sabdeviBold(size: 17 * 1.2))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                        )
                }
                .disabled(eventName.isEmpty || eventDate.isEmpty)
                .opacity(eventName.isEmpty || eventDate.isEmpty ? 0.5 : 1.0)
            }
            .padding(20)
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


