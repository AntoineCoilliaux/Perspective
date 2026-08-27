//
//  DetailView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftData
import SwiftUI
import Charts

struct ItemDetailView: View {
    let item: Item
    let viewModel: ItemListViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingEdit = false
    
    private var currencyCode: String {
        profileViewModel.profile.currency.rawValue
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                
                switch item.calculationMode {
                case .perDay:
                    costPerDayCard
                case .perUse:
                    costPerUseCard
                }
                
                if let hourlyRate = profileViewModel.profile.computedHourlyRate {
                    workTimeBadge(hourlyRate: hourlyRate)
                }
                
                if item.calculationMode == .perUse {
                    costPerDaySecondaryCard
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddItemView(itemToEdit: item)
        }
    }
    
    private var header: some View {
        VStack(spacing: 2) {
            Text(item.price, format: .currency(code: currencyCode))
                .font(.title2.weight(.semibold))
            Text("purchased \(item.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var costPerDayCard: some View {
        VStack(spacing: 10) {
            Text("cost per day")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(item.costPerDay, format: .currency(code: currencyCode))
                .font(.system(size: 30, weight: .semibold))
            comparisonBadge(for: item.costPerDay)
            costPerDayChart
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var costPerUseCard: some View {
        VStack(spacing: 10) {
            Text("cost per use")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let cost = item.costPerUse {
                Text(cost, format: .currency(code: currencyCode))
                    .font(.system(size: 30, weight: .semibold))
                comparisonBadge(for: cost)
            } else {
                Text("—")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            if let average = item.averageUsesPerWeek {
                Text("~\(average.formatted(.number.precision(.fractionLength(1)))) uses/week on average")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("Uses so far")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            
            HStack(spacing: 24) {
                Button {
                    withAnimation {
                        if let last = item.usages.max(by: { $0.date < $1.date }) {
                            item.usages.removeAll { $0.id == last.id }
                            modelContext.delete(last)
                        }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                }
                .disabled(item.usages.isEmpty)
                
                Text("\(item.usages.count)")
                    .font(.title2.weight(.semibold))
                    .frame(minWidth: 40)
                    .contentTransition(.numericText())
                
                Button {
                    withAnimation {
                        viewModel.logUsage(for: item)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func workTimeBadge(hourlyRate: Double) -> some View {
        let cost = item.calculationMode == .perDay ? item.costPerDay : (item.costPerUse ?? item.price)
        let hours = cost / hourlyRate
        
        return Label {
            Text(workTimeText(hours: hours))
        } icon: {
            Image(systemName: "clock")
        }
        .font(.caption)
        .foregroundStyle(.tint)
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func workTimeText(hours: Double) -> String {
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "equals \(minutes) min of your work"
        } else {
            return "equals \(hours.formatted(.number.precision(.fractionLength(1))))h of your work"
        }
    }
    
    private struct CostPoint: Identifiable {
        let id = UUID()
        let day: Int
        let cost: Double
    }
    
    private var costPerDayHistory: [CostPoint] {
        let totalDays = item.daysOwned
        let stepCount = min(totalDays, 20)
        guard stepCount > 0 else { return [] }
        
        return stride(from: 1, through: totalDays, by: max(1, totalDays / stepCount)).map { day in
            CostPoint(day: day, cost: item.price / Double(day))
        }
    }
    
    private var costPerDayChart: some View {
        Chart(costPerDayHistory) { point in
            LineMark(
                x: .value("Day", point.day),
                y: .value("Cost", point.cost)
            )
            .foregroundStyle(.tint)
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 140)
        .chartXScale(domain: (costPerDayHistory.first?.day ?? 1)...(costPerDayHistory.last?.day ?? 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let day = value.as(Int.self), day > 0 {
                        Text("day \(day)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let cost = value.as(Double.self) {
                        Text(cost, format: .currency(code: currencyCode))
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private var costPerDaySecondaryCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("also costs")
                Text(item.costPerDay, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
                Text("per day since purchase")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            costPerDayChart
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func comparisonBadge(for value: Double) -> some View {
        Group {
            if let comparison = costComparison(for: value, in: profileViewModel.profile.currency) {
                Label(comparison.text, systemImage: "")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
