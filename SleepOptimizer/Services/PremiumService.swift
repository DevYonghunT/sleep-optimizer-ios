//
//  PremiumService.swift
//  SleepOptimizer
//
//  프리미엄 구독 관리 서비스 (StoreKit 2)
//

import Foundation
import StoreKit
import os

/// 프리미엄 구독 서비스 — IAP 관리
@MainActor
final class PremiumService: ObservableObject {
    private nonisolated static let logger = Logger(
        subsystem: "com.entangle.sleepoptimizer",
        category: "PremiumService"
    )
    /// 프리미엄 상태
    @Published var premiumStatus: PremiumStatus = PremiumStatus(isActive: false)

    /// 사용 가능한 상품 목록
    @Published var availableProducts: [Product] = []

    /// 구매 진행 중 여부
    @Published var isPurchasing: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 트랜잭션 리스너 태스크
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// 트랜잭션 변경 감지
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self.updatePurchaseStatus()
                case .unverified(_, let error):
                    Self.logger.error("거래 검증 실패 (finish 미호출): \(error.localizedDescription)")
                }
            }
        }
    }

    /// 상품 목록 로드
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [AppConstants.premiumProductID])
            self.availableProducts = products
        } catch {
            self.errorMessage = "상품 로드 실패: \(error.localizedDescription)"
        }
    }

    /// 구매 상태 업데이트
    func updatePurchaseStatus() async {
        var isActive = false
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == AppConstants.premiumProductID {
                    isActive = transaction.revocationDate == nil
                }
            case .unverified(_, let error):
                Self.logger.error("구독 상태 확인 중 거래 검증 실패: \(error.localizedDescription)")
            }
        }
        self.premiumStatus = PremiumStatus(isActive: isActive)
    }

    /// 프리미엄 구독 구매
    func purchasePremium() async {
        guard let product = availableProducts.first else {
            errorMessage = "구매 가능한 상품이 없습니다"
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
                case .unverified(_, let error):
                    errorMessage = "구매 검증 실패. 잠시 후 다시 시도해주세요."
                    Self.logger.error("구매 거래 검증 실패: \(error.localizedDescription)")
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "구매가 대기 중입니다"
            @unknown default:
                errorMessage = "알 수 없는 구매 결과"
            }
        } catch {
            errorMessage = "구매 실패: \(error.localizedDescription)"
        }

        isPurchasing = false
    }

    /// 구매 복원
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            errorMessage = "복원 실패: \(error.localizedDescription)"
        }
    }
}
