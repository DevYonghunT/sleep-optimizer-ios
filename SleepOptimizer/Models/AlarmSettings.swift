//
//  AlarmSettings.swift
//  SleepOptimizer
//
//  알람 설정 모델 (UserDefaults 저장)
//

import Foundation

/// 알람 설정
struct AlarmSettings: Codable {
    /// 알람 활성화 여부
    var isEnabled: Bool

    /// 목표 기상 시각 — 시
    var targetWakeHour: Int

    /// 목표 기상 시각 — 분
    var targetWakeMinute: Int

    /// 스마트 알람 윈도우 (목표 시각 전 분 단위, 기본 30분)
    var smartAlarmWindow: Int

    /// 알람 사운드 이름
    var soundName: String

    /// UserDefaults 저장 키
    private static let storageKey = "alarm_settings"

    init(
        isEnabled: Bool = false,
        targetWakeHour: Int = 7,
        targetWakeMinute: Int = 0,
        smartAlarmWindow: Int = 30,
        soundName: String = "default"
    ) {
        self.isEnabled = isEnabled
        self.targetWakeHour = targetWakeHour
        self.targetWakeMinute = targetWakeMinute
        self.smartAlarmWindow = smartAlarmWindow
        self.soundName = soundName
    }

    /// UserDefaults에서 설정 로드
    static func load() -> AlarmSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AlarmSettings.self, from: data) else {
            return AlarmSettings()
        }
        return settings
    }

    /// UserDefaults에 설정 저장
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: AlarmSettings.storageKey)
    }
}
