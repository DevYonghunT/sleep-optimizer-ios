//
//  AlarmView.swift
//  SleepOptimizer
//
//  알람 설정 화면 — 원형 시간 표시, 알람 토글, 스마트 알람
//

import SwiftUI

struct AlarmView: View {
    // MARK: - 의존성
    @ObservedObject var viewModel: AlarmViewModel

    // MARK: - 상태
    @State private var selectedHour: Int
    @State private var selectedMinute: Int

    init(viewModel: AlarmViewModel) {
        self.viewModel = viewModel
        _selectedHour = State(initialValue: viewModel.alarmSettings.targetWakeHour)
        _selectedMinute = State(initialValue: viewModel.alarmSettings.targetWakeMinute)
    }

    /// 포맷된 시간 문자열
    private var formattedTime: String {
        String(format: "%02d:%02d", viewModel.alarmSettings.targetWakeHour, viewModel.alarmSettings.targetWakeMinute)
    }

    /// Date 바인딩 (DatePicker용)
    private var wakeTimeDate: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = viewModel.alarmSettings.targetWakeHour
                components.minute = viewModel.alarmSettings.targetWakeMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let hour = components.hour ?? 7
                let minute = components.minute ?? 0
                viewModel.updateWakeTime(hour: hour, minute: minute)
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // 원형 시간 표시
                    circularTimeDisplay

                    // 알람 토글
                    alarmToggle

                    // 기상 시각 피커
                    wakeTimePicker

                    // 스마트 알람 윈도우
                    smartAlarmSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(AppColor.background)
            .navigationTitle("알람")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 원형 시간 표시
    private var circularTimeDisplay: some View {
        ZStack {
            // 외부 원 (네온 글로우)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [AppColor.primary, AppColor.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 220, height: 220)
                .shadow(color: AppColor.primary.opacity(0.5), radius: 12)

            // 내부 배경
            Circle()
                .fill(AppColor.cardBackground)
                .frame(width: 210, height: 210)

            // 시간 텍스트
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundColor(AppColor.textPrimary)

                Text(viewModel.alarmSettings.isEnabled ? "알람 켜짐" : "알람 꺼짐")
                    .font(.caption)
                    .foregroundColor(
                        viewModel.alarmSettings.isEnabled
                            ? AppColor.sleepGood
                            : AppColor.textSecondary
                    )
            }
        }
        .padding(.top, 20)
    }

    // MARK: - 알람 토글
    private var alarmToggle: some View {
        HStack {
            Label("알람", systemImage: "alarm.fill")
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { viewModel.alarmSettings.isEnabled },
                set: { _ in
                    Task {
                        await viewModel.toggleAlarm()
                    }
                }
            ))
            .tint(AppColor.primary)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - 기상 시각 피커
    private var wakeTimePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("기상 시각", systemImage: "sunrise.fill")
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            DatePicker(
                "기상 시각",
                selection: wakeTimeDate,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipped()
            .colorScheme(.dark)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - 스마트 알람 섹션
    private var smartAlarmSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("스마트 알람", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Spacer()

                // 모든 기능 해금
            }

            Text("얕은 수면 단계에서 깨워드립니다")
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)

            // 윈도우 슬라이더
            VStack(spacing: 8) {
                HStack {
                    Text("알람 윈도우")
                        .font(.subheadline)
                        .foregroundColor(AppColor.textSecondary)

                    Spacer()

                    Text("\(viewModel.alarmSettings.smartAlarmWindow)분")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.primary)
                }

                // 15/30/45/60분 선택
                HStack(spacing: 12) {
                    ForEach([15, 30, 45, 60], id: \.self) { minutes in
                        smartAlarmWindowButton(minutes: minutes)
                    }
                }
            }
            // 스마트 알람 항상 활성
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(14)
    }

    /// 스마트 알람 윈도우 선택 버튼
    private func smartAlarmWindowButton(minutes: Int) -> some View {
        let isSelected = viewModel.alarmSettings.smartAlarmWindow == minutes

        return Button {
            viewModel.updateSmartWindow(minutes)
        } label: {
            Text("\(minutes)분")
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(
                    isSelected ? AppColor.background : AppColor.textSecondary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected ? AppColor.primary : AppColor.secondaryBackground
                )
                .cornerRadius(10)
        }
    }

    // 프리미엄 배지 제거 — 모든 기능 해금
}

#Preview {
    AlarmView(viewModel: AlarmViewModel(premiumService: PremiumService(), notificationService: NotificationService.shared))
        .preferredColorScheme(.dark)
}
