//
//  ItemListView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftData
import SwiftUI

struct ItemListView: View {
    
    // MARK: - Properties
    
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Query(sort: \Item.purchaseDate, order: .reverse) private var items: [Item]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ItemListViewModel?
    @State private var showingAddItem = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No items yet",
                        systemImage: "cart",
                        description: Text("Add your first item to see its real cost.")
                    )
                } else {
                    List {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            ZStack {
                                NavigationLink(value: item) { EmptyView() }
                                    .opacity(0)
                                itemRow(item, rank: index + 1)
                            }
                            .listRowBackground(Theme.card)
                            .listRowSeparatorTint(Theme.border)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item, viewModel: viewModel!)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView(profileCurrency: profileViewModel.profile.currency)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ItemListViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - Row
    
    private func itemRow(_ item: Item, rank: Int) -> some View {
        guard let viewModel else { return AnyView(EmptyView()) }
        let currency = profileViewModel.profile.currency
        let cost = viewModel.displayedCost(for: item, currency: currency)
        let workChip = profileViewModel.profile.computedHourlyRate.flatMap {
            WorkTime.shortText(cost: cost.value, hourlyRate: $0)
        }
        
        return AnyView(
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 5) {
                    Text("\(rank)")
                        .font(Theme.serif(13, weight: .regular))
                        .foregroundStyle(Theme.text3)
                    
                    Image(systemName: item.calculationMode == .perDay ? "calendar" : "hand.tap")
                        .font(.system(size: 11))
                        .foregroundStyle(item.calculationMode == .perDay ? Theme.teal : Theme.rust)
                }
                .frame(width: 18)
                .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.text1)
                    Text(subtitle(for: item))
                        .font(.caption)
                        .foregroundStyle(Theme.text3)
                }
                                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(cost.value, format: .currency(code: currency.rawValue))
                        .font(Theme.serif(19))
                        .foregroundStyle(Theme.text1)
                    Text("per \(cost.unit)")
                        .font(.caption2)
                        .foregroundStyle(Theme.text3)
                    
                    if let workChip {
                        Text("≈ \(workChip) of work")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.goldBg, in: Capsule())
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.vertical, 6)
        )
    }
    
    private func subtitle(for item: Item) -> String {
        let purchased = "Purchased \(item.purchaseDate.formatted(.relative(presentation: .named)))"
        guard item.calculationMode == .perUse else { return purchased }
        return "\(purchased) · \(item.usages.count) \(item.usages.count > 1 ? "uses" : "use")"
    }
    
    // MARK: - Sorting & actions
    
    private var sortedItems: [Item] {
        guard let viewModel else { return items }
        let currency = profileViewModel.profile.currency
        return items.sorted {
            viewModel.displayedCost(for: $0, currency: currency).value < viewModel.displayedCost(for: $1, currency: currency).value
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            viewModel?.delete(sortedItems[index])
        }
    }
}

#Preview {
    ItemListView()
        .modelContainer(for: Item.self, inMemory: true)
        .environment(ProfileViewModel())
}
