//
//  ProfileView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(ProfileViewModel.self) private var viewModel
    @FocusState private var isNumberFieldFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            Form {
                Section {
                    Text("This section is optional. The app works without it — filling it in just unlocks a few extra comparisons.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
//                        .listRowInsets(EdgeInsets())
                }
                
                Section("Currency") {
                    Picker("Currency", selection: $viewModel.profile.currency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.rawValue) (\(currency.symbol))")
                                .tag(currency)
                        }
                    }
                }
                
                Section("Net income") {
                    TextField("Salary", value: $viewModel.profile.salary, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isNumberFieldFocused)

                    Picker("Salary type", selection: $viewModel.profile.salaryType) {
                        Text("Monthly").tag(UserProfile.SalaryType.monthly)
                        Text("Weekly").tag(UserProfile.SalaryType.weekly)
                        Text("Hourly").tag(UserProfile.SalaryType.hourly)
                    }
                    .pickerStyle(.segmented)
                    
                    if viewModel.profile.salaryType != .hourly {
                        TextField("Hours per week", value: $viewModel.profile.hoursPerWeek, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isNumberFieldFocused)
                    }
                    
                    if let rate = viewModel.profile.computedHourlyRate {
                        HStack {
                            Text("Hourly rate")
                            Spacer()
                            Text(rate, format: .currency(code: viewModel.profile.currency.rawValue))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if !viewModel.isComplete {
                    Section {
                        Label("Complete your income to see work-time equivalents on your items.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNumberFieldFocused = false
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
