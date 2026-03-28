// SettingsViewModel.swift
// SleepOptimizer
//
// 앱 설정 화면을 담당하는 뷰모델

import Foundation
import Combine

/// 앱 설정(HealthKit, 알림, 프리미엄 등)을 관리하는 뷰모델
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - 발행 프로퍼티

    /// HealthKit 접근 권한 부여 여부
    @Published var healthKitAuthorized: Bool = false

    // MARK: - 의존성

    /// 로컬 알림 서비스
    let notificationService: NotificationService

    /// 프리미엄 서비스
    let premiumService: PremiumService

    /// HealthKit 연동 서비스
    let healthKitService: HealthKitServiceProtocol

    // MARK: - 계산 프로퍼티

    /// 현재 앱 버전 문자열
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - 초기화

    /// 뷰모델 초기화
    /// - Parameters:
    ///   - notificationService: 로컬 알림 서비스
    ///   - premiumService: 프리미엄 기능 접근 서비스
    ///   - healthKitService: HealthKit 연동 서비스
    init(
        notificationService: NotificationService = .shared,
        premiumService: PremiumService,
        healthKitService: HealthKitServiceProtocol = HealthKitService.shared
    ) {
        self.notificationService = notificationService
        self.premiumService = premiumService
        self.healthKitService = healthKitService
    }

    // MARK: - HealthKit 접근 요청

    /// HealthKit 접근 권한을 요청한다
    /// 사용자가 권한을 부여하면 healthKitAuthorized가 true로 변경된다
    func requestHealthKitAccess() async {
        let granted = await healthKitService.requestAuthorization()
        healthKitAuthorized = granted
    }

    // MARK: - 알림 토글

    /// 알림 권한을 토글한다
    /// 권한이 없으면 시스템 권한 요청을 실행하고,
    /// 이미 부여된 경우 알림 예약을 해제한다
    func toggleNotification() async {
        let _ = await notificationService.requestAuthorization()
    }
}
