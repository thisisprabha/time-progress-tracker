//
//  ContentView.swift
//  TimeProgressTracker
//
//  Main Content View
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainHomeView()
            } else {
                OnboardingView()
            }
        }
    }
}

