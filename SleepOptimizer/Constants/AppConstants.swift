//
//  AppConstants.swift
//  SleepOptimizer
//
//  앱 전역 상수 정의
//

import SwiftUI

/// 앱 전역 상수
enum AppConstants {
    /// 무료 사용자 수면 기록 열람 제한 (일)
    static let freeRecordLimit: Int = 7

    /// 프리미엄 월간 구독 가격 표시용
    static let premiumMonthlyPrice: String = "$1.99"

    /// 프리미엄 IAP 상품 ID
    static let premiumProductID: String = "com.entangle.sleepoptimizer.premium.monthly"

    /// 앱 이름
    static let appName: String = "Sleep Optimizer"

    /// 권장 수면 시간 (시간 단위)
    static let recommendedSleepHours: Double = 7.5
}

/// 앱 색상 팔레트
enum AppColor {
    /// 기본 색상 — 인디고/딥블루
    static let primary = Color(hex: "6C5CE7")

    /// 보조 색상 — 소프트 퍼플
    static let secondary = Color(hex: "A29BFE")

    /// 강조 색상 — 따뜻한 골드/달 색상
    static let accent = Color(hex: "FECA57")

    /// 배경 — 매우 어두운 네이비
    static let background = Color(hex: "0D0D1A")

    /// 보조 배경 — 다크 네이비
    static let secondaryBackground = Color(hex: "161630")

    /// 카드 배경
    static let cardBackground = Color(hex: "1E1E3F")

    /// 기본 텍스트 — 흰색
    static let textPrimary = Color.white

    /// 보조 텍스트 — 회색
    static let textSecondary = Color.gray

    /// 수면 품질 좋음 — 녹색
    static let sleepGood = Color(hex: "2ECC71")

    /// 수면 품질 보통 — 노란색
    static let sleepFair = Color(hex: "F1C40F")

    /// 수면 품질 나쁨 — 빨간색
    static let sleepPoor = Color(hex: "E74C3C")

    /// 수면 품질에 따른 색상 반환
    static func qualityColor(for quality: SleepQuality) -> Color {
        switch quality {
        case .excellent, .good:
            return sleepGood
        case .fair:
            return sleepFair
        case .poor, .terrible:
            return sleepPoor
        }
    }
}
