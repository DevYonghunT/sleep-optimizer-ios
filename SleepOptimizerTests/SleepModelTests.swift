// SleepModelTests.swift
// SleepRecord, SleepQuality, AlarmSettings, PremiumStatus 모델 테스트

import XCTest
import SwiftData
@testable import SleepOptimizer

final class SleepModelTests: XCTestCase {

    // MARK: - νₑ 정상 경로 — SleepQuality

    func test_sleepQuality_allCases_hasFive() {
        XCTAssertEqual(SleepQuality.allCases.count, 5)
    }

    func test_sleepQuality_scores_descendingOrder() {
        XCTAssertEqual(SleepQuality.excellent.score, 5)
        XCTAssertEqual(SleepQuality.good.score, 4)
        XCTAssertEqual(SleepQuality.fair.score, 3)
        XCTAssertEqual(SleepQuality.poor.score, 2)
        XCTAssertEqual(SleepQuality.terrible.score, 1)
    }

    func test_sleepQuality_displayNames_korean() {
        XCTAssertEqual(SleepQuality.excellent.displayName, "최상")
        XCTAssertEqual(SleepQuality.terrible.displayName, "최악")
    }

    func test_sleepQuality_emojis_notEmpty() {
        for quality in SleepQuality.allCases {
            XCTAssertFalse(quality.emoji.isEmpty)
        }
    }

    func test_sleepQuality_iconNames_notEmpty() {
        for quality in SleepQuality.allCases {
            XCTAssertFalse(quality.iconName.isEmpty)
        }
    }

    // MARK: - νₑ 정상 경로 — SleepRecord

    @MainActor
    func test_sleepRecord_duration_normalCase() {
        // 23:00 → 07:00 (8시간)
        let bedTime = makeDate(hour: 23, minute: 0)
        let wakeTime = makeDate(hour: 7, minute: 0, daysOffset: 1)

        let record = SleepRecord(bedTime: bedTime, wakeTime: wakeTime, quality: .good)

        XCTAssertEqual(record.durationHours, 8.0, accuracy: 0.01)
    }

    @MainActor
    func test_sleepRecord_duration_midnightCrossover() {
        // wakeTime < bedTime → 자정 보정 테스트
        let bedTime = makeDate(hour: 23, minute: 30)
        let wakeTime = makeDate(hour: 6, minute: 30) // 같은 날짜, bedTime보다 이전

        let record = SleepRecord(bedTime: bedTime, wakeTime: wakeTime)

        // interval이 음수 → +86400 보정 → 7시간
        XCTAssertEqual(record.durationHours, 7.0, accuracy: 0.01)
    }

    @MainActor
    func test_sleepRecord_quality_computedProperty() {
        let record = SleepRecord(bedTime: Date(), wakeTime: Date(), quality: .excellent)
        XCTAssertEqual(record.quality, .excellent)

        record.quality = .poor
        XCTAssertEqual(record.quality, .poor)
        XCTAssertEqual(record.qualityRawValue, "poor")
    }

    @MainActor
    func test_sleepRecord_defaultQuality_isFair() {
        let record = SleepRecord(bedTime: Date(), wakeTime: Date())
        XCTAssertEqual(record.quality, .fair)
    }

    @MainActor
    func test_sleepRecord_notes_storedCorrectly() {
        let record = SleepRecord(bedTime: Date(), wakeTime: Date(), notes: "좋은 수면")
        XCTAssertEqual(record.notes, "좋은 수면")
    }

    // MARK: - νₑ 정상 경로 — AlarmSettings

    func test_alarmSettings_defaultValues() {
        let settings = AlarmSettings()

        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.targetWakeHour, 7)
        XCTAssertEqual(settings.targetWakeMinute, 0)
        XCTAssertEqual(settings.smartAlarmWindow, 30)
        XCTAssertEqual(settings.soundName, "default")
    }

    func test_alarmSettings_saveAndLoad_roundTrip() {
        UserDefaults.standard.removeObject(forKey: "alarm_settings")

        var settings = AlarmSettings()
        settings.isEnabled = true
        settings.targetWakeHour = 6
        settings.targetWakeMinute = 30
        settings.smartAlarmWindow = 15
        settings.save()

        let loaded = AlarmSettings.load()

        XCTAssertTrue(loaded.isEnabled)
        XCTAssertEqual(loaded.targetWakeHour, 6)
        XCTAssertEqual(loaded.targetWakeMinute, 30)
        XCTAssertEqual(loaded.smartAlarmWindow, 15)

        UserDefaults.standard.removeObject(forKey: "alarm_settings")
    }

    func test_alarmSettings_codable_roundTrip() throws {
        let settings = AlarmSettings(isEnabled: true, targetWakeHour: 8, targetWakeMinute: 15)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AlarmSettings.self, from: data)

        XCTAssertEqual(decoded.isEnabled, settings.isEnabled)
        XCTAssertEqual(decoded.targetWakeHour, settings.targetWakeHour)
        XCTAssertEqual(decoded.targetWakeMinute, settings.targetWakeMinute)
    }

    // MARK: - νₑ 정상 경로 — PremiumStatus

    func test_premiumStatus_free_cannotAccessPremiumFeatures() {
        let status = PremiumStatus(isActive: false)

        XCTAssertFalse(status.canUseSmartAlarm)
        XCTAssertFalse(status.canAccessDetailedStats)
    }

    func test_premiumStatus_premium_canAccessAllFeatures() {
        let status = PremiumStatus(isActive: true)

        XCTAssertTrue(status.canUseSmartAlarm)
        XCTAssertTrue(status.canAccessDetailedStats)
    }

    // MARK: - νμ 예외 경로

    @MainActor
    func test_sleepRecord_invalidQualityRawValue_defaultsToFair() {
        let record = SleepRecord(bedTime: Date(), wakeTime: Date())
        record.qualityRawValue = "invalid"

        XCTAssertEqual(record.quality, .fair)
    }

    func test_alarmSettings_load_noData_returnsDefaults() {
        UserDefaults.standard.removeObject(forKey: "alarm_settings")
        let loaded = AlarmSettings.load()

        XCTAssertFalse(loaded.isEnabled)
        XCTAssertEqual(loaded.targetWakeHour, 7)
    }

    // MARK: - ντ 경계 경로

    @MainActor
    func test_sleepRecord_zeroDuration_sameTimes() {
        let time = Date()
        let record = SleepRecord(bedTime: time, wakeTime: time)

        XCTAssertEqual(record.duration, 0)
        XCTAssertEqual(record.durationHours, 0)
    }

    @MainActor
    func test_sleepRecord_veryShortSleep() {
        let bedTime = Date()
        let wakeTime = bedTime.addingTimeInterval(60) // 1분

        let record = SleepRecord(bedTime: bedTime, wakeTime: wakeTime)

        XCTAssertEqual(record.duration, 60, accuracy: 1)
    }

    func test_sleepTrend_displayNames_notEmpty() {
        XCTAssertFalse(SleepTrend.improving.displayName.isEmpty)
        XCTAssertFalse(SleepTrend.declining.displayName.isEmpty)
        XCTAssertFalse(SleepTrend.stable.displayName.isEmpty)
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int, daysOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        if let date = calendar.date(from: components) {
            return calendar.date(byAdding: .day, value: daysOffset, to: date) ?? date
        }
        return Date()
    }
}
