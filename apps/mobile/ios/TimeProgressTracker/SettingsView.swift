//
//  SettingsView.swift
//  TimeProgressTracker
//
//  Modern Minimal iOS Style Settings
//

import SwiftUI
import UserNotifications
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var eventCategoryFilter: EventCategoryFilter = .all
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var exportURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var importStatusText: String? = nil
    @State private var calendarImportText: String? = nil
    @State private var showPhotoPicker: Bool = false

    private var customPinnedCount: Int {
        appState.selectedDisplayItems.filter { item in
            if case .customEvent = item { return true }
            return false
        }.count
    }

    private var filteredEvents: [CustomEvent] {
        let events: [CustomEvent]
        if let category = eventCategoryFilter.category {
            events = appState.customEvents.filter { $0.category == category }
        } else {
            events = appState.customEvents
        }

        return events.sorted { lhs, rhs in
            if lhs.mode != rhs.mode {
                return lhs.mode == .countdown
            }
            if lhs.mode == .countup && rhs.mode == .countup {
                return lhs.nextRelevantDate() > rhs.nextRelevantDate()
            }
            return lhs.nextRelevantDate() < rhs.nextRelevantDate()
        }
    }

    private func displayIndex(for item: DisplayItem) -> Int? {
        appState.selectedDisplayItems.firstIndex(of: item).map { $0 + 1 }
    }

    private func togglePin(for event: CustomEvent) {
        let customItem = DisplayItem.customEvent(id: event.id)
        let isPinned = appState.selectedDisplayItems.contains(customItem)

        if isPinned {
            if appState.selectedDisplayItems.count > 1 {
                appState.selectedDisplayItems.removeAll { $0 == customItem }
            }
        } else if customPinnedCount < 5 {
            appState.selectedDisplayItems.append(customItem)
        }

        appState.saveSettings()
    }

    private func deleteEvent(_ event: CustomEvent) {
        let customItem = DisplayItem.customEvent(id: event.id)
        appState.selectedDisplayItems.removeAll { $0 == customItem }
        appState.customEvents.removeAll { $0.id == event.id }
        appState.saveSettings()
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized: return "Notifications: On"
        case .provisional: return "Notifications: Provisional"
        case .denied: return "Notifications: Off (Denied)"
        case .notDetermined: return "Notifications: Not Requested"
        case .ephemeral: return "Notifications: Temporary"
        @unknown default: return "Notifications: Unknown"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                appState.theme.groupedBackgroundColor(isDark: appState.isDarkMode)
                    .ignoresSafeArea()
                
                List {
                    // Appearance Section
                    Section {
                        Toggle(isOn: $appState.isDarkMode) {
                            Text("Dark  Mode")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }
                        .tint(appState.theme.accentColor(isDark: appState.isDarkMode))
                        .onChange(of: appState.isDarkMode) { _ in
                            appState.saveSettings()
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    } header: {
                        Text("Appearance")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }

                    // Theme Section
                    Section {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            SettingsRow(
                                title: theme.displayName,
                                isSelected: appState.theme == theme
                            ) {
                                appState.theme = theme
                                appState.saveSettings()
                            }
                        }

                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            Text("Add  custom  background")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.gray)
                                .underline()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .listRowBackground(Color.clear)

                        if appState.customBackgroundImageData != nil {
                            Button(action: {
                                appState.customBackgroundImageData = nil
                                appState.saveSettings()
                            }) {
                                Text("Remove  background")
                                    .font(.sabdeviRegular(size: 12))
                                    .foregroundColor(.gray)
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Theme")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
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

                    // Widget Style Section
                    Section {
                        ForEach(WidgetStyle.allCases, id: \.self) { style in
                            SettingsRow(
                                title: style.displayName,
                                isSelected: appState.widgetStyle == style
                            ) {
                                appState.widgetStyle = style
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Widget  Style")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // Customize Display Section
                    Section {
                        Text("Choose  3  time  items  to  display")
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)

                        // Count separate types
                        let predefinedCount = appState.selectedDisplayItems.filter { item in
                            if case .customEvent = item { return false }
                            return true
                        }.count

                        // Predefined items
                        let predefinedItems: [DisplayItem] = [.today, .week, .month, .quarter, .year]

                        ForEach(predefinedItems, id: \.self) { item in
                            let isSelected = appState.selectedDisplayItems.contains(item)
                            let index = displayIndex(for: item)

                            SettingsRow(
                                title: item.displayName(in: appState),
                                isSelected: isSelected,
                                isDisabled: !isSelected && predefinedCount >= 3,
                                showNumber: isSelected,
                                number: index
                            ) {
                                if isSelected {
                                    if appState.selectedDisplayItems.count > 1 {
                                        appState.selectedDisplayItems.removeAll { $0 == item }
                                    }
                                } else {
                                    if predefinedCount < 3 {
                                        appState.selectedDisplayItems.append(item)
                                    }
                                }
                                appState.saveSettings()
                            }
                        }
                    } header: {
                        Text("Customize Display")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }

                    // Events Section
                    Section {
                        Text("Pin  up  to  5  events  to  show  on  Home  +  widgets")
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)

                        Picker("Filter", selection: $eventCategoryFilter) {
                            ForEach(EventCategoryFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName)
                                    .font(.sabdeviRegular(size: 12))
                                    .tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)

                        if filteredEvents.isEmpty {
                            Text("No  events  yet")
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredEvents, id: \.id) { event in
                                let customItem = DisplayItem.customEvent(id: event.id)
                                let isPinned = appState.selectedDisplayItems.contains(customItem)
                                let index = displayIndex(for: customItem)

                                EventManagementRow(
                                    event: event,
                                    isPinned: isPinned,
                                    isPinDisabled: !isPinned && customPinnedCount >= 5,
                                    displayIndex: index,
                                    onPinToggle: { togglePin(for: event) },
                                    onDelete: { deleteEvent(event) }
                                )
                            }
                        }

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
                        Text("Events")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }

                    // Backup & Export Section
                    Section {
                        Button(action: {
                            do {
                                exportURL = try AppBackupManager.exportBackup(appState: appState)
                                showShareSheet = exportURL != nil
                            } catch {
                                importStatusText = "Export failed"
                            }
                        }) {
                            Text("Export  Backup")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            showImportPicker = true
                        }) {
                            Text("Import  Backup")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            do {
                                exportURL = try EventCSVExporter.export(events: appState.customEvents)
                                showShareSheet = exportURL != nil
                            } catch {
                                importStatusText = "Export failed"
                            }
                        }) {
                            Text("Export  Events  (CSV)")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }

                        if let importStatusText {
                            Text(importStatusText)
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Backup  &  Export")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }

                    // Calendar Import Section
                    Section {
                        Button(action: {
                            Task {
                                let result = await CalendarImportManager.shared.importUpcomingEvents(into: appState)
                                calendarImportText = "Imported \(result.imported) • Skipped \(result.skipped)"
                            }
                        }) {
                            Text("Import  Calendar  Events")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }

                        if let calendarImportText {
                            Text(calendarImportText)
                                .font(.sabdeviRegular(size: 12))
                                .foregroundColor(.secondary)
                                .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text("Calendar  Import")
                            .font(.sabdeviBold(size: 16))
                            .foregroundColor(.primary)
                    }
                    
                    // MARK: - Apple Watch Section (Hidden - To be implemented)
                    /*
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
                    */
                    
                    // Notification Section
                    Section {
                        Toggle(isOn: $appState.remindersEnabled) {
                            Text("Event  Reminders")
                                .font(.sabdeviRegular(size: 14))
                                .foregroundColor(.primary)
                        }
                        .tint(appState.theme.accentColor(isDark: appState.isDarkMode))
                        .onChange(of: appState.remindersEnabled) { enabled in
                            Task {
                                if enabled {
                                    let granted = await NotificationManager.shared.requestAuthorization()
                                    notificationStatus = await NotificationManager.shared.authorizationStatus()
                                    if !granted {
                                        appState.remindersEnabled = false
                                    }
                                } else {
                                    NotificationManager.shared.cancelAll()
                                }
                                appState.saveSettings()
                            }
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))

                        Text(notificationStatusText)
                            .font(.sabdeviRegular(size: 12))
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)

                        if notificationStatus == .denied {
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Open  Settings")
                                    .font(.sabdeviRegular(size: 12))
                                    .foregroundColor(.gray)
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowBackground(Color.clear)
                        }
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
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .task {
            notificationStatus = await NotificationManager.shared.authorizationStatus()
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess { url.stopAccessingSecurityScopedResource() }
                }
                do {
                    try AppBackupManager.importBackup(from: url, appState: appState)
                    importStatusText = "Backup imported"
                } catch {
                    importStatusText = "Import failed"
                }
            case .failure:
                importStatusText = "Import cancelled"
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(imageData: $appState.customBackgroundImageData) {
                appState.saveSettings()
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
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                if showNumber, let num = number {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 24, height: 24)
                        Text("\(num)")
                            .font(.sabdeviBold(size: 14))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
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
            .padding(.vertical, 8)
        }
        .disabled(isDisabled)
        .listRowBackground(
            isSelected 
                ? Color(.secondarySystemGroupedBackground)
                : Color(.systemGroupedBackground)
        )
    }
}

struct EventManagementRow: View {
    let event: CustomEvent
    let isPinned: Bool
    let isPinDisabled: Bool
    let displayIndex: Int?
    let onPinToggle: () -> Void
    let onDelete: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            if let index = displayIndex {
                ZStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 24, height: 24)
                    Text("\(index)")
                        .font(.sabdeviBold(size: 14))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(event.summaryText())
                    .font(.sabdeviRegular(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onPinToggle) {
                HStack(spacing: 4) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.sabdeviRegular(size: 12))
                    Text(isPinned ? "Pinned" : "Pin")
                        .font(.sabdeviRegular(size: 12))
                }
                .foregroundColor(isPinned ? .primary : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isPinDisabled)
            .opacity(isPinDisabled ? 0.4 : 1.0)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.sabdeviRegular(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
}

enum EventCategoryFilter: String, CaseIterable {
    case all
    case personal
    case work
    case family
    case custom

    var displayName: String {
        switch self {
        case .all: return "All"
        case .personal: return "Personal"
        case .work: return "Work"
        case .family: return "Family"
        case .custom: return "Custom"
        }
    }

    var category: EventCategory? {
        switch self {
        case .all: return nil
        case .personal: return .personal
        case .work: return .work
        case .family: return .family
        case .custom: return .custom
        }
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

extension WidgetStyle {
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .minimal: return "Minimal"
        }
    }
}
