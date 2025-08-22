//
//  Community.swift
//  hangang
//

import SwiftUI

struct CommunityView: View {
    @State var contentList: [ContentJSON] = []      // 게시글 목록 상태
    @State var commentList: [CommentJSON] = []       // 댓글 목록 상태 (개수 계산용)
    @State var likeList: [PostLikeJSON] = []         // 좋아요 목록 상태 (개수 계산용)
    
    @State var isLoading = false                     // 데이터 로딩 상태
    @State var errorMessage: String?                 // 에러 메시지
    @State var showAlert = false                     // 에러 알림 표시 여부
    
    @EnvironmentObject var userManager: UserManager          // 로그인 상태 관리
    @State var goContentAdd = false                  // 게시글 작성 화면으로 이동 상태
    @State var showLoginAlert = false                // 로그인 필요 알림 표시 여부
    @State var showLoginSheet = false                // 로그인 화면 시트 표시 여부
    @State var pendingContentAdd = false             // 로그인 후 게시글 작성 대기 상태
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 커뮤니티 헤더 카드
                ModernCommunityHeader(
                    userManager: userManager,
                    onAddPost: {
                        print("🔘 Plus 버튼 클릭됨") // 디버그용
                        print("🔍 현재 로그인 상태: \(userManager.isLoggedIn)")
                        print("🔍 현재 goContentAdd 상태: \(goContentAdd)")
                        
                        if userManager.isLoggedIn {
                            print("✅ 로그인된 상태 - goContentAdd를 true로 설정")
                            goContentAdd = true
                            print("🔄 설정 후 goContentAdd 상태: \(goContentAdd)")
                        } else {
                            print("❌ 로그인되지 않은 상태 - 로그인 알림 표시")
                            pendingContentAdd = true  // 게시글 작성 대기 상태 설정
                            showLoginAlert = true
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 게시글이 없을 때 빈 화면 표시
                if contentList.isEmpty && !isLoading {
                    Spacer()
                    ModernEmptyView()
                    Spacer()
                } else {
                    // 게시글 목록 출력
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach($contentList, id: \.id) { $item in
                                NavigationLink {
                                    CommentDetail(
                                        selectedContent: $item,
                                        commentList: commentList,
                                        likeList: likeList
                                    )
                                } label: {
                                    ModernPostCard(
                                        post: item,
                                        likeCount: getLikeCount(for: item.id),
                                        commentCount: getCommentCount(for: item.id)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100) // 탭바 공간 확보
                    }
                    .refreshable { await loadData() }  // 당겨서 새로고침
                }
            }
        }
        
        // 데이터 로딩 중 오버레이
        .overlay {
            if isLoading {
                ModernLoadingOverlay()
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        
        // 화면 진입 시 데이터 로드
        .onAppear { Task { await loadData() } }
        
        // 에러 발생 시 알림창
        .alert("오류", isPresented: $showAlert) {
            Button("다시 시도") { Task { await loadData() } }
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        
        // ✅ 수정: 로그인 알림
        .alert("로그인이 필요합니다", isPresented: $showLoginAlert) {
            Button("로그인하기") {
                print("🔑 로그인하기 버튼 클릭")
                showLoginSheet = true
            }
            Button("취소", role: .cancel) {
                pendingContentAdd = false  // 취소 시 대기 상태 해제
            }
        } message: {
            Text("게시글 작성은 로그인 후 이용 가능합니다.")
        }
        
        // 게시글 작성 화면을 sheet로 표시
        .sheet(isPresented: $goContentAdd) {
            NavigationView {
                ContentAddView(posts: $contentList)
                    .environmentObject(userManager)
            }
        }
        
        // 수정: 로그인 화면 시트
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                print("🎉 로그인 성공 콜백 호출됨")
                showLoginSheet = false  // 로그인 화면 닫기
                
                // 로그인 성공 후 즉시 게시글 작성으로 이동
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if pendingContentAdd {
                        print("✅ 대기 중이던 게시글 작성 실행")
                        pendingContentAdd = false
                        goContentAdd = true
                    }
                }
            }
            .environmentObject(userManager)
        }
        
        .onChange(of: goContentAdd) { newValue in
            print("📍 goContentAdd 상태 변경: \(newValue)")
        }
        .onChange(of: userManager.isLoggedIn) { newValue in
            print("👤 UserManager 로그인 상태 변경: \(newValue)")
        }
        .onChange(of: showLoginSheet) { newValue in
            print("🔑 로그인 시트 상태 변경: \(newValue)")
        }
        .onChange(of: pendingContentAdd) { newValue in
            print("⏳ 게시글 작성 대기 상태: \(newValue)")
        }
    }
    
    // 특정 게시글의 댓글 개수 계산
    func getCommentCount(for postId: String) -> Int {
        commentList.filter { $0.postId == postId && !$0.deleted }.count
    }
    
    // 특정 게시글의 좋아요 개수 계산
    func getLikeCount(for postId: String) -> Int {
        likeList.filter { $0.postId == postId }.count
    }
    
    // 모든 데이터 병렬 로드 (게시글, 댓글, 좋아요)
    func loadData() async {
        await MainActor.run { isLoading = true }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadPosts() }
            group.addTask { await loadComments() }
            group.addTask { await loadLikes() }
        }
        
