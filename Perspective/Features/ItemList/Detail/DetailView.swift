//
//  DetailView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Charts
import SwiftData
import SwiftUI

struct ItemDetailView: View {
    
    // MARK: - Properties
    
    let item: Item
    let viewModel: ItemListViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]
    
    @State private var showingEdit = false
    
    private var currencyCode: String {
        profileViewModel.profile.currency.rawValue
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                bestValueBadge
                switch item.calculationMode {
                case .perDay:
                    costPerDayCard
                    nextThresholdCard(currency: profileViewModel.profile.currency)
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
            AddItemView(itemToEdit: item, profileCurrency: profileViewModel.profile.currency)
        }
        .onAppear {
            NotificationManager.scheduleThresholdNotification(for: item, currency: profileViewModel.profile.currency)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 2) {
            Text(item.convertedPrice(to: profileViewModel.profile.currency), format: .currency(code: currencyCode))
                .font(.title2.weight(.semibold))
            Text("purchased \(item.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Cost per day
    
    private var costPerDayCard: some View {
        VStack(spacing: 10) {
            Text("cost per day")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(item.costPerDay(in: profileViewModel.profile.currency), format: .currency(code: currencyCode))
                .font(.system(size: 30, weight: .semibold))
            comparisonBadge(for: item.costPerDay(in: profileViewModel.profile.currency))
            costPerDayChart
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var costPerDaySecondaryCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("also costs")
                Text(item.costPerDay(in: profileViewModel.profile.currency), format: .currency(code: currencyCode))
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
    
    private struct CostPoint: Identifiable {
        let id = UUID()
        let day: Int
        let cost: Double
    }
    
    private var costPerDayHistory: [CostPoint] {
        let totalDays = item.daysOwned
        let stepCount = min(totalDays, 20)
        guard stepCount > 0 else { return [] }
        let convertedPrice = item.convertedPrice(to: profileViewModel.profile.currency)
        
        return stride(from: 1, through: totalDays, by: max(1, totalDays / stepCount)).map { day in
            CostPoint(day: day, cost: convertedPrice / Double(day))
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
    
    private func nextThresholdCard(currency: Currency) -> some View {
        Group {
            if let next = item.nextThreshold(in: currency) {
                Label {
                    Text("\(next.daysUntil) day\(next.daysUntil > 1 ? "s" : "") until under \(next.value.formatted(.currency(code: currency.rawValue)))/day")
                } icon: {
                    Image(systemName: "hourglass")
                }
                .font(.caption)
                .foregroundStyle(.purple)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Cost per use
    
    private var costPerUseCard: some View {
        VStack(spacing: 10) {
            Text("cost per use")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let cost = item.costPerUse(in: profileViewModel.profile.currency) {
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
    
    // MARK: - Badges
    
    private var bestValueBadge: some View {
        Group {
            if item.calculationMode == .perDay, item.isBestValue(among: allItems, currency: profileViewModel.profile.currency) {
                Label("your best value item right now", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private func workTimeBadge(hourlyRate: Double) -> some View {
        let cost = item.calculationMode == .perDay ? item.costPerDay(in: profileViewModel.profile.currency) : (item.costPerUse(in: profileViewModel.profile.currency) ?? item.convertedPrice(to: profileViewModel.profile.currency))
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
