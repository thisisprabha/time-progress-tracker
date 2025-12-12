//
//  LifeDataSelectionView.swift
//  TimeProgressTracker
//
//  Reusable view for selecting age and life expectancy
//

import SwiftUI

struct LifeDataSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var currentStep: Int = 1 // 1: Age, 2: Life Expectancy
    @State private var tempAge: Int
    @State private var tempLifeExpectancy: Int
    
    init(age: Int, lifeExpectancy: Int) {
        _tempAge = State(initialValue: age)
        _tempLifeExpectancy = State(initialValue: lifeExpectancy)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Step 1: Age Selection
                if currentStep == 1 {
                    ageSelectionView
                }
                
                // Step 2: Life Expectancy Selection
                if currentStep == 2 {
                    lifeExpectancySelectionView
                }
                
                Spacer()
                
                // Footer Button
                Button(action: {
                    handleNextStep()
                }) {
                    Text(currentStep == 2 ? "Done" : "Next")
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
    
    // MARK: - Step 1: Age Selection
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
                Text("\(tempAge)")
                    .font(.sabdeviBold(size: 48))
                    .foregroundColor(.primary)
                
                Slider(value: Binding(
                    get: { Double(tempAge) },
                    set: { tempAge = Int($0) }
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
    
    // MARK: - Step 2: Life Expectancy Selection
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
                        tempLifeExpectancy = expectancy
                    }) {
                        HStack {
                            Text(expectancy == 90 ? "90+" : "\(expectancy)")
                                .font(.sabdeviBold(size: 16))
                                .foregroundColor(tempLifeExpectancy == expectancy ? Color(.systemBackground) : .primary)
                            
                            Spacer()
                            
                            if tempLifeExpectancy == expectancy {
                                Image(systemName: "checkmark")
                                    .font(.sabdeviBold(size: 16))
                                    .foregroundColor(Color(.systemBackground))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tempLifeExpectancy == expectancy ? Color.primary : Color.secondary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(tempLifeExpectancy == expectancy ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tempLifeExpectancy)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Navigation
    private func handleNextStep() {
        if currentStep < 2 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            // Save values
            appState.userAge = tempAge
            appState.lifeExpectancy = tempLifeExpectancy
            appState.saveSettings()
            dismiss()
        }
    }
}

