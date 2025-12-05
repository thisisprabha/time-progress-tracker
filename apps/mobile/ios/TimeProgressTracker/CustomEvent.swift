//
//  CustomEvent.swift
//  TimeProgressTracker
//
//  Custom Event Model
//

import Foundation

struct CustomEvent: Identifiable, Codable {
    let id: String
    let name: String
    let date: String // ISO format: YYYY-MM-DD
    let startDate: String // ISO format: YYYY-MM-DD
    
    init(id: String = UUID().uuidString, name: String, date: String, startDate: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        
        if let start = startDate {
            self.startDate = start
        } else {
            // Default to today
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.startDate = dateFormatter.string(from: Date())
        }
    }
    
    func calculateProgress() -> (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String, totalDays: Int, daysCompleted: Int) {
        let now = Date()
        let calendar = Calendar.current
        
        // Parse date string (YYYY-MM-DD format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let eventDate = dateFormatter.date(from: date) else {
            return (0, 0, false, false, false, "", 1, 0)
        }
        
        // Parse start date
        let start = dateFormatter.date(from: startDate) ?? Date()
        
        // Set dates to start of day
        let today = calendar.startOfDay(for: now)
        let eventDay = calendar.startOfDay(for: eventDate)
        let startDay = calendar.startOfDay(for: start)
        
        let diffTime = eventDay.timeIntervalSince(today)
        let diffDays = Int(diffTime / (24 * 60 * 60))
        
        // Calculate total duration and completed days
        let totalDuration = eventDay.timeIntervalSince(startDay)
        let totalDays = max(1, Int(totalDuration / (24 * 60 * 60)))
        
        let completedDuration = today.timeIntervalSince(startDay)
        let daysCompleted = max(0, Int(completedDuration / (24 * 60 * 60)))
        
        // Calculate weeks for events > 30 days
        let weeksLeft = Int(ceil(Double(abs(diffDays)) / 7.0))
        let useWeeks = abs(diffDays) > 30
        
        // Format date as DD/MM/YYYY
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd/MM/yyyy"
        let formattedDate = displayFormatter.string(from: eventDate)
        
        return (
            daysLeft: diffDays,
            weeksLeft: weeksLeft,
            useWeeks: useWeeks,
            isPast: diffDays < 0,
            isToday: diffDays == 0,
            formattedDate: formattedDate,
            totalDays: totalDays,
            daysCompleted: daysCompleted
        )
    }
}


