// SleepInsightServiceTests.swift
// SleepInsightService 테스트 — 인사이트 생성, 평균/일관성/트렌드 계산

import XCTest
@testable import SleepOptimizer

final class SleepInsightServiceTests: XCTestCase {

    private let sut = SleepInsightService.shared

    private func makeRecord(
        bedHour: Int = 23, bedMinute: Int = 0,
        wakeHour: Int = 7, wakeMinute: Int = 0,
        quality: SleepQuality = .good,
        daysAgo: Int = 0
    ) -> SleepRecord {
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let bedDay = cal.date(byAdding: .day, value: -daysAgo, to: base)!
        let bedTime = cal.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: bedDay)!
        let wakeDay = cal.date(byAdding: .day, value: -daysAgo + 1, to: base)!
        let wakeTime = cal.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: wakeDay)!
        return SleepRecord(bedTime: bedTime, wakeTime: wakeTime, quality: quality)
    }

    // MARK: - νₑ 정상 경로 (Happy Path)

    func test_generateInsight_validRecords_returnsInsight() {
        let records = [
            makeRecord(quality: .good, daysAgo: 0),
            makeRecord(quality: .excellent, daysAgo: 1),
            makeRecord(quality: .good, daysAgo: 2)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertGreaterThan(insight.averageDuration, 0)
        XCTAssertGreaterThan(insight.averageQuality, 0)
        XCTAssertFalse(insight.tip.isEmpty)
    }

    func test_averageDuration_8hourSleep_returns8() {
        // 23:00 → 07:00 = 8시간
        let records = [
            makeRecord(bedHour: 23, wakeHour: 7, daysAgo: 0),
            makeRecord(bedHour: 23, wakeHour: 7, daysAgo: 1)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.averageDuration, 8.0, accuracy: 0.1)
    }

    func test_averageQuality_mixedScores_calculatesCorrectly() {
        let records = [
            makeRecord(quality: .excellent, daysAgo: 0), // 5
            makeRecord(quality: .good, daysAgo: 1),      // 4
            makeRecord(quality: .poor, daysAgo: 2)        // 2
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.averageQuality, 3.67, accuracy: 0.1) // (5+4+2)/3
    }

    func test_consistency_sameTime_returns100() {
        // 모두 23:00에 취침
        let records = [
            makeRecord(bedHour: 23, bedMinute: 0, daysAgo: 0),
            makeRecord(bedHour: 23, bedMinute: 0, daysAgo: 1),
            makeRecord(bedHour: 23, bedMinute: 0, daysAgo: 2)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.consistencyScore, 100.0, accuracy: 1.0)
    }

    func test_trend_improving_whenNewerBetter() {
        // 오래된 기록: 나쁨, 최근: 좋음
        let records = [
            makeRecord(quality: .terrible, daysAgo: 7),
            makeRecord(quality: .poor, daysAgo: 6),
            makeRecord(quality: .good, daysAgo: 1),
            makeRecord(quality: .excellent, daysAgo: 0)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.trend, .improving)
    }

    func test_trend_declining_whenNewerWorse() {
        let records = [
            makeRecord(quality: .excellent, daysAgo: 7),
            makeRecord(quality: .good, daysAgo: 6),
            makeRecord(quality: .poor, daysAgo: 1),
            makeRecord(quality: .terrible, daysAgo: 0)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.trend, .declining)
    }

    func test_tip_shortSleep_returnsShortSleepTip() {
        // 5시간 수면 (부족): 새벽 2시 취침 → 같은 날 7시 기상
        let cal = Calendar.current
        let base = cal.startOfDay(for: Date())
        let bedTime = cal.date(bySettingHour: 2, minute: 0, second: 0, of: base)!
        let wakeTime = cal.date(bySettingHour: 7, minute: 0, second: 0, of: base)!
        let record1 = SleepRecord(bedTime: bedTime, wakeTime: wakeTime, quality: .poor)

        let base2 = cal.date(byAdding: .day, value: -1, to: base)!
        let bedTime2 = cal.date(bySettingHour: 2, minute: 0, second: 0, of: base2)!
        let wakeTime2 = cal.date(bySettingHour: 7, minute: 0, second: 0, of: base2)!
        let record2 = SleepRecord(bedTime: bedTime2, wakeTime: wakeTime2, quality: .poor)

        let insight = sut.generateInsight(from: [record1, record2])

        XCTAssertEqual(insight.averageDuration, 5.0, accuracy: 0.1)
        XCTAssertFalse(insight.tip.isEmpty)
    }

    // MARK: - νμ 예외 경로 (Error Path)

    func test_generateInsight_emptyRecords_returnsDefaults() {
        let insight = sut.generateInsight(from: [])

        XCTAssertEqual(insight.averageDuration, 0)
        XCTAssertEqual(insight.averageQuality, 0)
        XCTAssertEqual(insight.consistencyScore, 0)
        XCTAssertEqual(insight.trend, .stable)
        XCTAssertFalse(insight.tip.isEmpty)
    }

    func test_trend_lessThan4Records_returnsStable() {
        let records = [
            makeRecord(quality: .excellent, daysAgo: 0),
            makeRecord(quality: .terrible, daysAgo: 1)
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.trend, .stable)
    }

    // MARK: - ντ 경계 경로 (Edge Case)

    func test_consistency_singleRecord_returns100() {
        let records = [makeRecord(daysAgo: 0)]

        let insight = sut.generateInsight(from: records)

        XCTAssertEqual(insight.consistencyScore, 100.0, accuracy: 1.0)
    }

    func test_consistency_veryIrregular_returnsLowScore() {
        // 취침 시간이 매우 불규칙
        let records = [
            makeRecord(bedHour: 21, bedMinute: 0, daysAgo: 0),
            makeRecord(bedHour: 3, bedMinute: 0, daysAgo: 1), // 새벽 3시
            makeRecord(bedHour: 22, bedMinute: 0, daysAgo: 2),
            makeRecord(bedHour: 1, bedMinute: 0, daysAgo: 3)  // 새벽 1시
        ]

        let insight = sut.generateInsight(from: records)

        XCTAssertLessThan(insight.consistencyScore, 80.0)
    }

    func test_trend_exactlyFourRecords_calculatesCorrectly() {
        let records = [
            makeRecord(quality: .fair, daysAgo: 3),
            makeRecord(quality: .fair, daysAgo: 2),
            makeRecord(quality: .fair, daysAgo: 1),
            makeRecord(quality: .fair, daysAgo: 0)
        ]

        let insight = sut.generateInsight(from: records)

        // 동일 품질 → stable
        XCTAssertEqual(insight.trend, .stable)
    }

    func test_manyRecords_performance() {
        let records = (0..<100).map { i in
            makeRecord(quality: SleepQuality.allCases[i % 5], daysAgo: i)
        }

        let start = CFAbsoluteTimeGetCurrent()
        let insight = sut.generateInsight(from: records)
        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertLessThan(elapsed, 1.0)
        XCTAssertGreaterThan(insight.averageDuration, 0)
    }
}
