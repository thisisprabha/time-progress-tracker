//
//  SettingsView.swift
//  TimeProgressTracker
//
//  Modern Minimal iOS Style Settings - Tabbed Layout
//

import SwiftUI
import UserNotifications
import UIKit
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable {
    case display = "Display"
    case mindset = "Mindset"
    case appearance = "Appearance"
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SettingsTab = .display
    
    // Add/Edit Event State
    @State private var presentedSheetItem: EventSheetItem? = nil
    @State private var showModeSelectionActionSheet: Bool = false
    @State private var selectedInitMode: EventMode = .countdown
    
    // Calendar Picker State
    @State private var showCalendarPicker: Bool = false
    
    // Toast Message State
    @State private var toastMessage: String? = nil
    
    // Notifications & Import/Export
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var exportURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var importStatusText: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    Picker("Settings Section", selection: $selectedTab) {
                        ForEach(SettingsTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    
                    // Tab Content
                    if selectedTab == .display {
                         DisplaySettingsView(
                            showModeSelection: $showModeSelectionActionSheet,
                            showCalendarPicker: $showCalendarPicker,
                            presentedSheetItem: $presentedSheetItem,
                            notificationStatus: $notificationStatus,
                            exportURL: $exportURL,
                            showShareSheet: $showShareSheet,
                            showImportPicker: $showImportPicker,
                            importStatusText: $importStatusText
                        )
                    } else if selectedTab == .mindset {
                        MindsetSettingsView()
                    } else {
                        AppearanceSettingsView()
                    }
                }
                
                // Toast Overlay
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.black.opacity(0.8)))
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(100)
                }
            }
            .navigationTitle("Configure")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body))
                }
            }
            .confirmationDialog("What kind of event?", isPresented: $showModeSelectionActionSheet, titleVisibility: .visible) {
                 Button("Countdown (e.g. Birthday)") {
                     presentedSheetItem = EventSheetItem(initialMode: .countdown)
                 }
                 Button("Count Up (e.g. Sobriety)") {
                     presentedSheetItem = EventSheetItem(initialMode: .countup)
                 }
                 Button("Habit (e.g. Daily Run)") {
                     presentedSheetItem = EventSheetItem(initialMode: .habit)
                 }
                 Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $presentedSheetItem) { item in
                AddCustomEventView(initialMode: item.initialMode, existingEvent: item.event)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showCalendarPicker) {
                CalendarEventPickerView(toastMessage: $toastMessage)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let didAccess = url.startAccessingSecurityScopedResource()
                    defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
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
        }
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .font(.system(size: 14))
        .onChange(of: toastMessage) { newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        toastMessage = nil
                    }
                }
            }
        }
    }
}

// MARK: - Mindset Tab

