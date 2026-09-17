//
//  AddItemView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNumberFieldFocused: Bool
    
    @State private var name = ""
    @State private var price: Double?
    @State private var purchaseDate = Date.now
    @State private var calculationMode: CalculationMode = .perDay
    @State private var initialUsageCount: Int?
    
    private let characterLimit: Int = 30
    
    var itemToEdit: Item?
    
    init(itemToEdit: Item? = nil, profileCurrency: Currency) {
        self.itemToEdit = itemToEdit
        _name = State(initialValue: itemToEdit?.name ?? "")
        _price = State(initialValue: itemToEdit?.convertedPrice(to: profileCurrency))
        _purchaseDate = State(initialValue: itemToEdit?.purchaseDate ?? .now)
        _calculationMode = State(initialValue: itemToEdit?.calculationMode ?? .perDay)
    }
    
    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && (price ?? 0) > 0 && trimmed.count <= characterLimit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(name.count > characterLimit ? .red : .clear, lineWidth: 1)
                        )
                    HStack {
                        Text(profileViewModel.profile.currency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("Price", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isNumberFieldFocused)
                    }
                    DatePicker("Purchase date", selection: $purchaseDate, in: ...Date.now, displayedComponents: .date)
                } header: {
                    Text("General information")
                }
                
                Section {
                    Picker("Track cost by", selection: $calculationMode) {
                        Text("Per day").tag(CalculationMode.perDay)
                        Text("Per use").tag(CalculationMode.perUse)
                    }
                    .pickerStyle(.segmented)
                    
                    if calculationMode == .perUse && itemToEdit == nil {
                        TextField("Already used how many times?", value: $initialUsageCount, format: .number)
                            .keyboardType(.numberPad)
                            .focused($isNumberFieldFocused)
                    }
                } header: {
                    Text("Calculate the cost")
                } footer: {
                    Text(calculationMode == .perDay
                         ? "Cost drops automatically the longer you keep it."
                         : "Log each time you use it to see the cost per use go down.")
                }
                
                if !profileViewModel.isComplete {
                    Section {
                        Label("Add your income in Profile to see work-time comparisons on this item.", systemImage: "sparkles")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(name != "" ? name : "New item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNumberFieldFocused = false
                    }
                }
            }
        }
    }
    
    private func save() {
        if let itemToEdit {
            itemToEdit.name = name.trimmingCharacters(in: .whitespaces)
            itemToEdit.price = price ?? 0
            itemToEdit.currency = profileViewModel.profile.currency
            itemToEdit.purchaseDate = purchaseDate
            itemToEdit.calculationMode = calculationMode
            
            if calculationMode == .perDay {
                NotificationManager.scheduleThresholdNotification(for: itemToEdit, currency: profileViewModel.profile.currency)
            }
        } else {
            let item = Item(
                name: name.trimmingCharacters(in: .whitespaces),
                price: price ?? 0,
                purchaseDate: purchaseDate,
                calculationMode: calculationMode,
                currency: profileViewModel.profile.currency
            )
            modelContext.insert(item)
            
            if calculationMode == .perUse, let count = initialUsageCount, count > 0 {
                for _ in 0..<count {
                    item.usages.append(Usage(date: purchaseDate, item: item))
                }
            }
            
            if calculationMode == .perDay {
                NotificationManager.scheduleThresholdNotification(for: item, currency: profileViewModel.profile.currency)
            }
        }
        dismiss()
    }
}

#Preview {
    AddItemView(profileCurrency: .eur)
        .modelContainer(for: Item.self, inMemory: true)
        .environment(ProfileViewModel())
}
