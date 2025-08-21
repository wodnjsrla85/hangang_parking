//
//  InquiryView.swift
//  hangang
//
//  Created by 정서윤 on 8/18/25.
//

import SwiftUI

struct InquiryView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedOption: InquiryOption?
    @State private var showingOneOnOne = false
    @State private var showingHistory = false
    
    private let inquiryOptions = [
        InquiryOption(
            id: 0,
            icon: "bubble.left.and.bubble.right.fill",
            title: "1:1 문의",
            subtitle: "개인적인 문의사항을 보내주세요",
            description: "관리자가 직접 답변해드립니다",
            color: .blue,
            gradientColors: [.blue, .cyan]
        ),
        InquiryOption(
            id: 1,
            icon: "clock.arrow.circlepath",
            title: "나의 문의내역",
            subtitle: "이전에 보낸 문의사항을 확인하세요",
            description: "답변 상태와 히스토리를 볼 수 있습니다",
            color: .green,
            gradientColors: [.green, .mint]
        )
    ]
    
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
                    // 헤더 카드
                    InquiryHeaderCard()
                    
                    // 문의 옵션 카드들
                    LazyVStack(spacing: 16) {
                        ForEach(inquiryOptions, id: \.id) { option in
                            ModernInquiryCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id
                            ) {
                                selectOption(option)
                            }
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedOption?.id)
                        }
                    }
                    
                    // 도움말 카드
                    HelpCard()
                    
                    Spacer(minLength: 100) // 탭바 공간 확보
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("문의사항")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        
        // Navigation Links
        NavigationLink(destination: OneOnOneInquiry(), isActive: $showingOneOnOne) {
            EmptyView()
        }
        .hidden()
        
        NavigationLink(destination: MyInquiryHistory(), isActive: $showingHistory) {
            EmptyView()
        }
        .hidden()
    }
    
    private func selectOption(_ option: InquiryOption) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedOption = option
        }
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 0.3초 후 네비게이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch option.id {
            case 0:
                showingOneOnOne = true
            case 1:
                showingHistory = true
            default:
                break
            }
            
            // 선택 상태 초기화
            selectedOption = nil
        }
    }
}

// MARK: - 데이터 모델
struct InquiryOption {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
    let gradientColors: [Color]
}

// MARK: - 헤더 카드
struct InquiryHeaderCard: View {
    var body: some View {
        VStack(spacing: 16) {
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
                    .frame(width: 80, height: 80)
                
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 40, weight: .semibold))
            }
            
            // 텍스트
            VStack(spacing: 8) {
                Text("어떤 도움이 필요하신가요?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("문의사항이 있으시면 언제든지 연락해주세요.\n빠르고 정확한 답변을 드리겠습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - 모던 문의 카드
struct ModernInquiryCard: View {
    let option: InquiryOption
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // 아이콘 영역
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: option.gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: option.icon)
                        .foregroundColor(option.color)
                        .font(.system(size: 28, weight: .semibold))
                }
                
                // 텍스트 영역
                VStack(alignment: .leading, spacing: 8) {
                    Text(option.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 화살표 아이콘
                Image(systemName: "chevron.right")
                    .foregroundColor(option.color)
                    .font(.system(size: 16, weight: .semibold))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isSelected ?
                            option.color.opacity(0.6) :
                            Color.white.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                )
                .shadow(
                    color: isSelected ?
                    option.color.opacity(0.3) :
                    Color.black.opacity(0.05),
                    radius: isSelected ? 20 : 10,
                    x: 0,
                    y: isSelected ? 10 : 5
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        )
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 도움말 카드
struct HelpCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("문의 전 확인사항")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HelpTip(
                    icon: "checkmark.circle.fill",
                    text: "자주 묻는 질문을 먼저 확인해보세요",
                    color: .green
                )
                
                HelpTip(
                    icon: "clock.fill",
                    text: "답변은 영업일 기준 1-2일 소요됩니다",
                    color: .blue
                )
                
                HelpTip(
                    icon: "envelope.fill",
                    text: "정확한 연락처를 입력해주세요",
                    color: .purple
                )
                
                HelpTip(
                    icon: "exclamationmark.triangle.fill",
                    text: "긴급한 경우 고객센터로 전화문의 바랍니다",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - 도움말 팁
struct HelpTip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - 고객센터 정보 카드 (추가 옵션)
struct CustomerServiceCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("고객센터")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("긴급 문의 시 이용해주세요")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: {
                    if let phoneURL = URL(string: "tel://1588-1234") {
                        UIApplication.shared.open(phoneURL)
                    }
                }) {
                    Image(systemName: "phone.circle.fill")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
            
            Divider()
                .overlay(Color.white.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("운영시간")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("평일 09:00 - 18:00")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("전화번호")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("1588-1234")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
}

#Preview {
    NavigationView {
        InquiryView()
            .environmentObject(UserManager.shared)
    }
}
