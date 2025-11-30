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
    
    let messages = [
        "Your time is valuable.",
        "Do something great today.",
        "Time is inevitable."
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                Text(messages[messageIndex])
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
        
        // Schedule message rotation
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                messageIndex = (messageIndex + 1) % messages.count
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1
                }
            }
        }
    }
}

