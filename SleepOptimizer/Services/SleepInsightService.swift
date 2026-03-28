//
//  SleepInsightService.swift
//  SleepOptimizer
//
//  수면 인사이트 및 팁 제공 서비스
//

import Foundation

/// 수면 트렌드
enum SleepTrend: String {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"

    /// 한국어 표시 이름
    var displayName: String {
        switch self {
        case .improving: return "개선 중"
        case .declining: return "악화 중"
        case .stable: return "안정적"
        }
    }
}

/// 수면 인사이트 결과
struct SleepInsight {
    /// 평균 수면 시간 (시간 단위)
    let averageDuration: Double

    /// 평균 수면 품질 점수 (1~5)
    let averageQuality: Double

    /// 수면 일관성 점수 (0~100, 취침 시각 편차 기반)
    let consistencyScore: Double

    /// 수면 트렌드
    let trend: SleepTrend

    /// 수면 팁 (한국어)
    let tip: String
}

/// 수면 인사이트 서비스
final class SleepInsightService {
    /// 싱글톤 인스턴스
    static let shared = SleepInsightService()

    private init() {}

    /// 수면 기록 배열로부터 인사이트 생성
    /// - Parameter records: 수면 기록 배열
    /// - Returns: 수면 인사이트
    func generateInsight(from records: [SleepRecord]) -> SleepInsight {
        guard !records.isEmpty else {
            return SleepInsight(
                averageDuration: 0,
                averageQuality: 0,
                consistencyScore: 0,
                trend: .stable,
                tip: "수면 기록을 추가하면 맞춤 인사이트를 제공합니다."
            )
        }

        let averageDuration = calculateAverageDuration(records)
        let averageQuality = calculateAverageQuality(records)
        let consistencyScore = calculateConsistency(records)
        let trend = calculateTrend(records)
        let tip = selectTip(
            averageDuration: averageDuration,
            averageQuality: averageQuality,
            consistencyScore: consistencyScore,
            trend: trend
        )

        return SleepInsight(
            averageDuration: averageDuration,
            averageQuality: averageQuality,
            consistencyScore: consistencyScore,
            trend: trend,
            tip: tip
        )
    }

    // MARK: - 내부 계산 함수

    /// 평균 수면 시간 계산 (시간 단위)
    private func calculateAverageDuration(_ records: [SleepRecord]) -> Double {
        let totalHours = records.reduce(0.0) { $0 + $1.durationHours }
        return totalHours / Double(records.count)
    }

    /// 평균 수면 품질 점수 계산
    private func calculateAverageQuality(_ records: [SleepRecord]) -> Double {
        let totalScore = records.reduce(0) { $0 + $1.quality.score }
        return Double(totalScore) / Double(records.count)
    }

    /// 수면 일관성 점수 계산 (취침 시각의 표준편차 기반, 0~100)
    private func calculateConsistency(_ records: [SleepRecord]) -> Double {
        guard records.count >= 2 else { return 100.0 }

        /// 각 취침 시각을 자정 기준 분 단위로 변환
        let calendar = Calendar.current
        let bedTimeMinutes: [Double] = records.map { record in
            let components = calendar.dateComponents([.hour, .minute], from: record.bedTime)
            var minutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
            /// 자정 이후 취침(새벽)은 +1440으로 처리하여 연속성 유지
            if minutes < 720 {
                minutes += 1440
            }
            return minutes
        }

        let mean = bedTimeMinutes.reduce(0, +) / Double(bedTimeMinutes.count)
        let variance = bedTimeMinutes.reduce(0) { $0 + pow($1 - mean, 2) } / Double(bedTimeMinutes.count)
        let stdDev = sqrt(variance)

        /// 표준편차 0분 → 100점, 120분(2시간) 이상 → 0점
        let maxDeviation: Double = 120.0
        let score = max(0, min(100, (1.0 - stdDev / maxDeviation) * 100.0))
        return score
    }

    /// 수면 트렌드 계산 (최근 절반 vs 이전 절반 비교)
    private func calculateTrend(_ records: [SleepRecord]) -> SleepTrend {
        guard records.count >= 4 else { return .stable }

        let sorted = records.sorted { $0.bedTime < $1.bedTime }
        let midIndex = sorted.count / 2
        let olderHalf = Array(sorted[..<midIndex])
        let newerHalf = Array(sorted[midIndex...])

        let olderAvg = calculateAverageQuality(olderHalf)
        let newerAvg = calculateAverageQuality(newerHalf)

        let difference = newerAvg - olderAvg
        if difference > 0.3 {
            return .improving
        } else if difference < -0.3 {
            return .declining
        } else {
            return .stable
        }
    }

