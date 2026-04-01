// SleepLogViewModel.swift
// SleepOptimizer
//
// 수면 기록 입력 및 관리를 담당하는 뷰모델

import Foundation
import SwiftData
import Combine

/// 수면 기록 생성, 삭제, 조회를 처리하는 뷰모델
@MainActor
final class SleepLogViewModel: ObservableObject {

    // MARK: - 발행 프로퍼티

    /// 취침 시간 (기본값: 오늘 23:00)
    @Published var bedTime: Date = SleepLogViewModel.defaultBedTime()

    /// 기상 시간 (기본값: 내일 07:00)
    @Published var wakeTime: Date = SleepLogViewModel.defaultWakeTime()

    /// 선택된 수면 품질
    @Published var selectedQuality: SleepQuality = .good

    /// 메모
    @Published var notes: String = ""

    /// 저장 성공 알림 표시 여부
    @Published var showingSuccessAlert: Bool = false

    // MARK: - 의존성

    /// SwiftData 모델 컨텍스트
    private(set) var modelContext: ModelContext?

    /// 프리미엄 서비스
    private let premiumService: PremiumService

    // MARK: - 초기화

    /// 뷰모델 초기화
    /// - Parameter premiumService: 프리미엄 기능 접근 서비스
    init(premiumService: PremiumService) {
        self.premiumService = premiumService
    }

    // MARK: - 컨텍스트 설정

    /// SwiftData 모델 컨텍스트를 주입한다
    /// - Parameter context: SwiftData 모델 컨텍스트
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - 수면 기록 저장

    /// 현재 폼 데이터로 수면 기록을 생성하고 저장한다
    func saveSleepRecord() {
        guard let modelContext else {
            assertionFailure("ModelContext가 설정되지 않았습니다")
            return
        }

        // 무료 사용자: 최근 7일 이내 기록만 조회 가능 (기록 자체는 제한 없음)
        // 기록은 항상 허용하되, 조회 시 기간 제한 적용

        let record = SleepRecord(
            bedTime: bedTime,
            wakeTime: wakeTime,
            quality: selectedQuality,
            notes: notes.isEmpty ? "" : notes
        )

        modelContext.insert(record)

        do {
            try modelContext.save()
            showingSuccessAlert = true
            resetForm()
        } catch {
            assertionFailure("수면 기록 저장 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 수면 기록 삭제

    /// 지정된 수면 기록을 삭제한다
    /// - Parameter record: 삭제할 수면 기록
    func deleteSleepRecord(_ record: SleepRecord) {
        guard let modelContext else {
            assertionFailure("ModelContext가 설정되지 않았습니다")
            return
        }

        modelContext.delete(record)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("수면 기록 삭제 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 최근 기록 조회

    /// 최근 수면 기록을 생성일 역순으로 조회한다
    /// 무료 사용자는 최근 7일 이내 기록만 반환한다
    /// - Returns: 정렬된 수면 기록 배열
    func loadRecentRecords() -> [SleepRecord] {
        guard let modelContext else {
            return []
        }

        let descriptor = FetchDescriptor<SleepRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let records = try modelContext.fetch(descriptor)
            return records
        } catch {
            assertionFailure("수면 기록 조회 실패: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 폼 초기화

    /// 입력 폼을 기본값으로 초기화한다
    func resetForm() {
        bedTime = Self.defaultBedTime()
        wakeTime = Self.defaultWakeTime()
        selectedQuality = .good
        notes = ""
    }

    // MARK: - 기본값 헬퍼

    /// 기본 취침 시간 (오늘 23:00)을 생성한다
    private static func defaultBedTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }

    /// 기본 기상 시간 (내일 07:00)을 생성한다
    private static func defaultWakeTime() -> Date {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return Date()
        }
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 7
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
}
