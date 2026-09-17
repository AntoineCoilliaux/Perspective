//
//  SummaryView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import Charts
import SwiftData
import SwiftUI

struct SummaryView: View {
    @Query private var items: [Item]
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State private var viewModel = SummaryViewModel()
    
    private var currency: Currency { profileViewModel.profile.currency }
    private var currencyCode: String { currency.rawValue }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to summarize yet",
                        systemImage: "chart.bar",
                        description: Text("Add a few items to see your overall trend.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            heroCard
                            cumulativeInvestmentCard
                            costPerDayEvolutionCard
                            highlightsCard
                            metricsRow
                        }
                        .padding(20)
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle("Summary")
        }
    }
    
    // MARK: - Hero
    
    private var heroCard: some View {
        VStack(spacing: 4) {
            if let rate = profileViewModel.profile.computedHourlyRate {
                let hours = viewModel.totalWorkHoursInvested(items: items, currency: currency, hourlyRate: rate)
                Text("\(hours.formatted(.number.precision(.fractionLength(0)))) h")
                    .font(Theme.serif(40))
                    .foregroundStyle(Theme.gold)
                Text("of work invested in your items")
                    .font(.footnote)
                    .foregroundStyle(Theme.text2)
            } else {
                Text(viewModel.totalInvested(items: items, currency: currency), format: .currency(code: currencyCode))
                    .font(Theme.serif(40))
                    .foregroundStyle(Theme.gold)
                Text("invested in your items")
                    .font(.footnote)
                    .foregroundStyle(Theme.text2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .themeCard()
    }
    
    // MARK: - Total invested
    
    private var cumulativeInvestmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("total invested")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            let points = viewModel.cumulativeInvestment(items: items, currency: currency)
            
            if points.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Total", point.value)
                    )
                    .foregroundStyle(Theme.slate)
                    .interpolationMethod(.stepEnd)
                }
                .frame(height: 140)
                .chartXAxis { dateAxis }
                .chartYAxis { currencyAxis }
            }
        }
        .themeCard()
    }
    
    // MARK: - Cost/day trend
    
    private var costPerDayEvolutionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cost / day trend")
                .font(.footnote)
                .foregroundStyle(Theme.text2)
            
            let points = viewModel.costPerDayEvolution(items: items, currency: currency)
            
            if points.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Cost", point.value)
                    )
                    .foregroundStyle(Theme.teal)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 140)
                .chartXAxis { dateAxis }
                .chartYAxis { currencyAxis }
            }
        }
        .themeCard()
    }
    
    private var emptyChartPlaceholder: some View {
        Text("Not enough data yet")
            .font(.footnote)
            .foregroundStyle(Theme.text3)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
    }
    
    private var dateAxis: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 3)) { _ in
            AxisGridLine().foregroundStyle(Theme.border)
            AxisValueLabel(format: .dateTime.month(.abbreviated).year())
                .foregroundStyle(Theme.text3)
        }
    }
    
    private var currencyAxis: some AxisContent {
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
    
    // MARK: - Rankings
    
    private var highlightsCard: some View {
        Group {
            if let highlights = viewModel.mostAndLeastCostEffective(items: items, currency: currency) {
                let count = viewModel.dailyItemCount(items: items)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("your per day items, ranked")
                        .font(.footnote)
                        .foregroundStyle(Theme.text2)
                        .padding(.bottom, 10)
                    
                    highlightRow(rank: 1, label: "best value", highlight: highlights.best)
                    Divider().overlay(Theme.border)
                    highlightRow(rank: count, label: "least used value", highlight: highlights.worst)
                }
                .themeCard()
            }
        }
    }
    
    private func highlightRow(rank: Int, label: String, highlight: SummaryViewModel.ItemHighlight) -> some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(Theme.serif(13, weight: .regular))
                .foregroundStyle(Theme.text3)
                .frame(width: 18, alignment: .leading)
            
            Text(highlight.item.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.text1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(highlight.costPerDay, format: .currency(code: currencyCode))
                    .font(Theme.serif(17))
                    .foregroundStyle(Theme.text1)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.text3)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Totals
    
    private var metricsRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    title: "cost/day (daily items)",
                    value: viewModel.totalCostPerDay(items: items, currency: currency).formatted(.currency(code: currencyCode)),
                    tint: Theme.teal,
                    background: Theme.tealBg
                )
                
                metricCard(
                    title: "cost/use (per-use items)",
                    value: viewModel.totalCostPerUse(items: items, currency: currency).formatted(.currency(code: currencyCode)),
                    tint: Theme.rust,
                    background: Theme.rustBg
                )
            }
            
            if let hourlyRate = profileViewModel.profile.computedHourlyRate {
                let totalCost = viewModel.totalCostPerDay(items: items, currency: currency)
                    + viewModel.totalCostPerUse(items: items, currency: currency)
                if let text = WorkTime.shortText(cost: totalCost, hourlyRate: hourlyRate) {
                    metricCard(
                        title: "combined work time",
                        value: text,
                        tint: Theme.slate,
                        background: Theme.slateBg
                    )
                }
            }
        }
    }
    
    private func metricCard(title: String, value: String, tint: Color, background: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.text2)
            Text(value)
                .font(Theme.serif(22))
                .foregroundStyle(tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: Theme.bannerRadius))
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: Item.self, inMemory: true)
        .environment(ProfileViewModel())
}
