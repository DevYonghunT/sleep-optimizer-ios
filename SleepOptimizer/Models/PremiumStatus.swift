//
//  PremiumStatus.swift
//  SleepOptimizer
//
//  프리미엄 구독 상태 모델 — 모든 기능 무료 해금
//

import Foundation

/// 프리미엄 구독 상태
struct PremiumStatus {
    /// 프리미엄 활성 여부
    let isActive: Bool

    /// 기록 열람 항상 허용
    func canAccessHistory(recordCount: Int) -> Bool {
        return true
    }

    /// 스마트 알람 항상 사용 가능
    var canUseSmartAlarm: Bool {
        true
    }

    /// 상세 통계 항상 접근 가능
    var canAccessDetailedStats: Bool {
        true
    }
}
