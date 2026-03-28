//
//  Date+Extensions.swift
//  SleepOptimizer
//
//  수면 앱용 날짜 유틸리티 확장
//

import Foundation

extension Date {
    /// 오늘 날짜의 시작 (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 시:분 형식 문자열 (HH:mm)
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }

    /// 수면 날짜 표시 문자열 (오늘/어제/날짜)
    var sleepDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "오늘"
        } else if calendar.isDateInYesterday(self) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M월 d일 (E)"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: self)
        }
    }

    /// 시간:분 표시 문자열 (오전/오후 포함)
    var hourMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }

    /// N일 전 날짜 반환
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    /// 오늘로부터 N일 전 날짜 (정적 헬퍼)
    static func daysAgo(_ days: Int) -> Date {
        Date().daysAgo(days)
    }
}

extension TimeInterval {
    /// 시간/분 형식 문자열 (예: "7시간 30분")
    var durationString: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}
