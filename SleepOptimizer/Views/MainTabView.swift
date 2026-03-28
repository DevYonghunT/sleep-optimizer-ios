//
//  MainTabView.swift
//  SleepOptimizer
//
//  메인 탭 네비게이션 — 수면 기록, 통계, 알람, 설정
//

import SwiftUI

struct MainTabView: View {
    // MARK: - 공유 서비스
    @StateObject private var premiumService = PremiumService()

    // MARK: - 뷰모델
    @StateObject private var sleepLogVM: SleepLogViewModel
    @StateObject private var statisticsVM: StatisticsViewModel
    @StateObject private var alarmVM: AlarmViewModel
    @StateObject private var settingsVM: SettingsViewModel

    /// 선택된 탭 인덱스
    @State private var selectedTab: Int = 0

    init() {
        let premium = PremiumService()
        let notification = NotificationService.shared
        let healthKit = HealthKitService.shared

        _premiumService = StateObject(wrappedValue: premium)
        _sleepLogVM = StateObject(wrappedValue: SleepLogViewModel(premiumService: premium))
        _statisticsVM = StateObject(wrappedValue: StatisticsViewModel(premiumService: premium))
        _alarmVM = StateObject(wrappedValue: AlarmViewModel(premiumService: premium, notificationService: notification))
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(notificationService: notification, premiumService: premium, healthKitService: healthKit))

        // 탭바 외관 커스터마이징
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.background)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 수면 기록 탭
            SleepLogView(viewModel: sleepLogVM)
                .tabItem {
                    Label("수면 기록", systemImage: "moon.fill")
                }
                .tag(0)

            // 통계 탭
            StatisticsView(viewModel: statisticsVM)
                .tabItem {
                    Label("통계", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // 알람 탭
            AlarmView(viewModel: alarmVM)
                .tabItem {
                    Label("알람", systemImage: "alarm.fill")
                }
                .tag(2)

            // 설정 탭
            SettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppColor.primary)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
