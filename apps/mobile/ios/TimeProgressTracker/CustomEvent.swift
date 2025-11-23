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
    
    init(id: String = UUID().uuidString, name: String, date: String) {
        self.id = id
        self.name = name
        self.date = date
    }
    
    func calculateProgress() -> (daysLeft: Int, weeksLeft: Int, useWeeks: Bool, isPast: Bool, isToday: Bool, formattedDate: String) {
        let now = Date()
        let calendar = Calendar.current
        
        // Parse date string (YYYY-MM-DD format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let eventDate = dateFormatter.date(from: date) else {
            return (0, 0, false, false, false, "")
        }
        
        // Set both dates to start of day
        let today = calendar.startOfDay(for: now)
        let eventDay = calendar.startOfDay(for: eventDate)
        
        let diffTime = eventDay.timeIntervalSince(today)
        let diffDays = Int(diffTime / (24 * 60 * 60))
        
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
            formattedDate: formattedDate
        )
    }
}


