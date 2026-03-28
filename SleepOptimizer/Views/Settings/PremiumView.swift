//
//  PremiumView.swift
//  SleepOptimizer
//
//  프리미엄 구매 화면 — 혜택 안내, 가격, 구매 버튼
//

import SwiftUI

struct PremiumView: View {
    // MARK: - 의존성
    @ObservedObject var premiumService: PremiumService
    @Environment(\.dismiss) private var dismiss

    /// 프리미엄 혜택 목록
    private let benefits: [(icon: String, title: String, description: String)] = [
        ("infinity", "무제한 기록", "수면 기록 제한 없이 전체 히스토리 보관"),
        ("brain.head.profile", "스마트 알람", "얕은 수면 단계에서 최적의 타이밍에 기상"),
        ("chart.line.uptrend.xyaxis", "상세 통계", "고급 수면 패턴 분석 및 인사이트"),
        ("heart.text.square", "HealthKit 연동", "Apple 건강 앱과 자동 데이터 동기화"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // 헤더 — 달/별 비주얼
                    headerSection

                    // 혜택 목록
                    benefitsSection

                    // 가격 표시
                    priceSection

                    // 구매 버튼
                    purchaseButton

                    // 복원 버튼
                    restoreButton

                    // 하단 안내
                    footerText
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
            .alert("오류", isPresented: Binding(
                get: { premiumService.errorMessage != nil },
                set: { if !$0 { premiumService.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(premiumService.errorMessage ?? "")
            }
        }
    }

    // MARK: - 헤더 섹션
    private var headerSection: some View {
        ZStack {
            // 배경 글로우
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            AppColor.primary.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            VStack(spacing: 12) {
                // 달 아이콘
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColor.accent, AppColor.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppColor.accent.opacity(0.5), radius: 16)

                Text("Sleep Optimizer Pro")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)

                Text("최적의 수면을 위한 프리미엄 기능")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - 혜택 섹션
    private var benefitsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                HStack(spacing: 16) {
                    // 아이콘
                    Image(systemName: benefit.icon)
                        .font(.title3)
                        .foregroundColor(AppColor.primary)
                        .frame(width: 40, height: 40)
                        .background(AppColor.primary.opacity(0.15))
                        .cornerRadius(10)

                    // 텍스트
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColor.textPrimary)

                        Text(benefit.description)
                            .font(.caption)
                            .foregroundColor(AppColor.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColor.sleepGood)
                }
                .padding(.vertical, 14)

                // 구분선 (마지막 항목 제외)
                if index < benefits.count - 1 {
                    Divider()
                        .background(AppColor.textSecondary.opacity(0.3))
                }
            }
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 가격 섹션
    private var priceSection: some View {
        VStack(spacing: 4) {
            if let product = premiumService.availableProducts.first {
                Text(product.displayPrice)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
            } else {
                Text(AppConstants.premiumMonthlyPrice)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)
            }
            Text("/ 월")
                .font(.subheadline)
                .foregroundColor(AppColor.textSecondary)
        }
    }

    // MARK: - 구매 버튼
    private var purchaseButton: some View {
        Button {
            Task {
                await premiumService.purchasePremium()
                if premiumService.premiumStatus.isActive {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if premiumService.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("프리미엄 시작하기")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(GlowButtonStyle())
        .disabled(premiumService.isPurchasing)
    }

    // MARK: - 복원 버튼
    private var restoreButton: some View {
        Button {
            Task {
                await premiumService.restorePurchases()
                if premiumService.premiumStatus.isActive {
                    dismiss()
                }
            }
        } label: {
            Text("이전 구매 복원")
                .font(.subheadline)
                .foregroundColor(AppColor.secondary)
        }
    }

    // MARK: - 하단 안내 텍스트
    private var footerText: some View {
        VStack(spacing: 4) {
            Text("구독은 언제든 취소할 수 있습니다")
            Text("7일 무료 체험 후 과금됩니다")
        }
        .font(.caption2)
        .foregroundColor(AppColor.textSecondary)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    PremiumView(premiumService: PremiumService())
        .preferredColorScheme(.dark)
}
