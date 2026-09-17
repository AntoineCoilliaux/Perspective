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
    
    private var currencyCode: String {
        profileViewModel.profile.currency.rawValue
    }
    
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
                        VStack(spacing: 16) {
                            cumulativeInvestmentCard(viewModel: viewModel)
                            costPerDayEvolutionCard(viewModel: viewModel)
                            metricsRow(viewModel: viewModel)
                            highlightsCard(viewModel: viewModel)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
    
    // MARK: - Spending by month
    
    private func cumulativeInvestmentCard(viewModel: SummaryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("total invested")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            let points = viewModel.cumulativeInvestment(items: items, currency: profileViewModel.profile.currency)
            
            if points.isEmpty {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 140)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Total", point.value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.stepEnd)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).year())
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
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Cost/day trend
    
    private func costPerDayEvolutionCard(viewModel: SummaryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cost/day trend")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            let points = viewModel.costPerDayEvolution(items: items, currency: profileViewModel.profile.currency)
            
            if points.isEmpty {
                Text("Not enough data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 140)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Cost", point.value)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Rankings
    
    private func highlightsCard(viewModel: SummaryViewModel) -> some View {
        Group {
            if let highlights = viewModel.mostAndLeastCostEffective(items: items, currency: profileViewModel.profile.currency) {
                VStack(spacing: 12) {
                    Text("your per day items, ranked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    highlightRow(
                        icon: "arrow.down.circle.fill",
                        tint: .green,
                        label: "best value",
                        highlight: highlights.best
                    )
                    
                    Divider()
                    
                    highlightRow(
                        icon: "arrow.up.circle.fill",
                        tint: .red,
                        label: "least used value",
                        highlight: highlights.worst
                    )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Totals
    
    private func metricsRow(viewModel: SummaryViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    title: "cost/day (daily items)",
                    value: viewModel.totalCostPerDay(items: items, currency: profileViewModel.profile.currency).formatted(.currency(code: currencyCode)),
                    tint: .green
                )
                
                metricCard(
                    title: "cost/use (per-use items)",
                    value: viewModel.totalCostPerUse(items: items, currency: profileViewModel.profile.currency).formatted(.currency(code: currencyCode)),
                    tint: .orange
                )
            }
            
            if let hourlyRate = profileViewModel.profile.computedHourlyRate {
                let totalCost = viewModel.totalCostPerDay(items: items, currency: profileViewModel.profile.currency) + viewModel.totalCostPerUse(items: items, currency: profileViewModel.profile.currency)
                let hours = totalCost / hourlyRate
                metricCard(
                    title: "combined work time",
                    value: hours < 1
                        ? "\(Int(hours * 60)) min"
                        : "\(hours.formatted(.number.precision(.fractionLength(1))))h",
                    tint: .blue
                )
            }
        }
    }
    
    // MARK: - Reusable rows
    
    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func highlightRow(icon: String, tint: Color, label: String, highlight: SummaryViewModel.ItemHighlight) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(tint)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(highlight.item.name)
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(highlight.costPerDay, format: .currency(code: currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(for: Item.self, inMemory: true)
        .environment(ProfileViewModel())
}
