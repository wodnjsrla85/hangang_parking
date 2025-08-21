//
//  Community.swift
//  hangang
//


import SwiftUI

struct CommunityView: View {
    @State private var contentList: [ContentJSON] = []      // 게시글 목록 상태
    @State private var commentList: [CommentJSON] = []       // 댓글 목록 상태 (개수 계산용)
    @State private var likeList: [PostLikeJSON] = []         // 좋아요 목록 상태 (개수 계산용)
    
    @State private var isLoading = false                     // 데이터 로딩 상태
    @State private var errorMessage: String?                 // 에러 메시지
    @State private var showAlert = false                     // 에러 알림 표시 여부
    
    var body: some View {
        NavigationView {
            VStack {
                // 게시글이 없을 때 빈 화면 표시
                if contentList.isEmpty && !isLoading {
                    Spacer()
                    ContentUnavailableView(
                        "아직 게시글이 없어요",
                        systemImage: "doc.text",
                        description: Text("첫 번째 게시글을 작성해보세요!")
                    )
                    Spacer()
                } else {
                    // 게시글 목록 출력
                    List {
                        ForEach($contentList, id: \.id) { $item in
                            ZStack(alignment: .leading) {
                                // 게시글 상세 화면으로 네비게이션
                                NavigationLink {
                                    CommentDetail(
                                        selectedContent: $item,
                                        commentList: commentList,
                                        likeList: likeList
                                    )
                                } label: { EmptyView() }
                                .opacity(0)
                                
                                // 게시글 카드 UI
                                VStack(alignment: .leading, spacing: 8) {
                                    // 게시글 헤더: 작성자 및 작성시간
                                    HStack(spacing: 10) {
                                        Circle().fill(.gray).frame(width: 30, height: 30)
                                        VStack(alignment: .leading) {
                                            Text("사용자\(item.userId.suffix(4))")
                                                .font(.title2)
                                            Text(getTime(item.createdAt))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    
                                    // 게시글 본문 내용
                                    Text(item.content)
                                        .padding(.vertical)
                                    
                                    // 좋아요 및 댓글 수 표시
                                    HStack {
                                        Image(systemName: "hand.thumbsup")
                                            .foregroundColor(.blue)
                                        Text("\(getLikeCount(for: item.id))")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "bubble.left")
                                        Text("\(getCommentCount(for: item.id))")
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: 190)
                                .background(.yellow)
                                .cornerRadius(8)
                                .padding(.vertical, 4)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await loadData() }  // 당겨서 새로고침
                }
            }
            
            // 데이터 로딩 중 오버레이
            .overlay {
                if isLoading {
                    ProgressView("로딩 중…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.inline)
            
            // 게시글 작성 버튼 (상단 우측)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ContentAddView(posts: $contentList)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            
            // 화면 진입 시 데이터 로드
            .onAppear { Task { await loadData() } }
            
            // 에러 발생 시 알림창
            .alert("오류", isPresented: $showAlert) {
                Button("다시 시도") { Task { await loadData() } }
                Button("확인", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
            }
        }
    }
    
    // 특정 게시글의 댓글 개수 계산
    private func getCommentCount(for postId: String) -> Int {
        commentList.filter { $0.postId == postId && !$0.deleted }.count
    }
    
    // 특정 게시글의 좋아요 개수 계산
    private func getLikeCount(for postId: String) -> Int {
        likeList.filter { $0.postId == postId }.count
    }
    
    // 모든 데이터 병렬 로드 (게시글, 댓글, 좋아요)
    private func loadData() async {
        await MainActor.run { isLoading = true }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadPosts() }
            group.addTask { await loadComments() }
            group.addTask { await loadLikes() }
        }
        
        await MainActor.run { isLoading = false }
    }
    
    // 게시글 목록 서버 요청
    private func loadPosts() async {
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
    private func loadComments() async {
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
    private func loadLikes() async {
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

#Preview {
    CommunityView()
}
