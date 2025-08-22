//
//  NoticeView.swift
//  hangang
//
//  Created by 정서윤 on 8/18/25.
//

import SwiftUI

struct NoticeView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var goInquiry = false
    @State private var showLoginAlert = false
    @State private var showLoginSheet = false
    @State private var selectedTab = 0
    @Namespace private var animationNamespace
    
    private let tabs = ["분수일정", "행사공연"]
    
    var body: some View {
        NavigationView {
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
                    // 커스텀 헤더
                    ModernHeader()
                    
                    // 탭 선택 영역
                    ModernTabSelector(
                        tabs: tabs,
                        selectedTab: $selectedTab,
                        namespace: animationNamespace
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 콘텐츠 영역
                    TabView(selection: $selectedTab) {
                        FountainScheduleView()
                            .tag(0)
                        
                        EventsView()
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    
                    Spacer(minLength: 100) // 탭바 공간 확보
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        // 네비게이션 링크
        NavigationLink(destination: InquiryView(), isActive: $goInquiry) {
            EmptyView()
        }
        .hidden()
        
        // 로그인 알림
        .alert("로그인이 필요합니다", isPresented: $showLoginAlert) {
            Button("로그인하기") {
                showLoginSheet = true
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("로그인 후 이용 가능합니다.")
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                print("🎉 로그인 성공 콜백 호출됨")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    goInquiry = true
                }
            }
        }
        .onChange(of: goInquiry) {
            print("📍 goInquiry 상태 변경: \(goInquiry)")
        }
        .onChange(of: userManager.isLoggedIn) {
            print("👤 UserManager 로그인 상태 변경: \(userManager.isLoggedIn)")
        }
    }
    
    // 문의 버튼 액션
    private func handleInquiryTap() {
        print("🔘 문의 버튼 클릭됨")
        print("👤 현재 로그인 상태: \(userManager.isLoggedIn)")
        
        if userManager.isLoggedIn {
            print("✅ 로그인됨 - InquiryView로 이동")
            goInquiry = true
        } else {
            print("❌ 비로그인 - 로그인 Alert 표시")
            showLoginAlert = true
        }
    }
}

// MARK: - 모던 헤더
struct ModernHeader: View {
    @EnvironmentObject var userManager: UserManager
    @State private var goInquiry = false
    @State private var showLoginAlert = false
    @State private var showLoginSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("공지사항")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("한강공원의 최신 소식을 확인하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 문의 버튼
            Button(action: handleInquiryTap) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        
        // 네비게이션 및 시트 처리
        NavigationLink(destination: InquiryView(), isActive: $goInquiry) {
            EmptyView()
        }
        .hidden()
        
        .alert("로그인이 필요합니다", isPresented: $showLoginAlert) {
            Button("로그인하기") {
                showLoginSheet = true
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("로그인 후 이용 가능합니다.")
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    goInquiry = true
                }
            }
        }
    }
    
    private func handleInquiryTap() {
        if userManager.isLoggedIn {
            goInquiry = true
        } else {
            showLoginAlert = true
        }
    }
}

// MARK: - 모던 탭 선택기
struct ModernTabSelector: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    
                    // 햅틱 피드백
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        if selectedTab == index {
                            Capsule()
                                .fill(Color.blue)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 분수 일정 뷰
struct FountainScheduleView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 제목 카드
                InfoCard(
                    icon: "cloud.rainbow.crop",
                    iconColor: .blue,
                    title: "무지개분수 운영 안내",
                    subtitle: "한강공원 무지개분수의 상세 운영 일정을 확인하세요"
                )
                
                // 비수기 일정
                ScheduleCard(
                    period: "비수기",
                    duration: "4월 - 6월, 9월 - 10월",
                    runtime: "매회 20분",
                    times: "12:00, 19:30, 20:00, 20:30, 21:00",
                    color: .green
                )
                
                // 성수기 일정
                ScheduleCard(
                    period: "성수기",
                    duration: "7월 - 8월",
                    runtime: "매회 20분",
                    times: "12:00, 19:30, 20:00, 20:30, 21:00, 21:30",
                    color: .orange
                )
                
                // 주의사항 카드
                NoticeCard()
                
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - 행사공연 뷰
struct EventsView: View {
    private let events = [
        EventData(
            imageName: "한강페스티벌",
            title: "2025 한강페스티벌 여름",
            period: "2025-07-26(토) ~ 2025-08-24(일)",
            time: "프로그램별 상이",
            participation: "프로그램별 상이",
            location: "한강 수상과 10개 한강공원 일대"
        ),
        EventData(
            imageName: "한강사진공모전",
            title: "제22회 아름다운 한강사진 공모전",
            period: "2025-07-09(수) ~ 2025-08-28(목)",
            time: "프로그램별 상이",
            participation: "온라인 접수",
            location: "한강 및 한강공원 전역"
        ),
        EventData(
            imageName: "서울 러닝크루",
            title: "7979 서울 러닝크루",
            period: "2025-04-10(목) ~ 2025-10-30(목)",
            time: "저녁 7시~9시",
            participation: "사전접수 및 현장참여",
            location: "반포한강공원 달빛광장, 여의도공원 문화의 마당"
        ),
        EventData(
            imageName: "한강역사탐방",
            title: "2025년 한강 역사탐방",
            period: "2025-04-04(금) ~ 2025-11-30(일)",
            time: "1일 2회 오전 10 ~ 12시, 오후 2 ~ 4시",
            participation: "3월 28일(금)부터 선착순 진행, 참여희망일 5일전까지",
            location: "한강공원과 인근 문화유산(16코스)"
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<events.count, id: \.self) { index in
                    ModernEventCard(event: events[index])
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: true)
                }
                
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - 데이터 모델
struct EventData {
    let imageName: String
    let title: String
    let period: String
    let time: String
    let participation: String
    let location: String
}

// MARK: - 정보 카드
struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
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
    }
}

// MARK: - 일정 카드
struct ScheduleCard: View {
    let period: String
    let duration: String
    let runtime: String
    let times: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text(period)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(runtime)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(color)
                    )
            }
            
            // 기간
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(duration)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // 운영시간
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(times)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 주의사항 카드
struct NoticeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("운영 중지 조건")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text("전력낭비 방지를 위해 기상상황에 따라 분수 가동이 중지될 수 있습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - 모던 이벤트 카드
struct ModernEventCard: View {
    let event: EventData
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 🔥 Asset 이미지 로드
            Image(event.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // 콘텐츠
            VStack(alignment: .leading, spacing: 12) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    EventInfoRow(icon: "calendar", label: "기간", content: event.period)
                    EventInfoRow(icon: "clock", label: "시간", content: event.time)
                    EventInfoRow(icon: "person.fill", label: "참여", content: event.participation)
                    EventInfoRow(icon: "location", label: "장소", content: event.location)
                }
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
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}


// MARK: - 이벤트 정보 행
struct EventInfoRow: View {
    let icon: String
    let label: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            Text(content)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

#Preview {
    NoticeView()
        .environmentObject(UserManager.shared)
}
