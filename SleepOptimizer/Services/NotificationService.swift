//
//  NotificationService.swift
//  SleepOptimizer
//
//  알람 알림 서비스
//

import Foundation
import UserNotifications
import os

/// 알람 알림 서비스 — 기상 알람 스케줄링 담당
final class NotificationService {
    /// 싱글톤 인스턴스
    static let shared = NotificationService()

    /// 알람 알림 식별자
    private let alarmIdentifier = "sleep_optimizer_alarm"

    /// 알람 카테고리 식별자
    private let alarmCategoryIdentifier = "ALARM_CATEGORY"

    private init() {
        registerNotificationCategory()
    }

    /// 알림 카테고리 및 액션 등록
    private func registerNotificationCategory() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "다시 알림",
            options: []
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "해제",
            options: [.destructive]
        )

        let alarmCategory = UNNotificationCategory(
            identifier: alarmCategoryIdentifier,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }

    /// 알림 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            Logger(subsystem: "com.entangle.sleepoptimizer", category: "Notification").error("알림 권한 요청 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 알람 스케줄링
    /// - Parameter settings: 알람 설정
    func scheduleAlarm(settings: AlarmSettings) {
        guard settings.isEnabled else {
            cancelAlarm()
            return
        }

        /// 기존 알람 취소 후 새로 등록
        cancelAlarm()

        /// 알림 콘텐츠 구성
        let content = UNMutableNotificationContent()
        content.title = "좋은 아침이에요! ☀️"
        content.body = "일어날 시간입니다. 오늘도 상쾌한 하루 보내세요!"
        content.categoryIdentifier = alarmCategoryIdentifier
        content.sound = settings.soundName == "default"
            ? .default
            : UNNotificationSound(named: UNNotificationSoundName(rawValue: settings.soundName))

        /// 매일 반복 트리거 생성
        var dateComponents = DateComponents()
        dateComponents.hour = settings.targetWakeHour
        dateComponents.minute = settings.targetWakeMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        /// 알림 요청 등록
        let request = UNNotificationRequest(
            identifier: alarmIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger(subsystem: "com.entangle.sleepoptimizer", category: "Notification").error("알람 등록 실패: \(error.localizedDescription)")
            }
        }
    }

    /// 알람 취소
    func cancelAlarm() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [alarmIdentifier])
    }
}
