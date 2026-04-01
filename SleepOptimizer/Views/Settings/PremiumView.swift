//
//  PremiumView.swift
//  SleepOptimizer
//
//  모든 기능 무료 해금 — 구독 UI 제거
//

import SwiftUI

struct PremiumView: View {
    @ObservedObject var premiumService: PremiumService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColor.accent, AppColor.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("모든 기능이 해금되었습니다")
                    .font(.title2.bold())
                    .foregroundColor(AppColor.textPrimary)

                Text("무제한 기록, 스마트 알람, 상세 통계를 자유롭게 사용하세요")
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button("닫기") {
                    dismiss()
                }
                .foregroundColor(AppColor.primary)
                .padding(.bottom, 40)
            }
            .background(AppColor.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PremiumView(premiumService: PremiumService())
        .preferredColorScheme(.dark)
}
