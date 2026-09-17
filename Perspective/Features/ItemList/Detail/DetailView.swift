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
    
    // MARK: - Properties
    
    let item: Item
    let viewModel: ItemListViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]
    
    @State private var showingEdit = false
    
    private var currency: Currency { profileViewModel.profile.currency }
    private var currencyCode: String { currency.rawValue }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                bestValueBadge
                
                switch item.calculationMode {
                case .perDay:
                    costPerDayCard
                    nextThresholdBanner
                case .perUse:
                    costPerUseCard
                }
                
                workTimeBanner
                
                if item.calculationMode == .perUse {
                    costPerDaySecondaryCard
                }
            }
            .padding(20)
        }
        .background(Theme.background)
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
            AddItemView(itemToEdit: item, profileCurrency: currency)
        }
        .onAppear {
            NotificationManager.scheduleThresholdNotification(for: item, currency: currency)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 4) {
            Text(item.convertedPrice(to: currency), format: .currency(code: currencyCode))
                .font(Theme.serif(38))
                .foregroundStyle(Theme.text1)
            Text("purchased \(item.purchaseDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
        }
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
    
    // MARK: - Cost per day
    
    private var costPerDayCard: some View {
        VStack(spacing: 10) {
            Text("cost per day")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            Text(item.costPerDay(in: currency), format: .currency(code: currencyCode))
                .font(Theme.serif(32))
                .foregroundStyle(Theme.text1)
            
            comparisonBanner(for: item.costPerDay(in: currency))
            costPerDayChart
        }
        .themeCard()
    }
    
    private var costPerDaySecondaryCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("also costs \(item.costPerDay(in: currency).formatted(.currency(code: currencyCode))) / day since purchase")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            costPerDayChart
        }
        .themeCard()
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
        let convertedPrice = item.convertedPrice(to: currency)
        
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
            .foregroundStyle(Theme.slate)
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 140)
        .chartXScale(domain: (costPerDayHistory.first?.day ?? 1)...(costPerDayHistory.last?.day ?? 1))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Theme.border)
                AxisValueLabel {
                    if let day = value.as(Int.self), day > 0 {
                        Text("day \(day)")
                            .foregroundStyle(Theme.text3)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine().foregroundStyle(Theme.border)
                AxisValueLabel {
                    if let cost = value.as(Double.self) {
                        Text(cost, format: .currency(code: currencyCode))
                            .foregroundStyle(Theme.text3)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private var nextThresholdBanner: some View {
        Group {
            if let next = item.nextThreshold(in: currency) {
                ThemeBanner(
                    "\(next.daysUntil) day\(next.daysUntil > 1 ? "s" : "") until under \(next.value.formatted(.currency(code: currencyCode)))/day",
                    systemImage: "hourglass",
                    tint: Theme.slate,
                    background: Theme.slateBg
                )
            }
        }
    }
    
    // MARK: - Cost per use
    
    private var costPerUseCard: some View {
        VStack(spacing: 10) {
            Text("cost per use")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            if let cost = item.costPerUse(in: currency) {
                Text(cost, format: .currency(code: currencyCode))
                    .font(Theme.serif(32))
                    .foregroundStyle(Theme.text1)
                comparisonBanner(for: cost)
            } else {
                Text("—")
                    .font(Theme.serif(32))
                    .foregroundStyle(Theme.text3)
            }
            
            if let average = item.averageUsesPerWeek {
                Text("≈ \(average.formatted(.number.precision(.fractionLength(1)))) uses / week on average")
                    .font(.footnote)
                    .foregroundStyle(Theme.text2)
                    .padding(.bottom, 4)
            }
            
            Text("uses so far")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            HStack(spacing: 18) {
                stepButton(systemImage: "minus") {
                    if let last = item.usages.max(by: { $0.date < $1.date }) {
                        item.usages.removeAll { $0.id == last.id }
                        modelContext.delete(last)
                    }
                }
                .disabled(item.usages.isEmpty)
                .opacity(item.usages.isEmpty ? 0.35 : 1)
                
                Text("\(item.usages.count)")
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.text1)
                    .frame(minWidth: 52)
                    .contentTransition(.numericText())
                
                stepButton(systemImage: "plus") {
                    viewModel.logUsage(for: item)
                }
            }
            .padding(.top, 2)
        }
        .themeCard()
    }
    
    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation { action() }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.slate)
                .frame(width: 44, height: 44)
                .background(
                    Circle().stroke(Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Banners
    
    private var bestValueBadge: some View {
        Group {
            if item.calculationMode == .perDay,
               item.isBestValue(among: allItems, currency: currency) {
                ThemeBanner(
                    "your best value item right now",
                    systemImage: "star.fill",
                    tint: Theme.gold,
                    background: Theme.goldBg
                )
            }
        }
    }
    
    private var workTimeBanner: some View {
        Group {
            if let hourlyRate = profileViewModel.profile.computedHourlyRate {
                let cost = item.calculationMode == .perDay
                    ? item.costPerDay(in: currency)
                    : (item.costPerUse(in: currency) ?? item.convertedPrice(to: currency))
                
                if let text = WorkTime.longText(cost: cost, hourlyRate: hourlyRate) {
                    ThemeBanner(text, systemImage: "clock", tint: Theme.gold, background: Theme.goldBg)
                }
            }
        }
    }
    
    private func comparisonBanner(for value: Double) -> some View {
        Group {
            if let comparison = costComparison(for: value, in: currency) {
                ThemeBanner(comparison.text, tint: Theme.text2, background: Theme.cardAlt)
            }
        }
    }
}
