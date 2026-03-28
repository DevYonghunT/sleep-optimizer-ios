//
//  SleepRecordCardView.swift
//  SleepOptimizer
//
//  개별 수면 기록 카드 — 날짜, 시간, 수면 시간, 품질 배지 표시
//

import SwiftUI
import SwiftData

struct SleepRecordCardView: View {
    // MARK: - 속성
    let record: SleepRecord
    @Environment(\.modelContext) private var modelContext

    /// 날짜 포맷터
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }

    /// 시각 포맷터
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    /// 품질에 따른 색상
    private var qualityColor: Color {
        AppColor.qualityColor(for: record.quality)
    }

    var body: some View {
        HStack(spacing: 14) {
            // 품질 이모지
            Text(record.quality.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                // 날짜
                Text(dateFormatter.string(from: record.bedTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)

                // 시간 범위
                HStack(spacing: 4) {
                    Text(timeFormatter.string(from: record.bedTime))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(timeFormatter.string(from: record.wakeTime))
                }
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // 수면 시간
                Text(String(format: "%.1f시간", record.durationHours))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.secondary)

                // 품질 배지
                Text(record.quality.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(qualityColor.opacity(0.2))
                    .foregroundColor(qualityColor)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(AppColor.cardBackground)
        .cornerRadius(14)
        .contextMenu {
            Button(role: .destructive) {
                deleteRecord()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - 기록 삭제
    private func deleteRecord() {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SleepRecord.self, configurations: config)

    let record = SleepRecord(
        bedTime: Calendar.current.date(bySettingHour: 23, minute: 30, second: 0, of: Date())!,
        wakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!,
        quality: .good,
        notes: "테스트 메모"
    )
    container.mainContext.insert(record)

    return SleepRecordCardView(record: record)
        .modelContainer(container)
        .padding()
        .background(AppColor.background)
        .preferredColorScheme(.dark)
}