        await MainActor.run { isLoading = false }
    }
    
    // 게시글 목록 서버 요청
    func loadPosts() async {
        do {
            let url = URL(string: "\(baseURL)/community/select")!
            let (data, _) = try await URLSession.shared.data(from: url)
            struct PostData: Decodable { let results: [ContentJSON] }
            let result = try JSONDecoder().decode(PostData.self, from: data)
            
            await MainActor.run {
                contentList = result.results
                    .filter { !$0.deleted }                     // 삭제되지 않은 게시글만
                    .sorted { $0.createdAt > $1.createdAt }    // 최신순 정렬
            }
        } catch {
            await MainActor.run {
                errorMessage = "게시글을 불러올 수 없어요.\n인터넷 연결을 확인해주세요."
                showAlert = true
            }
        }
    }
    
    // 댓글 목록 서버 요청
    func loadComments() async {
        do {
            let url = URL(string: "\(baseURL)/comment/select")!
            let (data, _) = try await URLSession.shared.data(from: url)
            struct CommentData: Decodable { let results: [CommentJSON] }
            let result = try JSONDecoder().decode(CommentData.self, from: data)
            await MainActor.run { commentList = result.results }
        } catch {
            print("댓글 로드 실패:", error.localizedDescription)
        }
    }
    
    // 좋아요 목록 서버 요청
    func loadLikes() async {
        do {
            let url = URL(string: "\(baseURL)/postlike/select")!
            let (data, _) = try await URLSession.shared.data(from: url)
            struct LikeData: Decodable { let results: [PostLikeJSON] }
            let result = try JSONDecoder().decode(LikeData.self, from: data)
            await MainActor.run { likeList = result.results }
        } catch {
            print("좋아요 로드 실패:", error.localizedDescription)
        }
    }
    
    // 작성시간을 상대적 시간으로 변환 (예: 3분 전, 2시간 전)
    func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        switch seconds {
        case ..<60:
            return "\(Int(seconds))초 전"
        case ..<3600:
            return "\(Int(seconds/60))분 전"
        case ..<86400:
            return "\(Int(seconds/3600))시간 전"
        case ..<604800:
            return "\(Int(seconds/86400))일 전"
        default:
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "MM월 dd일"
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - 모던 커뮤니티 헤더
struct ModernCommunityHeader: View {
    @ObservedObject var userManager: UserManager
    let onAddPost: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 커뮤니티 아이콘
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
            }
            
            // 헤더 텍스트
            VStack(alignment: .leading, spacing: 4) {
                Text("한강 커뮤니티")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("이야기를 나누어요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 게시글 작성 버튼
            Button(action: onAddPost) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 모던 게시글 카드
struct ModernPostCard: View {
    let post: ContentJSON
    let likeCount: Int
    let commentCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 게시글 헤더: 작성자 및 작성시간
            HStack(spacing: 12) {
                // 프로필 아바타
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.cyan.opacity(0.7), .blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Text(String(post.userId.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(post.userId.suffix(20)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(getTime(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
//                // 더보기 버튼
//                Image(systemName: "ellipsis")
//                    .foregroundColor(.secondary)
//                    .font(.system(size: 16, weight: .semibold))
            }
            
            // 게시글 본문 내용
            Text(post.content)
                .font(.body)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
            
            // 인터랙션 바
            HStack(spacing: 24) {
                // 좋아요 버튼
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Text("\(likeCount)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                // 댓글 버튼
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Text("\(commentCount)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
//                // 공유 버튼
//                ZStack {
//                    Circle()
//                        .fill(Color.green.opacity(0.1))
//                        .frame(width: 32, height: 32)
//                    
//                    Image(systemName: "square.and.arrow.up")
//                        .foregroundColor(.green)
//                        .font(.system(size: 14, weight: .semibold))
//                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: post.id)
    }
    
    // 작성시간을 상대적 시간으로 변환
    private func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        switch seconds {
        case ..<60:
            return "\(Int(seconds))초 전"
        case ..<3600:
            return "\(Int(seconds/60))분 전"
        case ..<86400:
            return "\(Int(seconds/3600))시간 전"
        case ..<604800:
            return "\(Int(seconds/86400))일 전"
        default:
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "MM월 dd일"
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - 모던 빈 화면
struct ModernEmptyView: View {
    var body: some View {
        VStack(spacing: 24) {
            // 일러스트레이션
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                Text("아직 게시글이 없어요")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("첫 번째 게시글을 작성해보세요!\n한강에서의 추억을 공유해주세요.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - 모던 로딩 오버레이
struct ModernLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.3)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("게시글을 불러오는 중...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
        }
    }
}

// MARK: - 모던 추가 버튼
struct ModernAddButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold))
            }
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }
}

#Preview {
    NavigationView {
        CommunityView()
            .environmentObject(UserManager.shared)
    }
}
