//
//  PremiumService.swift
//  SleepOptimizer
//
//  프리미엄 상태 제공 — StoreKit 제거, 모든 기능 무료 해금
//

import Foundation

/// 프리미엄 서비스 — 모든 기능 무료 해금
@MainActor
final class PremiumService: ObservableObject {
    /// 프리미엄 상태 — 항상 활성
    @Published var premiumStatus: PremiumStatus = PremiumStatus(isActive: true)
}
