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
//    @StateObject var userManager = UserManager() // 앱 전체에 UserManager 연결
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
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea() // 전체 화면 사용
                
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
        ("bell", "bell.fill", "공지사항", .orange)
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
                        
                        // 햅틱 피드백
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
                // 메인 글라스 배경 (네모 모양)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // 내부 글로우 효과
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2),
                                        Color.clear,
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        // 상단 하이라이트
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
                
                // 리퀴드 효과를 위한 배경 블러
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
        .padding(.bottom, 30) // 바닥에서 띄움
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
                    // 활성 상태 배경
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
                        // 아이콘
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
                        
                        // 타이틀 (선택된 경우에만)
                        if isSelected {
                            Text(title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(color)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale),
                                    removal: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale)
                                ))
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

// 추가적인 스타일링을 위한 확장된 버전 (기존 유지하되 개선)
struct ModernTabbarView: View {
    @State var tabCurrent = 0
    @State var lastValidTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 메인 콘텐츠 (전체 화면)
                TabView(selection: $tabCurrent) {
                    MainView()
                        .tag(0)
                    
                    NoticeView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // 울트라 글라스 탭바
                VStack {
                    Spacer()
                    UltraGlassTabBar(selectedTab: $tabCurrent, safeAreaBottom: geometry.safeAreaInsets.bottom)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 울트라 글라스 탭바 (더욱 진보된 버전)
struct UltraGlassTabBar: View {
    @Binding var selectedTab: Int
    let safeAreaBottom: CGFloat
    @Namespace private var animationNamespace
    @State private var morphOffset = CGSize.zero
    @State private var glowIntensity: Double = 0.3
    
    private let tabs: [(String, String, String, Color)] = [
        ("house", "house.fill", "홈", .blue),
        ("bell", "bell.fill", "공지사항", .orange)
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
                    
                    // 강한 햅틱 피드백
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    
                    // 글로우 효과 트리거
                    withAnimation(.easeInOut(duration: 0.3)) {
                        glowIntensity = 0.8
                    }
                    withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                        glowIntensity = 0.3
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(
            ZStack {
                // 메인 글라스 컨테이너 (네모 모양)
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // 다층 테두리 효과
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.9),
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                            
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    Color.white.opacity(0.1),
                                    lineWidth: 4
                                )
                                .blur(radius: 2)
                        }
                    )
                
                // 내부 글로우
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(glowIntensity * 0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .animation(.easeInOut(duration: 0.5), value: glowIntensity)
                
                // 리퀴드 모핑 효과
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.08))
                    .blur(radius: 3)
                    .offset(morphOffset)
                    .scaleEffect(1.05)
                    .opacity(0.6)
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
        .shadow(color: .black.opacity(0.1), radius: 60, x: 0, y: 30)
        .padding(.horizontal, 18)
        .padding(.bottom, 35) // 바닥에서 띄움
        .offset(morphOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                        morphOffset = CGSize(
                            width: value.translation.width * 0.08,
                            height: value.translation.height * 0.08
                        )
                    }
                }
                .onEnded { _ in
                    withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.8)) {
                        morphOffset = .zero
                    }
                }
        )
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
    @State private var isPressed = false
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        Button(action: {
            action()
            
            // 파티클 효과 트리거
            withAnimation(.easeInOut(duration: 0.2)) {
                particleOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
                particleOpacity = 0
            }
        }) {
            ZStack {
                // 활성 상태 배경
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.6),
                                            color.opacity(0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .matchedGeometryEffect(id: "ultraBackground", in: namespace)
                        .frame(height: 52)
                
                    // 파티클 효과
                    Capsule()
                        .fill(color.opacity(particleOpacity * 0.3))
                        .frame(height: 52)
                        .blur(radius: 8)
                        .scaleEffect(1.2)
                }
                
                HStack(spacing: 10) {
                    // 아이콘 컨테이너
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color.opacity(0.9), color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .shadow(color: color.opacity(0.5), radius: 12, x: 0, y: 6)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        .frame(width: 40, height: 40)
                                )
                        }
                        
                        Image(systemName: isSelected ? activeIcon : icon)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(isSelected ? .white : Color(.systemGray2))
                            .scaleEffect(isSelected ? 1.0 : 0.85)
                            .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                    }
                    .frame(width: 40, height: 40)
                    
                    // 타이틀
                    if isSelected {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(color)
                            .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: 0)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.8)),
                                removal: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.8))
                            ))
                    }
                }
                .padding(.horizontal, isSelected ? 20 : 10)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// 앱 설정에 따라 원하는 스타일 선택
struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 기본 스타일
            TabbarView()
                .previewDisplayName("Basic Style")
                .environmentObject(UserManager.shared)
            
            // 모던 스타일
            ModernTabbarView()
                .previewDisplayName("Modern Style")
                .environmentObject(UserManager.shared)
        }
    }
}

#Preview {
    TabbarView()
        .environmentObject(UserManager.shared)
}
