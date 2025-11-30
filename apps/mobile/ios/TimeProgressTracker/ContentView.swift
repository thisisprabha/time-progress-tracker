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
    
    var body: some View {
        Group {
            if showLoadingScreen {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeOut(duration: 1.0)) {
                                showLoadingScreen = false
                            }
                        }
                    }
            } else if appState.hasCompletedOnboarding {
                MainHomeView()
            } else {
                OnboardingView()
            }
        }
    }
}

