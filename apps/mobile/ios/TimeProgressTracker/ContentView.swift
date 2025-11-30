//
//  ContentView.swift
//  TimeProgressTracker
//
//  Main Content View
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLoadingScreen = true
    @State private var mainContentOpacity: Double = 0
    
    var body: some View {
        ZStack {
            if showLoadingScreen {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(2)
            }
            
            if appState.hasCompletedOnboarding {
                MainHomeView(onSVGsLoaded: {
                    fadeInMainContent()
                })
                    .opacity(mainContentOpacity)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                OnboardingView()
                    .opacity(mainContentOpacity)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: showLoadingScreen)
        .animation(.easeInOut(duration: 1.0), value: mainContentOpacity)
    }
    
    private func fadeInMainContent() {
        // Fade out loader, then fade in main content
        withAnimation(.easeOut(duration: 0.5)) {
            showLoadingScreen = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                mainContentOpacity = 1
            }
        }
    }
}

