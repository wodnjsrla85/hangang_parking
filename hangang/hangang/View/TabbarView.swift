//
//  TabbarView.swift
//  hangang
//
//  Created by 김재원 on 8/18/25.
//

import SwiftUI

struct TabbarView: View {
    @State var tabCurrent = 0
    @State var lastValidTab = 0 // 마지막 유효한 탭 저장
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠 (전체 화면)
                TabView(selection: $tabCurrent) {
                    TabView(selection: $tabCurrent) {
                        NavigationView {
                            MainView()
                        }
                        .tag(0)
                        .ignoresSafeArea()

                        NavigationView {
                            NoticeView()
                        }
                        .tag(1)

                        NavigationView {
                            BuskingView()
                        }
                        .tag(2)

                        NavigationView {
                            CommunityView()
                        }
                        .tag(3)
                    }
                    .ignoresSafeArea()
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // 리퀴드 글라스 탭바 (하단에 오버레이)
                VStack {
                    Spacer()
                    LiquidGlassTabBar(
                        selectedTab: $tabCurrent,
                        safeAreaBottom: geometry.safeAreaInsets.bottom
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 리퀴드 글라스 탭바
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let safeAreaBottom: CGFloat
    @Namespace private var animationNamespace
    @State private var dragAmount = CGSize.zero
    
    private let tabItems: [(icon: String, activeIcon: String, title: String, color: Color)] = [
        ("house", "house.fill", "", .blue),
        ("bell", "bell.fill", "", .orange),
        ("music.mic", "music.mic.fill", "", .yellow), // ✅ 버스킹 탭 버튼 추가
        ("person.3", "person.3.fill", "", .green)  // ✅ 커뮤니티 탭 버튼 추가
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                LiquidGlassTabButton(
                    icon: tabItems[index].icon,
                    activeIcon: tabItems[index].activeIcon,
                    title: tabItems[index].title,
                    color: tabItems[index].color,
                    isSelected: selectedTab == index,
                    namespace: animationNamespace,
                    action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.8)) {
                            selectedTab = index
                        }
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 1)
                    .offset(dragAmount)
                    .scaleEffect(1.02)
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 10)
        .shadow(color: .black.opacity(0.05), radius: 50, x: 0, y: 20)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .offset(dragAmount)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragAmount = CGSize(
                        width: value.translation.width * 0.1,
                        height: value.translation.height * 0.1
                    )
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dragAmount = .zero
                    }
                }
        )
    }
}

struct LiquidGlassTabButton: View {
    let icon: String
    let activeIcon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.4), lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "liquidBackground", in: namespace)
                            .frame(height: 48)
                    }
                    
                    HStack(spacing: 8) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(color)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            
                            Image(systemName: isSelected ? activeIcon : icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isSelected ? .white : Color(.systemGray))
                                .scaleEffect(isSelected ? 1.0 : 0.9)
                        }
                        .frame(width: 36, height: 36)
                        
                        if isSelected {
                            Text(title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(color)
                        }
                    }
                    .padding(.horizontal, isSelected ? 16 : 8)
                    .padding(.vertical, 6)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - 프리뷰
struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        TabbarView()
            .environmentObject(UserManager.shared)
    }
}

#Preview {
    TabbarView()
        .environmentObject(UserManager.shared)
}
