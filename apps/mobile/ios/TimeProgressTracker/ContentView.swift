//
//  ContentView.swift
//  TimeProgressTracker
//
//  Main Content View
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLoadingScreen = true
    @State private var textAnimationComplete = false
    @State private var pageFadedIn = false
    @State private var startAnimations = false
    @StateObject private var audioPlayer = AudioPlayer()
    
    var body: some View {
        ZStack {
            // Always render MainHomeView (even if hidden) so SVGs can load
            if appState.hasCompletedOnboarding {
                MainHomeView(
                    onSVGsLoaded: {
                        print("✅ [ContentView] SVGs loaded callback received")
                    },
                    startAnimations: startAnimations
                )
                    .opacity(pageFadedIn ? 1 : 0.01) // Use 0.01 instead of 0 so view still renders
                    .allowsHitTesting(pageFadedIn)
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
                LoadingView(onTextAnimationComplete: {
                    print("✅ [ContentView] Text animation complete")
                    textAnimationComplete = true
                    if appState.hasCompletedOnboarding {
                        // If onboarding is complete, start main screen animation sequence
                        handleAnimationSequence()
                    } else {
                        // If onboarding not complete, show onboarding after text animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.8)) {
                                showLoadingScreen = false
                            }
                        }
                    }
                })
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: showLoadingScreen)
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .onAppear {
            print("✅ [ContentView] ContentView appeared, hasCompletedOnboarding: \(appState.hasCompletedOnboarding)")
            // Loading screen will show by default, text animation will trigger the next step
        }
        .onChange(of: appState.hasCompletedOnboarding) { completed in
            if completed && !pageFadedIn {
                // Onboarding just completed - show loading screen and trigger animation sequence
                print("✅ [ContentView] Onboarding just completed - showing loading screen")
                showLoadingScreen = true
                // Wait for text animation to complete (it will call handleAnimationSequence)
            }
        }
    }
    
    private func handleAnimationSequence() {
        // Step 1: Text animation is complete (already done)
        
        // Step 2: Fade in page
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("✅ [ContentView] Step 2: Fading in page")
            withAnimation(.easeOut(duration: 0.8)) {
                pageFadedIn = true
                showLoadingScreen = false
            }
            
            // Step 3: Start sun animation (after page fades in)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("✅ [ContentView] Step 3: Starting animations (sun, clouds, birds)")
                startAnimations = true
            }
        }
        
        // Play welcome chime sound 2 seconds after text animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ [ContentView] Playing welcome chime (2s delay after text animation)")
            audioPlayer.playSound(named: "welcome_chime", withExtension: "mp3")
        }
    }
}

