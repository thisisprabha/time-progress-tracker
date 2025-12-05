//
//  OnboardingView.swift
//  TimeProgressTracker
//
//  Onboarding Screen
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                if currentStep == 0 {
                    WelcomeStep()
                } else if currentStep == 1 {
                    PerspectiveSelectionStep()
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.sabdeviRegular(size: 16 * 0.7))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentStep < 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            // Complete onboarding - set default display items based on perspective
                            if appState.selectedDisplayItems.isEmpty || appState.selectedDisplayItems.count < 3 {
                                appState.selectedDisplayItems = [.today, .month, .year]
                            }
                            appState.hasCompletedOnboarding = true
                            appState.saveSettings()
                        }
                    }) {
                        Text(currentStep < 1 ? "Next" : "Get  Started")
                            .font(.sabdeviBold(size: 16 * 0.7))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.fill")
                .font(.system(size: 80))
                .foregroundColor(.black)
            
            Text("How  do  you  see  the  glass?")
                .font(.sabdeviBold(size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Text("Choose  your  perspective  to  track  time  progress.")
                .font(.sabdeviBold(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)
        }
    }
}

struct PerspectiveSelectionStep: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Half Full or Half Empty?")
            .font(.sabdeviBold(size: 16))
                .foregroundColor(.black)
            
            Text("Your  choice  will  determine  how  time  progress  is  displayed.")
            .font(.sabdeviBold(size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal,40)
            
            VStack(spacing: 12) {
                ForEach(Perspective.allCases, id: \.self) { perspective in
                    Button(action: {
                        appState.perspective = perspective
                    }) {
                        HStack {
                            Text(perspective.displayName)
                            .font(.sabdeviBold(size: 16))
                                .foregroundColor(appState.perspective == perspective ? .white : .black)
                            
                            Spacer()
                            
                            if appState.perspective == perspective {
                                Image(systemName: "checkmark")
                                .font(.sabdeviBold(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                              .fill(appState.perspective == perspective ? Color.black : Color.secondary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

