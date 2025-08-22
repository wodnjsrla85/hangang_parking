//
//  MyInquiryHistory.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct MyInquiryHistory: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject var viewModel = InquiryViewModel()
    @State private var selectedFilter: InquiryFilter = .all
    @State private var isRefreshing = false
    @Namespace private var animationNamespace
    
    private let filters: [InquiryFilter] = [.all, .answered, .pending]
    
    // 필터링된 문의 목록
    private var filteredInquiries: [Inquiry] {
        switch selectedFilter {
        case .all:
            return viewModel.inquiries
        case .answered:
            return viewModel.inquiries.filter { $0.isAnswered }
        case .pending:
            return viewModel.inquiries.filter { !$0.isAnswered }
        }
    }
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더 섹션
                InquiryHistoryHeader(
                    totalCount: viewModel.inquiries.count,
                    answeredCount: viewModel.inquiries.filter { $0.isAnswered }.count,
                    pendingCount: viewModel.inquiries.filter { !$0.isAnswered }.count
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 필터 탭
                FilterTabView(
                    filters: filters,
                    selectedFilter: $selectedFilter,
                    namespace: animationNamespace
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // 콘텐츠 영역
                if viewModel.inquiries.isEmpty {
                    EmptyStateView()
                } else if filteredInquiries.isEmpty {
                    EmptyFilterStateView(filter: selectedFilter)
                } else {
                    InquiryListView(
                        inquiries: filteredInquiries,
                        isRefreshing: $isRefreshing,
                        onRefresh: {
                            await refreshData()
                        }
                    )
                }
                
                Spacer(minLength: 100) // 탭바 공간 확보
            }
        }
        .navigationTitle("나의 문의내역")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserInquiries(userID: userManager.currentUserID)
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        await viewModel.fetchInquiries()
        
        // 새로고침 애니메이션
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        isRefreshing = false
    }
}

// MARK: - 필터 열거형
enum InquiryFilter: CaseIterable {
    case all, answered, pending
    
    var title: String {
        switch self {
        case .all: return "전체"
        case .answered: return "답변완료"
        case .pending: return "답변대기"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .answered: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .answered: return .green
        case .pending: return .orange
        }
    }
}

// MARK: - 헤더 뷰
struct InquiryHistoryHeader: View {
    let totalCount: Int
    let answeredCount: Int
    let pendingCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // 메인 카드
            HStack(spacing: 20) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                // 텍스트 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text("문의 내역")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("총 \(totalCount)건의 문의사항")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            
            // 통계 카드들
            HStack(spacing: 12) {
                StatCard(
                    title: "전체",
                    count: totalCount,
                    icon: "list.bullet",
                    color: .blue
                )

                StatCard(
                    title: "답변완료",
                    count: answeredCount,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "답변대기",
                    count: pendingCount,
                    icon: "clock.fill",
                    color: .orange
                )
                
            }
        }
    }
}

// MARK: - 통계 카드
struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 필터 탭 뷰
struct FilterTabView: View {
    let filters: [InquiryFilter]
    @Binding var selectedFilter: InquiryFilter
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(filters, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                    
                    // 햅틱 피드백
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: filter.icon)
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text(filter.title)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedFilter == filter ? .white : filter.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            if selectedFilter == filter {
                                Capsule()
                                    .fill(filter.color)
                                    .matchedGeometryEffect(id: "filterBackground", in: namespace)
                            } else {
                                Capsule()
                                    .fill(filter.color.opacity(0.1))
                            }
                        }
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 문의 목록 뷰
struct InquiryListView: View {
    let inquiries: [Inquiry]
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(inquiries.enumerated()), id: \.element.id) { index, inquiry in
                    NavigationLink(destination: InquiryDetail(inquiry: inquiry)) {
                        InquiryHistoryCard(inquiry: inquiry)
                            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: inquiries.count)
                    }
                    .buttonStyle(InquiryCardButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - 커스텀 버튼 스타일
struct InquiryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - 문의 히스토리 카드
struct InquiryHistoryCard: View {
    let inquiry: Inquiry
    
    private var statusColor: Color {
        inquiry.isAnswered ? .green : .orange
    }
    
    private var borderColor: Color {
        inquiry.isAnswered ? Color.green.opacity(0.3) : Color.orange.opacity(0.3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            headerSection
            
            // 내용 미리보기
            contentPreview

        }
        .padding(20)
        .background(cardBackground)
        .contentShape(Rectangle()) // 터치 영역을 명확히 정의
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(inquiry.safeTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(inquiry.qdate ?? "날짜 미확인")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 상태 배지
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: inquiry.isAnswered ? "checkmark.circle.fill" : "clock.fill")
                .foregroundColor(.white)
                .font(.caption)
            
            Text(inquiry.displayState)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor)
        )
    }
    
    private var contentPreview: some View {
        Text(inquiry.safeContent)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

// MARK: - 빈 상태 뷰
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 일러스트레이션
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                    .font(.system(size: 48, weight: .light))
            }
            
            // 텍스트
            VStack(spacing: 8) {
                Text("문의 내역이 없습니다")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("새로운 문의를 작성해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 필터 빈 상태 뷰
struct EmptyFilterStateView: View {
    let filter: InquiryFilter
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 아이콘
            ZStack {
                Circle()
                    .fill(filter.color.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: filter.icon)
                    .foregroundColor(filter.color)
                    .font(.system(size: 40, weight: .light))
            }
            
            // 텍스트
            VStack(spacing: 8) {
                Text("\(filter.title) 문의가 없습니다")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(getEmptyMessage(for: filter))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func getEmptyMessage(for filter: InquiryFilter) -> String {
        switch filter {
        case .all:
            return "문의 내역이 없습니다"
        case .answered:
            return "아직 답변완료된 문의가 없습니다"
        case .pending:
            return "답변 대기 중인 문의가 없습니다"
        }
    }
}

#Preview {
    NavigationView {
        MyInquiryHistory()
            .environmentObject(UserManager.shared)
    }
}
