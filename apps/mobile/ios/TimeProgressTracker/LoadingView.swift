//
//  LoadingView.swift
//  TimeProgressTracker
//
//  Loading screen with rotating messages
//

import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0
    
    let primaryMessage = "Time  is  inevitable."
    let randomMessages = [
        "Your  time  is  valuable.",
        "Do  something  great  today.",
        "Every  moment  counts.",
        "Make  it  count.",
        "Time  waits  for  no  one."
    ]
    
    // Get one random message per day (same message all day, different next day)
    private var dailyMessage: String {
        let allMessages = [primaryMessage] + randomMessages
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 0
        
        // Use day of year as seed for consistent random selection per day
        var generator = SeededRandomNumberGenerator(seed: UInt64(dayOfYear))
        let randomIndex = Int.random(in: 0..<allMessages.count, using: &generator)
        return allMessages[randomIndex]
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Loading message - one random message per day
                Text(dailyMessage)
                    .font(.sabdeviBold(size: 24))
                    .foregroundColor(.black)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Simple fade in
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1
            }
        }
    }
}

// Seeded random number generator for consistent daily selection
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}

