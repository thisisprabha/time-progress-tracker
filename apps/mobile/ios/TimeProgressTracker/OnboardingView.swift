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
    @State private var currentStep: Int = 1 // 1: Mindset, 2: Age, 3: Life Expectancy
    
    var body: some View {
        ZStack {
            appState.theme.backgroundColor(isDark: appState.isDarkMode)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Step 1: Mindset Selection
                if currentStep == 1 {
                    mindsetSelectionView
                }
                
                // Step 2: Age Selection
                if currentStep == 2 {
                    ageSelectionView
                }
                
                // Step 3: Life Expectancy Selection
                if currentStep == 3 {
                    lifeExpectancySelectionView
                }
                
                Spacer()
                
                // Footer Button
                Button(action: {
                    handleNextStep()
                }) {
                    Text(currentStep == 3 ? "Get  Started" : "Next")
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
    
    // MARK: - Step 1: Mindset Selection
    private var mindsetSelectionView: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 24) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .padding(.bottom, 10)
                
                Text("How  do  you  see  the  glass?")
                    .font(.sabdeviBold(size: 20))
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
                        .padding(.vertical, 18)
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
        }
    }
    
    // MARK: - Step 2: Age Selection
    private var ageSelectionView: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 24) {
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .padding(.bottom, 10)
                
                Text("What's  your  age?")
                    .font(.sabdeviBold(size: 20))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            
            Spacer()
            .frame(height: 50)
            
            // Age Slider
            VStack(spacing: 24) {
                Text("\(appState.userAge)")
                    .font(.sabdeviBold(size: 48))
                    .foregroundColor(.primary)
                
                Slider(value: Binding(
                    get: { Double(appState.userAge) },
                    set: { appState.userAge = Int($0) }
                ), in: 10...70, step: 1)
                .tint(.primary)
                .padding(.horizontal, 24)
                
                HStack {
                    Text("10")
                        .font(.sabdeviRegular(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("70")
                        .font(.sabdeviRegular(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Step 3: Life Expectancy Selection
    private var lifeExpectancySelectionView: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 24) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primary)
                    .padding(.bottom, 10)
                
                Text("Expected  life  expectancy")
                    .font(.sabdeviBold(size: 20))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            
            Spacer()
            .frame(height: 50)
            
            // Life Expectancy Buttons
            VStack(spacing: 16) {
                ForEach([60, 70, 80, 90], id: \.self) { expectancy in
                    Button(action: {
                        appState.lifeExpectancy = expectancy
                    }) {
                        HStack {
                            Text(expectancy == 90 ? "90+" : "\(expectancy)")
                                .font(.sabdeviBold(size: 16))
                                .foregroundColor(appState.lifeExpectancy == expectancy ? Color(.systemBackground) : .primary)
                            
                            Spacer()
                            
                            if appState.lifeExpectancy == expectancy {
                                Image(systemName: "checkmark")
                                    .font(.sabdeviBold(size: 16))
                                    .foregroundColor(Color(.systemBackground))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(appState.lifeExpectancy == expectancy ? Color.primary : Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(appState.lifeExpectancy == expectancy ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.lifeExpectancy)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Navigation
    private func handleNextStep() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            // Complete onboarding
            if appState.selectedDisplayItems.isEmpty || appState.selectedDisplayItems.count < 3 {
                appState.selectedDisplayItems = [.today, .month, .year]
            }
            withAnimation {
                appState.hasCompletedOnboarding = true
                appState.saveSettings()
            }
        }
    }
}
