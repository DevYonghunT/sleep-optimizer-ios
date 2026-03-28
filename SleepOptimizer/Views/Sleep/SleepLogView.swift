//
//  SleepLogView.swift
//  SleepOptimizer
//
//  수면 기록 메인 화면 — 취침/기상 시각, 수면 품질, 메모 입력
//

import SwiftUI
import SwiftData

struct SleepLogView: View {
    // MARK: - 의존성
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - 최근 기록 쿼리 (최신순)
    @Query(sort: \SleepRecord.bedTime, order: .reverse)
    private var allRecords: [SleepRecord]

    /// 최근 7일 기록만 표시
    private var recentRecords: [SleepRecord] {
        Array(allRecords.prefix(7))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    headerSection

                    // 취침 시각 선택
                    timePickerSection(
                        title: "취침 시각",
                        icon: "moon.fill",
                        selection: $viewModel.bedTime
                    )

                    // 기상 시각 선택
                    timePickerSection(
                        title: "기상 시각",
                        icon: "sunrise.fill",
                        selection: $viewModel.wakeTime
                    )

                    // 수면 품질 선택
                    qualitySection

                    // 메모 입력
                    notesSection

                    // 기록 버튼
                    saveButton

                    // 최근 기록 리스트
                    recentRecordsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(AppColor.background)
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .alert("기록 완료", isPresented: $viewModel.showingSuccessAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("수면 기록이 저장되었습니다")
            }
        }
    }

    // MARK: - 헤더 섹션
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColor.primary, AppColor.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("오늘의 수면을 기록하세요")
                .font(.subheadline)
                .foregroundColor(AppColor.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - 시각 선택 섹션
    private func timePickerSection(title: String, icon: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            DatePicker(
                title,
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipped()
            .colorScheme(.dark)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 수면 품질 선택
    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("수면 품질", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SleepQuality.allCases) { quality in
                        qualityButton(quality)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    /// 개별 품질 선택 버튼
    private func qualityButton(_ quality: SleepQuality) -> some View {
        let isSelected = viewModel.selectedQuality == quality

        return VStack(spacing: 6) {
            Text(quality.emoji)
                .font(.system(size: 28))

            Text(quality.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(
                    isSelected ? AppColor.primary : AppColor.textSecondary
                )
        }
        .frame(width: 64, height: 72)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppColor.primary.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? AppColor.primary : Color.clear,
                    lineWidth: 2
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedQuality = quality
            }
        }
    }

    // MARK: - 메모 입력
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("메모", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            TextField("오늘의 수면에 대한 메모...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...5)
                .padding(12)
                .background(AppColor.secondaryBackground)
                .cornerRadius(12)
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(16)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - 저장 버튼
    private var saveButton: some View {
        Button {
            viewModel.saveSleepRecord()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("수면 기록하기")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(GlowButtonStyle())
    }

    // MARK: - 최근 기록 리스트
    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !recentRecords.isEmpty {
                Text("최근 기록")
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                ForEach(recentRecords) { record in
                    SleepRecordCardView(record: record)
                }
            }
        }
    }
}

#Preview {
    SleepLogView(viewModel: SleepLogViewModel(premiumService: PremiumService()))
        .modelContainer(for: SleepRecord.self, inMemory: true)
        .preferredColorScheme(.dark)
}
