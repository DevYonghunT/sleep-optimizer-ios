//
//  SleepQuality.swift
//  SleepOptimizer
//
//  수면 품질 등급 열거형
//

import Foundation

/// 수면 품질 등급
enum SleepQuality: String, CaseIterable, Identifiable, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case terrible = "terrible"

    var id: String { rawValue }

    /// 한국어 표시 이름
    var displayName: String {
        switch self {
        case .excellent: return "최상"
        case .good: return "좋음"
        case .fair: return "보통"
        case .poor: return "나쁨"
        case .terrible: return "최악"
        }
    }

    /// SF Symbol 아이콘 이름 (달 변형)
    var iconName: String {
        switch self {
        case .excellent: return "moon.stars.fill"
        case .good: return "moon.fill"
        case .fair: return "moon.haze.fill"
        case .poor: return "moon.circle"
        case .terrible: return "moon.zzz"
        }
    }

    /// 이모지
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "🌙"
        case .fair: return "😐"
        case .poor: return "😩"
        case .terrible: return "💀"
        }
    }

    /// 점수 (1~5, 높을수록 좋음)
    var score: Int {
        switch self {
        case .excellent: return 5
        case .good: return 4
        case .fair: return 3
        case .poor: return 2
        case .terrible: return 1
        }
    }
}
