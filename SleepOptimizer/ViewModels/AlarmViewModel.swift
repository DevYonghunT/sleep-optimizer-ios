// AlarmViewModel.swift
// SleepOptimizer
//
// 알람 설정 및 관리를 담당하는 뷰모델

import Foundation
import Combine

/// UserDefaults 저장 키
private enum AlarmStorageKey {
    static let alarmSettings = "alarmSettings"
}

/// 알람 설정 변경 및 저장을 처리하는 뷰모델
@MainActor
final class AlarmViewModel: ObservableObject {

    // MARK: - 발행 프로퍼티

    /// 현재 알람 설정
    @Published var alarmSettings: AlarmSettings

    /// 프리미엄 서비스
    @Published var premiumService: PremiumService

    // MARK: - 의존성

    /// 알림 서비스
    private let notificationService: NotificationService

    // MARK: - 초기화

    /// 뷰모델 초기화
    /// - Parameters:
    ///   - premiumService: 프리미엄 기능 접근 서비스
    ///   - notificationService: 로컬 알림 서비스
    init(
        premiumService: PremiumService,
        notificationService: NotificationService = .shared
    ) {
        self.premiumService = premiumService
        self.notificationService = notificationService
        self.alarmSettings = Self.loadSettingsFromStorage()
    }

    // MARK: - 알람 토글

    /// 알람을 켜거나 끈다
    /// 알림 권한이 없으면 권한을 먼저 요청한다
    func toggleAlarm() async {
        alarmSettings.isEnabled.toggle()

        if alarmSettings.isEnabled {
            // 알림 권한 요청 후 알람 예약
            let granted = await notificationService.requestAuthorization()
            if granted {
                await scheduleAlarm()
            } else {
                // 권한 거부 시 알람 비활성화
                alarmSettings.isEnabled = false
            }
        } else {
            // 알람 비활성화 시 예약된 알림 취소
            notificationService.cancelAlarm()
        }

        saveSettings()
    }

    // MARK: - 기상 시간 변경

    /// 알람 기상 시간을 변경한다
    /// - Parameters:
    ///   - hour: 시 (0~23)
    ///   - minute: 분 (0~59)
    func updateWakeTime(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            assertionFailure("잘못된 시간 값: \(hour)시 \(minute)분")
            return
        }

        alarmSettings.targetWakeHour = hour
        alarmSettings.targetWakeMinute = minute
        saveSettings()

        // 알람이 활성화 상태면 재예약
        if alarmSettings.isEnabled {
            Task {
                await scheduleAlarm()
            }
        }
    }

    // MARK: - 스마트 알람 윈도우 변경

    /// 스마트 알람 윈도우(분)를 변경한다
    /// 스마트 알람은 설정 시간 전 윈도우 내에서 최적의 기상 시점을 찾는다
    /// - Parameter minutes: 스마트 알람 윈도우 (분 단위)
    func updateSmartWindow(_ minutes: Int) {
        guard minutes >= 0 else {
            assertionFailure("스마트 알람 윈도우는 0 이상이어야 합니다")
            return
        }

        alarmSettings.smartAlarmWindow = minutes
        saveSettings()

        // 알람이 활성화 상태면 재예약
        if alarmSettings.isEnabled {
            Task {
                await scheduleAlarm()
            }
        }
    }

    // MARK: - 설정 저장

    /// 현재 알람 설정을 UserDefaults에 저장한다
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(alarmSettings)
            UserDefaults.standard.set(data, forKey: AlarmStorageKey.alarmSettings)
        } catch {
            assertionFailure("알람 설정 저장 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 비공개 메서드

    /// UserDefaults에서 알람 설정을 불러온다
    /// 저장된 값이 없으면 기본값을 반환한다
    private static func loadSettingsFromStorage() -> AlarmSettings {
        guard let data = UserDefaults.standard.data(forKey: AlarmStorageKey.alarmSettings) else {
            return AlarmSettings()
        }

        do {
            let settings = try JSONDecoder().decode(AlarmSettings.self, from: data)
            return settings
        } catch {
            assertionFailure("알람 설정 로드 실패: \(error.localizedDescription)")
            return AlarmSettings()
        }
    }

    /// 알림 서비스를 통해 알람을 예약한다
    private func scheduleAlarm() async {
        notificationService.scheduleAlarm(settings: alarmSettings)
    }
}
