//
//  LoadingView.swift
//  TimeProgressTracker
//
//  Loading screen with rotating messages
//

import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0
    
    let message = "Time  is  inevitable."
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Loading message - show only one static text
                Text(message)
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

