//
//  SettingsView.swift
//  TimeProgressTracker
//
//  Modern Minimal iOS Style Settings
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                List {
                    // Your Mindset Section
                    Section {
                        ForEach(Perspective.allCases, id: \.self) { perspective in
                            SettingsRow(
                                title: perspective.displayName,
                                isSelected: appState.perspective == perspective
                            ) {
                                appState.perspective = perspective
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Your Mindset")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // Daily Tracking Section
                    Section {
                        ForEach(TimeMode.allCases, id: \.self) { mode in
                            SettingsRow(
                                title: mode.displayName,
                                isSelected: appState.timeMode == mode
                            ) {
                                appState.timeMode = mode
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Daily  Tracking")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // Customize Display Section
                    Section {
                        Text("Choose  3  items  to  display")
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                        
                        // Predefined items
                        let predefinedItems: [DisplayItem] = [.today, .week, .month, .quarter, .year]
                        
                        ForEach(predefinedItems, id: \.self) { item in
                            let isSelected = appState.selectedDisplayItems.contains(item)
                            let index = isSelected ? appState.selectedDisplayItems.firstIndex(of: item) : nil
                            
                            SettingsRow(
                                title: item.displayName(in: appState),
                                isSelected: isSelected,
                                isDisabled: !isSelected && appState.selectedDisplayItems.count >= 3,
                                showNumber: isSelected,
                                number: index != nil ? index! + 1 : nil
                            ) {
                                if isSelected {
                                    if appState.selectedDisplayItems.count > 1 {
                                        appState.selectedDisplayItems.removeAll { $0 == item }
                                    }
                                } else {
                                    if appState.selectedDisplayItems.count < 3 {
                                        appState.selectedDisplayItems.append(item)
                                    }
                                }
                                appState.saveSettings()
                            }
                        }
                        
                        // Add your events button (after predefined items, only if there are no custom events yet)
                        if appState.customEvents.isEmpty {
                            Button(action: {
                                appState.showAddEvent = true
                            }) {
                                Text("Add  your  events")
                                    .font(.sabdeviRegular(size: 12))
                                    .foregroundColor(.gray)
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowBackground(Color.clear)
                        }
                        
                        // Custom events list - each as individual selectable item
                        ForEach(appState.customEvents, id: \.id) { event in
                            let customItem = DisplayItem.customEvent(id: event.id)
                            let isSelected = appState.selectedDisplayItems.contains(customItem)
                            let index = isSelected ? appState.selectedDisplayItems.firstIndex(of: customItem) : nil
                            
                            HStack {
                                SettingsRow(
                                    title: event.name,
                                    isSelected: isSelected,
                                    isDisabled: !isSelected && appState.selectedDisplayItems.count >= 3,
                                    showNumber: isSelected,
                                    number: index != nil ? index! + 1 : nil
                                ) {
                                    if isSelected {
                                        if appState.selectedDisplayItems.count > 1 {
                                            appState.selectedDisplayItems.removeAll { $0 == customItem }
                                        }
                                    } else {
                                        if appState.selectedDisplayItems.count < 3 {
                                            appState.selectedDisplayItems.append(customItem)
                                        }
                                    }
                                    appState.saveSettings()
                                }
                                
                                // Delete button for custom events
                                Button(action: {
                                    // Remove from selected items if selected
                                    appState.selectedDisplayItems.removeAll { $0 == customItem }
                                    // Remove from custom events
                                    appState.customEvents.removeAll { $0.id == event.id }
                                    appState.saveSettings()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.sabdeviRegular(size: 14))
                                        .foregroundColor(.red)
                                        .padding(.leading, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Add your events button (at the bottom, always visible)
                        Button(action: {
                            appState.showAddEvent = true
                        }) {
                            Text("Add  your  events")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.gray)
                                .underline()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Customize Display")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // Apple Watch Section
                    Section {
                        Text("Choose  what  to  display  on  Apple  Watch")
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                        
                        let watchItems: [DisplayItem] = [.today, .week, .month, .quarter, .year]
                        ForEach(watchItems, id: \.self) { item in
                            let isSelected = appState.watchComplicationItem == item
                            
                            SettingsRow(
                                title: item.displayName(in: appState),
                                isSelected: isSelected
                            ) {
                                appState.watchComplicationItem = item
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Apple  Watch")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // Notification Section
                    Section {
                        Text("Weekly  progress  updates  every  Monday")
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    } header: {
                        Text("Notification")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.sabdeviRegular(size: 17))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $appState.showAddEvent) {
                AddCustomEventView()
                    .environmentObject(appState)
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let isSelected: Bool
    var isDisabled: Bool = false
    var showNumber: Bool = false
    var number: Int? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if showNumber, let num = number {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height: 24)
                        Text("\(num)")
                            .font(.sabdeviBold(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                }
                
                Text(title)
                    .font(isSelected ? .sabdeviBold(size: 14) : .sabdeviRegular(size: 14))
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.sabdeviBold(size: 14))
                        .foregroundColor(.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .listRowBackground(Color(.systemBackground))
    }
}

extension Perspective {
    var displayName: String {
        switch self {
        case .halfFull: return "Half  Full"
        case .halfEmpty: return "Half  Empty"
        }
    }
}

extension TimeMode {
    var displayName: String {
        switch self {
        case .twentyFourHour: return "24  Hours"
        case .nineToFive: return "9  to  5"
        }
    }
}