    /// 수면 패턴에 기반한 팁 선택
    private func selectTip(
        averageDuration: Double,
        averageQuality: Double,
        consistencyScore: Double,
        trend: SleepTrend
    ) -> String {
        /// 수면 시간 부족
        if averageDuration < 6.0 {
            return shortSleepTips.randomElement() ?? defaultTip
        }

        /// 수면 시간 과다
        if averageDuration > 9.5 {
            return longSleepTips.randomElement() ?? defaultTip
        }

        /// 수면 품질 낮음
        if averageQuality < 2.5 {
            return poorQualityTips.randomElement() ?? defaultTip
        }

        /// 일관성 낮음
        if consistencyScore < 50.0 {
            return inconsistentTips.randomElement() ?? defaultTip
        }

        /// 악화 추세
        if trend == .declining {
            return decliningTips.randomElement() ?? defaultTip
        }

        /// 전반적으로 양호
        return goodSleepTips.randomElement() ?? defaultTip
    }

    // MARK: - 팁 풀

    private let defaultTip = "규칙적인 수면 습관이 건강의 기본입니다."

    /// 수면 시간 부족 팁
    private let shortSleepTips = [
        "수면 시간이 부족합니다. 성인 기준 7~9시간 수면이 권장됩니다.",
        "잠이 부족하면 집중력과 면역력이 떨어집니다. 취침 시간을 앞당겨 보세요.",
        "매일 30분씩 일찍 잠자리에 들어보세요. 서서히 수면 시간을 늘리는 것이 효과적입니다.",
        "카페인은 오후 2시 이전에만 섭취하면 취침이 수월해집니다.",
        "수면 부채가 쌓이고 있어요. 주말 몰아자기보다 평일 수면 시간을 늘려보세요."
    ]

    /// 수면 시간 과다 팁
    private let longSleepTips = [
        "수면 시간이 다소 깁니다. 과도한 수면도 피로감을 유발할 수 있습니다.",
        "9시간 이상 자도 피곤하다면, 수면 품질에 문제가 있을 수 있습니다.",
        "기상 시간을 일정하게 유지하면 수면의 질이 높아집니다."
    ]

    /// 수면 품질 낮음 팁
    private let poorQualityTips = [
        "취침 1시간 전 스마트폰 사용을 줄이면 수면 품질이 개선됩니다.",
        "침실 온도를 18~20도로 유지하면 깊은 수면에 도움이 됩니다.",
        "저녁 과식과 음주는 수면 품질을 크게 떨어뜨립니다.",
        "자기 전 가벼운 스트레칭이나 명상이 숙면에 도움됩니다.",
        "침실을 최대한 어둡게 만들면 멜라토닌 분비가 촉진됩니다."
    ]

    /// 수면 일관성 낮음 팁
    private let inconsistentTips = [
        "취침 시간이 불규칙합니다. 매일 같은 시간에 자고 일어나세요.",
        "일정한 수면 스케줄은 체내 시계(일주기 리듬)를 안정시킵니다.",
        "주말에도 평일과 비슷한 시간에 기상하면 월요병이 줄어듭니다.",
        "취침 루틴을 만들어 보세요. 매일 같은 순서로 준비하면 뇌가 수면 모드로 전환됩니다."
    ]

    /// 악화 추세 팁
    private let decliningTips = [
        "최근 수면 품질이 하락하고 있습니다. 생활 패턴에 변화가 있었나요?",
        "스트레스가 수면에 영향을 줄 수 있습니다. 취침 전 이완 활동을 시도해 보세요.",
        "수면 환경(빛, 소음, 온도)을 점검해 보세요."
    ]

    /// 양호한 수면 팁
    private let goodSleepTips = [
        "수면 상태가 양호합니다! 현재 패턴을 유지하세요.",
        "좋은 수면 습관을 유지하고 계시네요. 꾸준함이 핵심입니다.",
        "아침 햇빛을 15분 이상 쬐면 수면 리듬이 더욱 안정됩니다.",
        "규칙적인 운동은 수면 품질을 높여줍니다. 단, 취침 3시간 전에 마무리하세요."
    ]
}
