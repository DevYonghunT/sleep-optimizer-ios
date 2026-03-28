//
//  PremiumStatus.swift
//  SleepOptimizer
//
//  프리미엄 구독 상태 모델
//

import Foundation

/// 프리미엄 구독 상태
struct PremiumStatus {
    /// 프리미엄 활성 여부
    let isActive: Bool

    /// 수면 기록 열람 가능 여부 (무료 사용자는 최근 7일 제한)
    func canAccessHistory(recordCount: Int) -> Bool {
        if isActive { return true }
        return recordCount <= AppConstants.freeRecordLimit
    }

    /// 스마트 알람 사용 가능 여부
    var canUseSmartAlarm: Bool {
        isActive
    }

    /// 상세 통계 접근 가능 여부
    var canAccessDetailedStats: Bool {
        isActive
    }
}
