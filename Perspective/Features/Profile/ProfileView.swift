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
                    Text("This section is optional. Filling it in just unlocks a few extra comparisons.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(Currency.allCases) { currency in
                            Button {
                                viewModel.profile.currency = currency
                            } label: {
                                VStack(spacing: 6) {
                                    Text(currency.flag)
                                        .font(.system(size: 28))
                                    Text(currency.rawValue)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(currency == viewModel.profile.currency ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(currency == viewModel.profile.currency ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(currency == viewModel.profile.currency ? Color.accentColor : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Currency")
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
