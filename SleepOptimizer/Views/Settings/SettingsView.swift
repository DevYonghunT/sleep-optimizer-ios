//
//  SettingsView.swift
//  SleepOptimizer
//
//  설정 화면 — 프리미엄, HealthKit, 알림, 앱 정보
//

import SwiftUI

struct SettingsView: View {
    // MARK: - 의존성
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                // 프리미엄 섹션
                premiumSection

                // HealthKit 섹션
                healthKitSection

                // 알림 섹션
                notificationSection

                // 앱 정보 섹션
                infoSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - 프리미엄 섹션 — 모든 기능 해금
    private var premiumSection: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(AppColor.accent)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("모든 기능 활성")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColor.textPrimary)

                    Text("모든 기능을 자유롭게 사용하세요")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColor.sleepGood)
            }
            .listRowBackground(AppColor.cardBackground)
        } header: {
            Text("기능")
                .foregroundColor(AppColor.textSecondary)
        }
    }

    // MARK: - HealthKit 섹션
    private var healthKitSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.requestHealthKitAccess()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple 건강 연동")
                            .font(.body)
                            .foregroundColor(AppColor.textPrimary)

                        Text(viewModel.healthKitAuthorized ? "연결됨" : "수면 데이터를 동기화합니다")
                            .font(.caption)
                            .foregroundColor(AppColor.textSecondary)
                    }

                    Spacer()

                    if viewModel.healthKitAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColor.sleepGood)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
            }
            .listRowBackground(AppColor.cardBackground)
        } header: {
            Text("건강")
                .foregroundColor(AppColor.textSecondary)
        }
    }

    // MARK: - 알림 섹션
    private var notificationSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.toggleNotification()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(AppColor.secondary)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("알림 설정")
                            .font(.body)
                            .foregroundColor(AppColor.textPrimary)

                        Text("취침 알림 및 기록 리마인더")
                            .font(.caption)
                            .foregroundColor(AppColor.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .listRowBackground(AppColor.cardBackground)
        } header: {
            Text("알림")
                .foregroundColor(AppColor.textSecondary)
        }
    }

    // MARK: - 앱 정보 섹션
    private var infoSection: some View {
        Section {
            // 버전 정보
            HStack {
                Label("버전", systemImage: "info.circle")
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(AppColor.textSecondary)
            }
            .listRowBackground(AppColor.cardBackground)

            // 팀 정보
            HStack {
                Label("개발팀", systemImage: "person.2.fill")
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Text("Team Entangle")
                    .foregroundColor(AppColor.textSecondary)
            }
            .listRowBackground(AppColor.cardBackground)

            // 개인정보 처리방침
            HStack {
                Label("개인정보 처리방침", systemImage: "lock.shield")
                    .foregroundColor(AppColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
            .listRowBackground(AppColor.cardBackground)
        } header: {
            Text("정보")
                .foregroundColor(AppColor.textSecondary)
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(premiumService: PremiumService()))
        .preferredColorScheme(.dark)
}
