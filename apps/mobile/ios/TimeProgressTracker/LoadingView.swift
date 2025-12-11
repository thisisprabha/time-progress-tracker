//
//  LoadingView.swift
//  TimeProgressTracker
//
//  Loading screen with rotating messages
//

import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0
    var onTextAnimationComplete: (() -> Void)? = nil
    
    let primaryMessage = "Time  is  inevitable."
    let randomMessages = [
        "Your  time  is  valuable.",
        "Do  something  great  today.",
        "Every  moment  counts.",
        "Make  it  count.",
        "Time  waits  for  no  one."
    ]
    
    // Get a random message every time the app loads
    private var dailyMessage: String {
        let allMessages = [primaryMessage] + randomMessages
        return allMessages.randomElement() ?? primaryMessage
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Loading message - one random message per day
                // Use custom typewriter effect
                TypewriterText(text: dailyMessage, onAnimationComplete: {
                    onTextAnimationComplete?()
                })
                
                Spacer()
            }
        }
    }
}

struct TypewriterText: View {
    let text: String
    var onAnimationComplete: (() -> Void)? = nil
    @State private var characters: [String] = []
    @State private var opacity: Double = 0
    @State private var displayedCount: Int = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<characters.count, id: \.self) { index in
                Text(characters[index])
                    .font(.sabdeviBold(size: 24))
                    .foregroundColor(.primary)
                    .opacity(index < displayedCount ? 1 : 0)
            }
        }
        .onAppear {
            // Split text into characters (preserving spaces)
            characters = text.map { String($0) }
            
            // Animate character by character
            animateText()
        }
    }
    
    private func animateText() {
        guard displayedCount < characters.count else {
            // Animation complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onAnimationComplete?()
            }
            return
        }
        
        // Show next character
        withAnimation(.easeOut(duration: 0.05)) {
            displayedCount += 1
        }
        
        // Continue to next character
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateText()
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

