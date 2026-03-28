//
//  StatisticsView.swift
//  SleepOptimizer
//
//  통계 화면 — 기간별 수면 데이터, 차트, 인사이트 카드
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    // MARK: - 의존성
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - 수면 기록 쿼리
    @Query(sort: \SleepRecord.bedTime, order: .reverse)
    private var allRecords: [SleepRecord]

    /// 선택된 기간에 맞는 기록 필터링
    private var filteredRecords: [SleepRecord] {
        let calendar = Calendar.current
        let daysBack = viewModel.selectedPeriod.dayCount
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else {
            return []
        }
        return allRecords.filter { $0.bedTime >= startDate }
    }

    /// 평균 수면 시간 (시간 단위)
    private var averageDuration: Double {
        guard !filteredRecords.isEmpty else { return 0 }
        let total = filteredRecords.reduce(0.0) { $0 + $1.durationHours }
        return total / Double(filteredRecords.count)
    }

    /// 평균 품질 점수 (1~5)
    private var averageQualityScore: Double {
        let scored = filteredRecords.map { $0.quality.score }
        guard !scored.isEmpty else { return 0 }
        return Double(scored.reduce(0, +)) / Double(scored.count)
    }

    /// 권장 수면 시간 대비 달성률
    private var recommendedRatio: Double {
        let recommended = AppConstants.recommendedSleepHours
        guard averageDuration > 0 else { return 0 }
        return min(averageDuration / recommended * 100, 150)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 기간 선택 피커
                    periodPicker

                    // 요약 카드
                    summaryCards

                    // 수면 시간 차트
                    sleepChart

                    // 인사이트 카드
                    insightCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(AppColor.background)
            .navigationTitle("통계")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 기간 선택 피커
    private var periodPicker: some View {
        Picker("기간", selection: $viewModel.selectedPeriod) {
            Text("1주").tag(StatsPeriod.week)
            Text("1달").tag(StatsPeriod.month)
            Text("3달").tag(StatsPeriod.threeMonths)
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
    }

    // MARK: - 요약 카드 그리드
    private var summaryCards: some View {
        HStack(spacing: 12) {
            // 평균 수면
            summaryCard(
                title: "평균 수면",
                value: String(format: "%.1f", averageDuration),
                unit: "시간",
                icon: "moon.zzz.fill",
                color: AppColor.primary
            )

            // 수면 품질
            summaryCard(
                title: "수면 품질",
                value: String(format: "%.1f", averageQualityScore),
                unit: "/ 5",
                icon: "star.fill",
                color: AppColor.accent
            )

            // 권장 대비
            summaryCard(
                title: "권장 대비",
                value: String(format: "%.0f", recommendedRatio),
                unit: "%",
                icon: "target",
                color: recommendedRatio >= 90
                    ? AppColor.sleepGood
                    : recommendedRatio >= 70
                        ? AppColor.sleepFair
                        : AppColor.sleepPoor
            )
        }
    }

    /// 요약 카드 개별 뷰
    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppColor.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - 수면 시간 차트
    private var sleepChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일별 수면 시간")
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            if filteredRecords.isEmpty {
                // 데이터 없음 안내
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppColor.textSecondary)
                    Text("기록된 수면 데이터가 없습니다")
                        .font(.subheadline)
                        .foregroundColor(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                Chart(filteredRecords) { record in
                    BarMark(
                        x: .value("날짜", record.bedTime, unit: .day),
                        y: .value("수면 시간", record.durationHours)
                    )
                    .foregroundStyle(AppColor.qualityColor(for: record.quality))
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption2)
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                        AxisGridLine()
                            .foregroundStyle(AppColor.textSecondary.opacity(0.3))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 인사이트 카드
    private var insightCard: some View {
        let insight = SleepInsightService.shared.generateInsight(from: filteredRecords)

        return VStack(alignment: .leading, spacing: 12) {
            Label("수면 인사이트", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(AppColor.accent)

            // 트렌드
            HStack(spacing: 8) {
                Image(systemName: trendIconName(insight.trend))
                    .foregroundColor(trendColor(insight.trend))
                Text(insight.trend.displayName)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textPrimary)
            }

            // 팁
            Text(insight.tip)
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColor.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColor.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    /// 트렌드 아이콘 이름 반환
    private func trendIconName(_ trend: SleepTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    /// 트렌드 색상 반환
    private func trendColor(_ trend: SleepTrend) -> Color {
        switch trend {
        case .improving: return AppColor.sleepGood
        case .declining: return AppColor.sleepPoor
        case .stable: return AppColor.sleepFair
        }
    }
}

#Preview {
    StatisticsView(viewModel: StatisticsViewModel(premiumService: PremiumService()))
        .modelContainer(for: SleepRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}
