//
//  SleepOptimizerApp.swift
//  SleepOptimizer
//
//  앱 진입점 — SwiftData 컨테이너 및 다크 테마 설정
//

import SwiftUI
import SwiftData

@main
struct SleepOptimizerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [SleepRecord.self])
    }
}
