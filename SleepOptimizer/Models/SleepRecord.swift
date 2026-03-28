//
//  SleepRecord.swift
//  SleepOptimizer
//
//  수면 기록 데이터 모델 (SwiftData)
//

import Foundation
import SwiftData

/// 수면 기록
@Model
final class SleepRecord {
    /// 고유 식별자
    var id: UUID

    /// 취침 시각
    var bedTime: Date

    /// 기상 시각
    var wakeTime: Date

    /// 수면 품질 원시값 (SleepQuality.rawValue)
    var qualityRawValue: String

    /// 메모 (선택사항)
    var notes: String

    /// 생성 일시
    var createdAt: Date

    /// 수면 품질 (계산 프로퍼티)
    var quality: SleepQuality {
        get { SleepQuality(rawValue: qualityRawValue) ?? .fair }
        set { qualityRawValue = newValue.rawValue }
    }

    /// 수면 시간 (초 단위)
    /// 자정을 넘기는 경우 (취침 > 기상) 24시간을 보정한다
    var duration: TimeInterval {
        let interval = wakeTime.timeIntervalSince(bedTime)
        if interval < 0 {
            return interval + 86400 // 자정 경과 보정 (24시간)
        }
        return interval
    }

    /// 수면 시간 (시간 단위, 소수점)
    var durationHours: Double {
        duration / 3600.0
    }

    init(
        id: UUID = UUID(),
        bedTime: Date,
        wakeTime: Date,
        quality: SleepQuality = .fair,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.qualityRawValue = quality.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}
