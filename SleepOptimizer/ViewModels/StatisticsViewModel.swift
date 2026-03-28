// StatisticsViewModel.swift
// SleepOptimizer
//
// 수면 통계 및 인사이트를 처리하는 뷰모델

import Foundation
import SwiftData
import Combine

// MARK: - 통계 기간 열거형

/// 통계 조회 기간
enum StatsPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case threeMonths

    var id: String { rawValue }

    /// 한국어 표시 이름
    var displayName: String {
        switch self {
        case .week:
            return "1주일"
        case .month:
            return "1개월"
        case .threeMonths:
            return "3개월"
        }
    }

    /// 해당 기간의 일수
    var dayCount: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .threeMonths:
            return 90
        }
    }
}

/// 수면 통계 데이터를 집계하고 인사이트를 제공하는 뷰모델
@MainActor
final class StatisticsViewModel: ObservableObject {

    // MARK: - 발행 프로퍼티

    /// 선택된 통계 기간
    @Published var selectedPeriod: StatsPeriod = .week

    /// 조회된 수면 기록 데이터
    @Published var sleepData: [SleepRecord] = []

    /// 생성된 수면 인사이트
    @Published var insight: SleepInsight?

    // MARK: - 의존성

    /// SwiftData 모델 컨텍스트
    private(set) var modelContext: ModelContext?

    /// 프리미엄 서비스
    let premiumService: PremiumService

    /// 수면 인사이트 분석 서비스
    let insightService: SleepInsightService

    // MARK: - 초기화

    /// 뷰모델 초기화
    /// - Parameters:
    ///   - premiumService: 프리미엄 기능 접근 서비스
    ///   - insightService: 수면 인사이트 분석 서비스
    init(
        premiumService: PremiumService,
        insightService: SleepInsightService = .shared
    ) {
        self.premiumService = premiumService
        self.insightService = insightService
    }

    // MARK: - 컨텍스트 설정

    /// SwiftData 모델 컨텍스트를 주입한다
    /// - Parameter context: SwiftData 모델 컨텍스트
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - 데이터 로드

    /// 선택된 기간에 해당하는 수면 기록을 조회하고 인사이트를 생성한다
    func loadData() {
        guard let modelContext else {
            assertionFailure("ModelContext가 설정되지 않았습니다")
            return
        }

        let calendar = Calendar.current
        guard let startDate = calendar.date(
            byAdding: .day,
            value: -selectedPeriod.dayCount,
            to: Date()
        ) else {
            return
        }

        // 선택 기간 내 기록 조회
        let predicate = #Predicate<SleepRecord> { record in
            record.createdAt >= startDate
        }

        var descriptor = FetchDescriptor<SleepRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            sleepData = try modelContext.fetch(descriptor)
            // 인사이트 생성
            insight = insightService.generateInsight(from: sleepData)
        } catch {
            assertionFailure("수면 데이터 조회 실패: \(error.localizedDescription)")
            sleepData = []
            insight = nil
        }
    }

    // MARK: - 계산 프로퍼티

    /// 평균 수면 시간 (시간 단위)
    var averageDuration: Double {
        guard !sleepData.isEmpty else { return 0 }
        let totalHours = sleepData.reduce(0.0) { $0 + $1.durationHours }
        return totalHours / Double(sleepData.count)
    }

    /// 평균 수면 품질 점수 (1~5)
    var averageQualityScore: Double {
        guard !sleepData.isEmpty else { return 0 }
        let totalScore = sleepData.reduce(0.0) { sum, record in
            sum + Double(record.quality.score)
        }
        return totalScore / Double(sleepData.count)
    }

    /// 가장 좋았던 수면 기록
    var bestDay: SleepRecord? {
        sleepData.max { lhs, rhs in
            if lhs.quality.score == rhs.quality.score {
                return lhs.durationHours < rhs.durationHours
            }
            return lhs.quality.score < rhs.quality.score
        }
    }

    /// 가장 나빴던 수면 기록
    var worstDay: SleepRecord? {
        sleepData.min { lhs, rhs in
            if lhs.quality.score == rhs.quality.score {
                return lhs.durationHours < rhs.durationHours
            }
            return lhs.quality.score < rhs.quality.score
        }
    }
}
