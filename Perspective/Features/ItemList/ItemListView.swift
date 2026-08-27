//
//  ItemListView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Query(sort: \Item.purchaseDate, order: .reverse) private var items: [Item]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ItemListViewModel?
    @State private var showingAddItem = false
    
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
                        ForEach(sortedItems) { item in
                            NavigationLink(value: item) {
                                itemRow(item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
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
                AddItemView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ItemListViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    private func itemRow(_ item: Item) -> some View {
        guard let viewModel else { return AnyView(EmptyView()) }
        let cost = viewModel.displayedCost(for: item)
        
        return AnyView(
            HStack(spacing: 12) {
                Image(systemName: item.calculationMode == .perDay ? "calendar" : "hand.tap.fill")
                    .font(.caption)
                    .foregroundStyle(item.calculationMode == .perDay ? .green : .orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.body)
                    Text("Purchased \(item.purchaseDate.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if item.calculationMode == .perUse {
                        Text("\(item.usages.count) \(item.usages.count > 1 ? "uses" : "use")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(cost.value, format: .currency(code: profileViewModel.profile.currency.rawValue))
                    Text("per \(cost.unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        )
    }
    
    private var sortedItems: [Item] {
        guard let viewModel else { return items }
        return items.sorted {
            viewModel.displayedCost(for: $0).value < viewModel.displayedCost(for: $1).value
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
}
