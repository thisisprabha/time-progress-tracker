//
//  LoadingView.swift
//  TimeProgressTracker
//
//  Loading screen with rotating messages
//

import SwiftUI

struct LoadingView: View {
    @State private var messageIndex = 0
    @State private var opacity: Double = 0
    
    let primaryMessage = "Time is inevitable."
    let randomMessages = [
        "Your time is valuable.",
        "Do something great today.",
        "Every moment counts.",
        "Make it count.",
        "Time waits for no one."
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Loading message - show primary message first, then random ones
                Text(messageIndex == 0 ? primaryMessage : randomMessages.randomElement() ?? primaryMessage)
                    .font(.sabdeviBold(size: 24))
                    .foregroundColor(.black)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear(perform: startLoadingAnimation)
    }
    
    private func startLoadingAnimation() {
        // Initial fade in
        withAnimation(.easeIn(duration: 1.0)) {
            opacity = 1
        }
        
        // Schedule message rotation - show primary first, then random messages
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // After first message, show random ones
                if messageIndex == 0 {
                    messageIndex = 1
                } else {
                    // Keep showing random messages
                    messageIndex = Int.random(in: 1..<randomMessages.count + 1)
                }
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1
                }
            }
        }
    }
}

