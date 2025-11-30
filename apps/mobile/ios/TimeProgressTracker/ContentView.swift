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
    @State private var svgsLoaded = false
    
    var body: some View {
        ZStack {
            // Always render MainHomeView (even if hidden) so SVGs can load
            if appState.hasCompletedOnboarding {
                MainHomeView(onSVGsLoaded: {
                    if !svgsLoaded {
                        svgsLoaded = true
                        fadeInMainContent()
                    }
                })
                    .opacity(showLoadingScreen ? 0.01 : 1) // Use 0.01 instead of 0 so view still renders
                    .allowsHitTesting(!showLoadingScreen)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                OnboardingView()
                    .opacity(showLoadingScreen ? 0 : 1)
                    .allowsHitTesting(!showLoadingScreen)
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            // Show loader on top
            if showLoadingScreen {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: showLoadingScreen)
    }
    
    private func fadeInMainContent() {
        // Fade out loader after SVGs are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showLoadingScreen = false
            }
        }
    }
}

