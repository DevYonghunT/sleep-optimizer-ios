//
//  GlowButtonStyle.swift
//  SleepOptimizer
//
//  네온 글로우 효과 버튼 스타일 — 인디고/퍼플 그라데이션 + 그림자
//

import SwiftUI

/// 네온 글로우 효과가 있는 커스텀 버튼 스타일
struct GlowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [AppColor.primary, AppColor.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: AppColor.primary.opacity(configuration.isPressed ? 0.3 : 0.6),
                radius: configuration.isPressed ? 4 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    Button {
        // 액션
    } label: {
        Text("글로우 버튼")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
    .buttonStyle(GlowButtonStyle())
    .padding(40)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
