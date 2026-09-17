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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("This section is optional. Filling it in unlocks a few extra comparisons.")
                        .font(.footnote)
                        .foregroundStyle(Theme.text2)
                        .lineSpacing(3)
                    
                    currencySection(viewModel: viewModel)
                    incomeSection(viewModel: viewModel)
                    
                    if viewModel.isComplete {
                        Text("Every item will also be shown in minutes or hours of your work.")
                            .font(.footnote)
                            .foregroundStyle(Theme.gold)
                            .lineSpacing(3)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.goldBg, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isNumberFieldFocused = false }
                }
            }
        }
    }
    
    // MARK: - Currency
    
    private func currencySection(viewModel: ProfileViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Currency")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(Currency.allCases) { currency in
                    let isSelected = currency == viewModel.profile.currency
                    
                    Button {
                        viewModel.profile.currency = currency
                    } label: {
                        VStack(spacing: 6) {
                            Text(currency.flag)
                                .font(.system(size: 26))
                            Text(currency.rawValue)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(isSelected ? Theme.gold : Theme.text2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Theme.goldBg : Theme.cardAlt)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Theme.gold : Theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Income
    
    private func incomeSection(viewModel: ProfileViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Net income")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            VStack(alignment: .leading, spacing: 0) {
                TextField("0", value: $viewModel.profile.salary, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isNumberFieldFocused)
                    .font(Theme.serif(28))
                    .foregroundStyle(Theme.text1)
                    .padding(.vertical, 8)
                
                Picker("Salary type", selection: $viewModel.profile.salaryType) {
                    Text("Monthly").tag(UserProfile.SalaryType.monthly)
                    Text("Weekly").tag(UserProfile.SalaryType.weekly)
                    Text("Hourly").tag(UserProfile.SalaryType.hourly)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 10)
                
                if viewModel.profile.salaryType != .hourly {
                    Text("Hours worked / week")
                        .font(.footnote)
                        .foregroundStyle(Theme.text2)
                        .padding(.top, 4)
                    
                    TextField("0", value: $viewModel.profile.hoursPerWeek, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isNumberFieldFocused)
                        .font(Theme.serif(22))
                        .foregroundStyle(Theme.text1)
                        .padding(.vertical, 6)
                }
                
                if let rate = viewModel.profile.computedHourlyRate {
                    Divider()
                        .overlay(Theme.border)
                        .padding(.top, 8)
                    
                    HStack {
                        Text("Hourly rate")
                            .font(.subheadline)
                            .foregroundStyle(Theme.text2)
                        Spacer()
                        Text(rate, format: .currency(code: viewModel.profile.currency.rawValue))
                            .font(Theme.serif(18))
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.top, 14)
                }
            }
            .themeCard()
        }
    }
}

#Preview {
    ProfileView()
        .environment(ProfileViewModel())
}