struct MindsetSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How do you view your journey?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Mindset", selection: $appState.perspective) {
                        ForEach(Perspective.allCases, id: \.self) { perspective in
                            Text(perspective == .halfFull ? "Half Full (Focus on Done)" : "Half Empty (Focus on Left)")
                                .tag(perspective)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: appState.perspective) { _ in
                        appState.saveSettings()
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Your Perspective")
            } footer: {
                Text("This changes how progress is displayed across the app and widgets.")
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Appearance Tab

struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPhotoPicker: Bool = false
    
    var body: some View {
        List {
            Section {
                Toggle("Dark Mode", isOn: $appState.isDarkMode)
                    .onChange(of: appState.isDarkMode) { _ in appState.saveSettings() }
                
                Picker("Widget Style", selection: $appState.widgetStyle) {
                    ForEach(WidgetStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .onChange(of: appState.widgetStyle) { _ in appState.saveSettings() }
            } header: {
                Text("Style")
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(imageData: $appState.customBackgroundImageData) {
                appState.saveSettings()
            }
        }
    }
}

// MARK: - Display Tab

struct DisplaySettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showModeSelection: Bool
    @Binding var showCalendarPicker: Bool
    @Binding var presentedSheetItem: EventSheetItem?
    
    // Bindings for parent actions
    @Binding var notificationStatus: UNAuthorizationStatus
    @Binding var exportURL: URL?
    @Binding var showShareSheet: Bool
    @Binding var showImportPicker: Bool
    @Binding var importStatusText: String?
    
    // Local filters
    @State private var eventCategoryFilter: EventCategoryFilter = .all
    
    var customPinnedCount: Int {
        appState.selectedDisplayItems.filter { item in
            if case .customEvent = item { return true }
            return false
        }.count
    }
    
    var filteredEvents: [CustomEvent] {
         let events: [CustomEvent]
         if let category = eventCategoryFilter.category {
             events = appState.customEvents.filter { $0.category == category }
         } else {
             events = appState.customEvents
         }
         return events.sorted { lhs, rhs in
              if lhs.mode != rhs.mode { return lhs.mode == .countdown }
              return lhs.name < rhs.name
         }
    }
    
    var body: some View {
        List {
            // 1. Default Events
            Section {
                 PredefinedItemRow(item: .today, icon: "sun.max", appState: appState)
                 PredefinedItemRow(item: .week, icon: "calendar", appState: appState)
                 PredefinedItemRow(item: .month, icon: "calendar.badge.clock", appState: appState)
                 PredefinedItemRow(item: .quarter, icon: "chart.pie", appState: appState)
                 PredefinedItemRow(item: .year, icon: "hourglass", appState: appState)
            } header: {
                Text("Default Events (Select max 3)")
            }
            
            // 2. My Events
            Section {
                if !appState.customEvents.isEmpty {
                    if filteredEvents.isEmpty {
                        Text("No \(eventCategoryFilter.displayName) events added")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(filteredEvents) { event in
                            Button(action: {
                                presentedSheetItem = EventSheetItem(event: event)
                            }) {
                                EventRowSystem(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteEvent(event)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    togglePin(for: event)
                                } label: {
                                    let isPinned = appState.selectedDisplayItems.contains(.customEvent(id: event.id))
                                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                } else {
                     Text("No events yet")
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity, alignment: .center)
                         .padding(.vertical, 20)
                }
            } header: {
                HStack {
                    Text("My Events")
                    Spacer()
                    
                    if !appState.customEvents.isEmpty {
                        HStack(spacing: 8) {
                            Text("\(customPinnedCount)/5 Pinned")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Menu {
                                Picker("Filter", selection: $eventCategoryFilter) {
                                    ForEach(EventCategoryFilter.allCases, id: \.self) { filter in
                                        Label(filter.displayName, systemImage: filter.icon).tag(filter)
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            // 3. Manage Events
            Section {
                Button(action: { showModeSelection = true }) {
                    Label("Create New Event", systemImage: "plus.circle")
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
                
                Button(action: { showCalendarPicker = true }) {
                    Label("Import from Calendar", systemImage: "calendar.badge.plus")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            } header: {
                 Text("Manage Events")
            }
            
            // 4. Life Progress Toggle
            Section {
                Toggle("Show Life Progress", isOn: $appState.showLifeProgress)
                     .onChange(of: appState.showLifeProgress) { _ in appState.saveSettings() }
            } header: {
                Text("Life Progress")
            }
            
            // 5. Data & Safety
            Section {
                Button("Export Backup") {
                    do {
                        exportURL = try AppBackupManager.exportBackup(appState: appState)
                        showShareSheet = (exportURL != nil)
                    } catch { importStatusText = "Export failed" }
                }
                
                Button("Import Backup") {
                    showImportPicker = true
                }
                if let status = importStatusText {
                    Text(status).font(.caption).foregroundColor(.secondary)
                }
            } header: {
                Text("Data & Safety")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func togglePin(for event: CustomEvent) {
        let customItem = DisplayItem.customEvent(id: event.id)
        if appState.selectedDisplayItems.contains(customItem) {
             if appState.selectedDisplayItems.count > 1 {
                 appState.selectedDisplayItems.removeAll { $0 == customItem }
             }
        } else {
             if customPinnedCount < 5 {
                 appState.selectedDisplayItems.append(customItem)
             }
        }
        appState.saveSettings()
    }
    
    private func deleteEvent(_ event: CustomEvent) {
        let customItem = DisplayItem.customEvent(id: event.id)
        appState.selectedDisplayItems.removeAll { $0 == customItem }
        appState.customEvents.removeAll { $0.id == event.id }
        appState.saveSettings()
    }
}

struct PredefinedItemRow: View {
    let item: DisplayItem
    let icon: String
    @ObservedObject var appState: AppState
    
    var body: some View {
        let isSelected = appState.selectedDisplayItems.contains(item)
        let predefinedSelectedCount = appState.selectedDisplayItems.filter { item in
            if case .customEvent = item { return false }
            return true
        }.count
        
        Button(action: {
            if isSelected {
                if appState.selectedDisplayItems.count > 1 {
                    appState.selectedDisplayItems.removeAll { $0 == item }
                }
            } else {
                if predefinedSelectedCount < 3 {
                    appState.selectedDisplayItems.append(item)
                }
            }
            appState.saveSettings()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)
                
                Text(item.displayName(in: appState))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct EventRowSystem: View {
    let event: CustomEvent
    @EnvironmentObject var appState: AppState
    
    var isPinned: Bool {
        appState.selectedDisplayItems.contains(.customEvent(id: event.id))
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(event.summaryText())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(.vertical, 4)
    }
}

enum EventCategoryFilter: String, CaseIterable {
    case all, personal, work, family, custom
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .personal: return "Personal"
        case .work: return "Work"
        case .family: return "Family"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .personal: return "person.circle"
        case .work: return "briefcase.circle"
        case .family: return "house.circle"
        case .custom: return "star.circle"
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
        case .halfFull: return "Half Full"
        case .halfEmpty: return "Half Empty"
        }
    }
}

extension TimeMode {
    var displayName: String {
        switch self {
        case .twentyFourHour: return "24 Hours"
        case .nineToFive: return "9 to 5"
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

// MARK: - Calendar Picker

import EventKit

struct CalendarEventPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Binding var toastMessage: String?
    
    @State private var events: [EKEvent] = []
    @State private var isLoading = true
    @State private var hasAccess = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading Calendar...")
                } else if !hasAccess {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Calendar Access Required")
                            .font(.headline)
                        Text("Please allow access to your calendar to import events.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding()
                } else if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Upcoming Events")
                            .font(.headline)
                        Text("Found no events in the next 90 days.")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(events, id: \.eventIdentifier) { event in
                            Button(action: {
                                importEvent(event)
                            }) {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Text(formatDate(event.startDate))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            if !event.isAllDay {
                                                Text("•")
                                                Text(formatTime(event.startDate))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pick Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            loadEvents()
        }
    }
    
    private func loadEvents() {
        Task {
            isLoading = true
            let granted = await CalendarImportManager.shared.requestAccess()
            hasAccess = granted
            if granted {
                events = await CalendarImportManager.shared.fetchEvents()
            }
            isLoading = false
        }
    }
    
    private func importEvent(_ event: EKEvent) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let isoDate = dateFormatter.string(from: event.startDate)
        let timeOfDay = event.isAllDay ? nil : timeFormatter.string(from: event.startDate)
        
        var recurrence: EventRecurrence = .none
        if let rule = event.recurrenceRules?.first {
            switch rule.frequency {
            case .weekly: recurrence = .weekly
            case .monthly: recurrence = .monthly
            case .yearly: recurrence = .yearly
            default: recurrence = .none
            }
        }
        
        let newEvent = CustomEvent(
            name: event.title,
            date: isoDate,
            startDate: isoDate,
            category: .personal,
            mode: .countdown,
            recurrence: recurrence,
            timeOfDay: timeOfDay,
            reminders: []
        )
        
        appState.customEvents.append(newEvent)
        
        let customCount = appState.selectedDisplayItems.filter {
            if case .customEvent = $0 { return true }
            return false
        }.count
        
        if customCount < 5 {
            appState.selectedDisplayItems.append(.customEvent(id: newEvent.id))
        }
        
        appState.saveSettings()
        toastMessage = "Event imported: \(event.title)"
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EventSheetItem: Identifiable {
    let id = UUID()
    var event: CustomEvent? = nil
    var initialMode: EventMode = .countdown
}

