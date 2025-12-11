//
//  OnboardingView.swift
//  TimeProgressTracker
//
//  Onboarding Screen
//
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Header Section
                VStack(spacing: 24) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    Text("How  do  you  see  the  glass?")
                        .font(.sabdeviBold(size: 20)) // Slightly larger
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Text("Choose  your  perspective  to  track  time  progress.")
                        .font(.sabdeviBold(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                .frame(height: 50)
                
                // Selection Section
                VStack(spacing: 16) {
                    ForEach(Perspective.allCases, id: \.self) { perspective in
                        Button(action: {
                            appState.perspective = perspective
                        }) {
                            HStack {
                                Text(perspective.displayName)
                                .font(.sabdeviBold(size: 16))
                                    .foregroundColor(appState.perspective == perspective ? Color(.systemBackground) : .primary)
                                
                                Spacer()
                                
                                if appState.perspective == perspective {
                                    Image(systemName: "checkmark")
                                    .font(.sabdeviBold(size: 16))
                                        .foregroundColor(Color(.systemBackground))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18) // Slightly taller
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                  .fill(appState.perspective == perspective ? Color.primary : Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(appState.perspective == perspective ? 1.02 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.perspective)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer Button
                Button(action: {
                    // Complete onboarding
                    if appState.selectedDisplayItems.isEmpty || appState.selectedDisplayItems.count < 3 {
                        appState.selectedDisplayItems = [.today, .month, .year]
                    }
                    withAnimation {
                        appState.hasCompletedOnboarding = true
                        appState.saveSettings()
                    }
                }) {
                    Text("Get  Started")
                        .font(.sabdeviBold(size: 16))
                        .foregroundColor(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }
}

