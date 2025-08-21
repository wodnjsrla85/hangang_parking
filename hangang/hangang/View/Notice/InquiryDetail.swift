//
//  InquiryDetail.swift
//  hangang
//
//  Created by 정서윤 on 8/20/25.
//

import SwiftUI

struct InquiryDetail: View {
    @EnvironmentObject var userManager: UserManager
    let inquiry: Inquiry
    @State private var showingShareSheet = false
    
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더 상태 카드
                    InquiryStatusHeader(inquiry: inquiry)
                    
                    // 문의 내용 섹션
                    InquiryContentSection(inquiry: inquiry)
                    
                    // 메타 정보 섹션
                    InquiryMetaSection(inquiry: inquiry)
                    
                    // 답변 또는 대기 섹션
                    if inquiry.isAnswered {
                        AdminAnswerSection(inquiry: inquiry)
                    } else {
                        WaitingForAnswerSection()
                    }
                    
                    // 액션 버튼들
                    ActionButtonsSection(
                        inquiry: inquiry,
                        showingShareSheet: $showingShareSheet
                    )
                    
                    Spacer(minLength: 100) // 탭바 공간 확보
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("문의 상세")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareInquiryView(inquiry: inquiry)
        }
    }
}

// MARK: - 문의 상태 헤더
struct InquiryStatusHeader: View {
    let inquiry: Inquiry
    
    private var statusConfig: (color: Color, icon: String, title: String) {
        if inquiry.isAnswered {
            return (.green, "checkmark.circle.fill", "답변완료")
        } else {
            return (.orange, "clock.fill", "답변대기")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 상태 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [statusConfig.color.opacity(0.3), statusConfig.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusConfig.icon)
                    .foregroundColor(statusConfig.color)
                    .font(.system(size: 36, weight: .semibold))
            }
            
            // 상태 정보
            VStack(spacing: 8) {
                Text(statusConfig.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(statusConfig.color)
                
                Text(inquiry.isAnswered ? "관리자가 답변을 완료했습니다" : "관리자가 답변을 준비 중입니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(statusConfig.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: statusConfig.color.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - 문의 내용 섹션
struct InquiryContentSection: View {
    let inquiry: Inquiry
    
    var body: some View {
        VStack(spacing: 20) {
            // 제목 카드
            DetailCard(
                icon: "doc.text.fill",
                iconColor: .blue,
                title: "문의 제목",
                content: inquiry.safeTitle,
                isExpandable: false
            )
            
            // 내용 카드
            DetailCard(
                icon: "text.alignleft",
                iconColor: .purple,
                title: "문의 내용",
                content: inquiry.safeContent,
                isExpandable: true
            )
        }
    }
}

// MARK: - 메타 정보 섹션
struct InquiryMetaSection: View {
    let inquiry: Inquiry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                Text("문의 정보")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            // 정보 항목들
            VStack(spacing: 12) {
                MetaInfoRow(
                    icon: "person.fill",
                    label: "작성자",
                    value: inquiry.safeUserID,
                    color: .blue
                )
                
                MetaInfoRow(
                    icon: "calendar",
                    label: "작성일",
                    value: inquiry.qdate ?? "날짜 미확인",
                    color: .green
                )
                
                MetaInfoRow(
                    icon: "checkmark.seal.fill",
                    label: "처리상태",
                    value: inquiry.displayState,
                    color: inquiry.isAnswered ? .green : .orange
                )
                
                if inquiry.isAnswered, let adate = inquiry.adate {
                    MetaInfoRow(
                        icon: "clock.arrow.circlepath",
                        label: "답변일",
                        value: adate,
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 관리자 답변 섹션
struct AdminAnswerSection: View {
    let inquiry: Inquiry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("관리자 답변")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                // 답변 완료 배지
                Text("답변완료")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.green)
                    )
            }
            
            // 답변 내용
            if let answerContent = inquiry.answerContent, !answerContent.isEmpty {
                Text(answerContent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("답변 내용을 불러올 수 없습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .green.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - 답변 대기 섹션
struct WaitingForAnswerSection: View {
    var body: some View {
        VStack(spacing: 20) {
            // 대기 아이콘
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
                    .font(.system(size: 40, weight: .light))
            }
            
            // 대기 메시지
            VStack(spacing: 12) {
                Text("답변 준비 중")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("관리자가 문의사항을 검토하고 있습니다.\n빠른 시일 내에 답변드리겠습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 예상 시간 안내
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("일반적으로 1-2일 내에 답변드립니다")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .orange.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - 액션 버튼들
struct ActionButtonsSection: View {
    let inquiry: Inquiry
    @Binding var showingShareSheet: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 문의 공유 버튼
            ModernActionButton(
                icon: "square.and.arrow.up",
                title: "문의 내용 공유",
                color: .blue,
                style: .filled
            ) {
                showingShareSheet = true
            }
            
            // 새 문의 작성 버튼
            ModernActionButton(
                icon: "plus.message.fill",
                title: "새 문의 작성",
                color: .green,
                style: .outlined
            ) {
                // 새 문의 작성 액션
                print("새 문의 작성")
            }
        }
    }
}

// MARK: - 공통 컴포넌트들

// 상세 카드
struct DetailCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    let isExpandable: Bool
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isExpandable && content.count > 100 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(iconColor)
                            .font(.subheadline)
                    }
                }
            }
            
            // 내용
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(isExpandable && !isExpanded ? 3 : nil)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// 메타 정보 행
struct MetaInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// 모던 액션 버튼
struct ModernActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let style: ButtonStyle
    let action: () -> Void
    @State private var isPressed = false
    
    enum ButtonStyle {
        case filled, outlined
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(style == .filled ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(style == .filled ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color, lineWidth: style == .outlined ? 2 : 0)
                    )
                    .shadow(
                        color: style == .filled ? color.opacity(0.3) : .clear,
                        radius: style == .filled ? 10 : 0,
                        x: 0,
                        y: style == .filled ? 5 : 0
                    )
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 공유 시트
struct ShareInquiryView: View {
    let inquiry: Inquiry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 공유 내용 미리보기
                VStack(alignment: .leading, spacing: 16) {
                    Text("공유할 내용")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(shareText)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
                
                Spacer()
                
                // 공유 버튼
                Button("공유하기") {
                    shareInquiry()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("문의 공유")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("닫기") { dismiss() })
        }
    }
    
    private var shareText: String {
        """
        [한강공원 문의사항]
        
        제목: \(inquiry.safeTitle)
        내용: \(inquiry.safeContent)
        작성일: \(inquiry.qdate ?? "날짜 미확인")
        상태: \(inquiry.displayState)
        """
    }
    
    private func shareInquiry() {
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        
        dismiss()
    }
}

