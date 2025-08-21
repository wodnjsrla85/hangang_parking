//
//  TabbarView.swift
//  hangang
//
//  Created by 김재원 on 8/18/25.
//

import SwiftUI

struct TabbarView: View {
    @State var tabCurrent = 0
    @State var lastValidTab = 0
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠 (전체 화면)
                TabView(selection: $tabCurrent) {
                    MainView()
                        .tag(0)
                    
                    NoticeView()
                        .tag(1)
                    
                    Community()
                        .tag(2)   // ✅ 커뮤니티 탭 추가
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // 리퀴드 글라스 탭바 (하단에 오버레이)
                VStack {
                    Spacer()
                    LiquidGlassTabBar(selectedTab: $tabCurrent, safeAreaBottom: geometry.safeAreaInsets.bottom)
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
        ("house", "house.fill", "홈", .blue),
        ("bell", "bell.fill", "공지사항", .orange),
        ("person.3", "person.3.fill", "커뮤니티", .green) // ✅ 커뮤니티 탭 버튼 추가
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
                                    colors: [
                                        color.opacity(0.3),
                                        color.opacity(0.15)
                                    ],
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

// MARK: - 울트라 글라스 탭바 버전
struct ModernTabbarView: View {
    @State var tabCurrent = 0
    @State var lastValidTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $tabCurrent) {
                    MainView()
                        .tag(0)
                    
                    NoticeView()
                        .tag(1)
                    
                    Community()
                        .tag(2)   // ✅ 커뮤니티 탭 추가
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    UltraGlassTabBar(selectedTab: $tabCurrent, safeAreaBottom: geometry.safeAreaInsets.bottom)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 울트라 글라스 탭바
struct UltraGlassTabBar: View {
    @Binding var selectedTab: Int
    let safeAreaBottom: CGFloat
    @Namespace private var animationNamespace
    
    private let tabs: [(String, String, String, Color)] = [
        ("house", "house.fill", "홈", .blue),
        ("bell", "bell.fill", "공지사항", .orange),
        ("person.3", "person.3.fill", "커뮤니티", .green) // ✅ 커뮤니티 탭 버튼 추가
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                UltraGlassTabButton(
                    icon: tabs[index].0,
                    activeIcon: tabs[index].1,
                    title: tabs[index].2,
                    color: tabs[index].3,
                    isSelected: selectedTab == index,
                    namespace: animationNamespace
                ) {
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.8)) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        .shadow(color: .black.opacity(0.1), radius: 60, x: 0, y: 30)
        .padding(.horizontal, 18)
        .padding(.bottom, 35)
    }
}

struct UltraGlassTabButton: View {
    let icon: String
    let activeIcon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? activeIcon : icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(.systemGray2))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? color : .clear)
                    )
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, isSelected ? 20 : 10)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                Capsule().fill(color.opacity(0.2))
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 프리뷰
struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabbarView()
                .environmentObject(UserManager.shared)
            
            ModernTabbarView()
                .environmentObject(UserManager.shared)
        }
    }
}

#Preview {
    TabbarView()
        .environmentObject(UserManager.shared)
}
