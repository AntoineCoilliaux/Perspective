//
//  SummaryView.swift
//  Perspective
//
//  Created by Antoine Coilliaux on 25/08/2026.
//

import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Query private var items: [Item]
    @Environment(ProfileViewModel.self) private var profileViewModel
    @State private var viewModel = SummaryViewModel()
    
    private var currencyCode: String {
        profileViewModel.profile.currency.rawValue
    }
    
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
                            monthlySpendingCard(viewModel: viewModel)
                            costPerDayEvolutionCard(viewModel: viewModel)
                            metricsRow(viewModel: viewModel)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
    
    private func monthlySpendingCard(viewModel: SummaryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("spending by month")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Chart(viewModel.monthlySpending(items: items)) { point in
                BarMark(
                    x: .value("Month", point.date, unit: .month),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(.tint)
                .cornerRadius(4)
                .annotation(position: .top) {
                    Text(point.total, format: .currency(code: currencyCode))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func costPerDayEvolutionCard(viewModel: SummaryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cost/day trend")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            let points = viewModel.costPerDayEvolution(items: items)
            
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
    
    private func metricsRow(viewModel: SummaryViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    title: "cost/day (daily items)",
                    value: viewModel.totalCostPerDay(items: items).formatted(.currency(code: currencyCode)),
                    tint: .green
                )
                
                metricCard(
                    title: "cost/use (per-use items)",
                    value: viewModel.totalCostPerUse(items: items).formatted(.currency(code: currencyCode)),
                    tint: .orange
                )
            }
            
            if let hourlyRate = profileViewModel.profile.computedHourlyRate {
                let totalCost = viewModel.totalCostPerDay(items: items) + viewModel.totalCostPerUse(items: items)
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
}

#Preview {
    SummaryView()
        .modelContainer(for: Item.self, inMemory: true)
        .environment(ProfileViewModel())
}
