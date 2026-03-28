//
//  HealthKitService.swift
//  SleepOptimizer
//
//  HealthKit 연동 서비스 — 수면 데이터 읽기/쓰기
//

import Foundation
import HealthKit
import os

/// HealthKit 서비스 프로토콜
protocol HealthKitServiceProtocol {
    /// HealthKit 사용 가능 여부
    var isAvailable: Bool { get }

    /// 권한 요청
    func requestAuthorization() async -> Bool

    /// 수면 기록 저장
    func saveSleepRecord(_ record: SleepRecord) async throws

    /// 수면 데이터 조회
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepRecord]
}

/// HealthKit 서비스 구현
final class HealthKitService: HealthKitServiceProtocol {
    /// 싱글톤 인스턴스
    static let shared = HealthKitService()

    /// HealthKit 저장소
    private let healthStore: HKHealthStore?

    /// 수면 분석 카테고리 타입
    private let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)

    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
        }
    }

    /// HealthKit 사용 가능 여부
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable() && healthStore != nil
    }

    /// HealthKit 권한 요청
    func requestAuthorization() async -> Bool {
        guard let healthStore, let sleepType else {
            Logger(subsystem: "com.entangle.sleepoptimizer", category: "HealthKit").warning("HealthKit 사용 불가 (시뮬레이터 등)")
            return false
        }

        let typesToShare: Set<HKSampleType> = [sleepType]
        let typesToRead: Set<HKObjectType> = [sleepType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            Logger(subsystem: "com.entangle.sleepoptimizer", category: "HealthKit").error("HealthKit 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 수면 기록을 HealthKit에 저장
    func saveSleepRecord(_ record: SleepRecord) async throws {
        guard let healthStore, let sleepType else {
            throw HealthKitError.unavailable
        }

        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleep.rawValue,
            start: record.bedTime,
            end: record.wakeTime
        )

        try await healthStore.save(sample)
    }

    /// HealthKit에서 수면 데이터 조회
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        guard let healthStore, let sleepType else {
            throw HealthKitError.unavailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let records = (samples as? [HKCategorySample] ?? []).map { sample in
                    SleepRecord(
                        bedTime: sample.startDate,
                        wakeTime: sample.endDate,
                        quality: .fair
                    )
                }

                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }
}

/// HealthKit 에러
enum HealthKitError: LocalizedError {
    case unavailable
    case queryFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "HealthKit을 사용할 수 없습니다. 기기에서 건강 데이터를 지원하지 않습니다."
        case .queryFailed:
            return "수면 데이터 조회에 실패했습니다."
        }
    }
}
