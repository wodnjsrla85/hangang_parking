//
//  CommentDetail.swift
//  hangang
//
import SwiftUI

struct CommentDetail: View {
    @Binding var selectedContent: ContentJSON          // 선택된 게시글 데이터 바인딩
    @State var commentList: [CommentJSON]              // 댓글 리스트 상태
    @State var likeList: [PostLikeJSON]                // 좋아요 리스트 상태
    
    @State var likeCount: Int = 0                       // 좋아요 개수 상태
    @State var isLiked: Bool = false                    // 현재 좋아요 여부 상태
    
    @State var newComment = ""                           // 새 댓글 입력 텍스트
    @State var isLoading = false                         // 로딩 인디케이터 상태
    @State var errorMessage: String?                     // 에러 메시지
    @State var showAlert = false                          // 에러 알림 표시 여부
    @FocusState var isFocused: Bool                       // 입력 필드 포커스 상태
    
    @State var showActions = false                        // 게시글 수정/삭제 옵션 표시 여부
    @State var showDelete = false                         // 삭제 확인 알림 표시 여부
    @State var showUpdate = false                         // 게시글 수정 화면 표시 여부
    @Environment(\.dismiss) var dismiss                   // 현재 뷰 닫기 처리
    
    @State var showReply = false                          // 답글 작성 시트 표시 여부
    @State var selectedComment: CommentJSON?             // 답글 대상 댓글
    @State var replyText = ""                             // 답글 텍스트
    
    // 로그인한 사용자 정보를 가져오기 위한 UserManager
    @EnvironmentObject var userManager: UserManager
    
    // 로그인한 사용자 ID 가져오기
    var userId: String {
        userManager.isLoggedIn ? userManager.currentUserID : "default_user_id"
    }
    
    // 댓글 작성 가능 여부 확인
    private var canAddComment: Bool {
        return userManager.isLoggedIn && !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // 게시글 헤더: 게시물 작성자 프로필 및 작성시간 표시
                HStack(spacing: 10) {
                    Circle().fill(.gray).frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text("\(selectedContent.userId.suffix(20))")  // 게시물 작성자 ID
                            .font(.headline).bold()
                        Text(getTime(selectedContent.createdAt))          // 게시물 작성 시간
                            .font(.caption).foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                // 게시글 본문 내용 표시
                Text(selectedContent.content)
                    .font(.body)
                    .padding(.vertical, 8)
                
                // 좋아요 및 댓글 수 표시 영역
                HStack {
                    // 좋아요 토글 버튼
                    Button {
                        toggleLike()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundColor(isLiked ? .blue : .gray)
                            Text("\(likeCount)")
                                .foregroundColor(isLiked ? .blue : .gray)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // 댓글 수 표시
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left").foregroundColor(.green)
                        Text("\(commentList.filter { comment in comment.postId == selectedContent.id && !comment.deleted }.count)")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                
                Divider()
                
                // 댓글 작성 입력창 및 등록 버튼
                HStack {
                    TextField("댓글을 입력하세요...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .disabled(!userManager.isLoggedIn)
                    
                    Button("작성") {
                        Task { await addComment() }
                        isFocused = false
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(canAddComment ? .blue : .gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!canAddComment)
                }
                .background(Color(.systemBackground))
                
                // 로그인되지 않았을 때 안내 메시지
                if !userManager.isLoggedIn {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.orange)
                        Text("댓글 작성은 로그인 후 이용 가능합니다.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 8)
                }
                
                Divider()
                
                // 댓글 섹션 헤더: 댓글 개수 포함
                HStack {
                    Text("댓글").font(.headline).bold()
                    Text("(\(commentList.filter { comment in comment.postId == selectedContent.id && !comment.deleted }.count))")
                        .font(.headline).foregroundColor(.gray)
                    Spacer()
                }
                
                // 댓글 리스트 출력 - 각 댓글 작성자별로 표시
                ForEach(commentList.filter { comment in !comment.deleted && comment.postId == selectedContent.id }, id: \.id) { comment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.blue.opacity(0.3)).frame(width: 30, height: 30)
                            VStack(alignment: .leading) {
                                Text("\(comment.userId.suffix(20))")      // 댓글 작성자 ID
                                    .font(.caption).bold()
                                Text(getTime(comment.createdAt))              // 댓글 작성 시간
                                    .font(.caption2).foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // 댓글 삭제 버튼 - 로그인된 사용자의 본인 댓글만 표시
                            if userManager.isLoggedIn && comment.userId == userManager.currentUserID {
                                Button {
                                    Task { await deleteComment(id: comment.id) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption2).foregroundColor(.red)
                                }
                            }
                        }
                        Text(comment.content)
                            .font(.body)
                            .padding(.leading, 35)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        // 답글 기능 - 로그인된 경우만
                        if userManager.isLoggedIn {
                            selectedComment = comment
                            replyText = "@사용자\(comment.userId.suffix(4)) "
                            showReply = true
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("게시글 상세")
        .navigationBarTitleDisplayMode(.inline)
        
        // 게시글 수정/삭제 옵션 메뉴 - 로그인된 사용자의 본인 게시글만
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if userManager.isLoggedIn && selectedContent.userId == userManager.currentUserID {
                    Button {
                        showActions = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .confirmationDialog("옵션 선택", isPresented: $showActions, titleVisibility: .visible) {
                        Button("수정") { showUpdate = true }
                        Button("삭제", role: .destructive) { showDelete = true }
                        Button("취소", role: .cancel) {}
                    }
                }
            }
        }
        
        // 초기 좋아요 및 댓글 데이터 로드
        .onAppear {
            setupLike()
            Task { await loadData() }
        }
        
        // 로딩 상태 오버레이 표시
        .overlay {
            if isLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        
        // 에러 알림창
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        
        // 게시글 삭제 확인 알림
        .alert("게시글 삭제", isPresented: $showDelete) {
            Button("삭제", role: .destructive) { Task { await deletePost() } }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 게시글을 삭제하시겠습니까?")
        }
        
        // 게시글 수정 화면 시트
        .sheet(isPresented: $showUpdate) {
            ContentUpdateView(content: $selectedContent)
        }
        
        // 답글 작성 화면 시트
        .sheet(isPresented: $showReply) {
            replySheet
        }
        
        // 배경 탭으로 키보드 내림
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
    
    var replySheet: some View {
        CommentReplySheet(
            originalComment: selectedComment,
            replyText: $replyText,
            onSubmit: { reply in /* 답글 등록 로직 필요 */ },
            onDismiss: { resetReply() }
        )
    }
    
    // 좋아요 초기값 설정 (서버 데이터 불러오기 전 임시)
    func setupLike() {
        likeCount = 3
        isLiked = false
        print("초기 상태 설정: count=\(likeCount), liked=\(isLiked)")
    }
    
    // 좋아요 토글 - 단순한 로그인 확인
    func toggleLike() {
        guard userManager.isLoggedIn else {
            errorMessage = "좋아요는 로그인 후 이용 가능합니다"
            showAlert = true
            return
        }
        
        if isLiked {
            likeCount = max(0, likeCount - 1)
            isLiked = false
        } else {
            likeCount += 1
            isLiked = true
        }
        
        Task {
            do {
                if isLiked {
                    try await sendLike()
                } else {
                    try await sendUnlike()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "좋아요 처리 중 오류가 발생했습니다."
                    showAlert = true
                }
            }
        }
    }
    
    // 좋아요 등록 요청
    func sendLike() async throws {
        let url = URL(string: "\(baseURL)/postlike/insert")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeData = PostLikeJSON(
            id: UUID().uuidString,
            postId: selectedContent.id,
            userId: userId,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        req.httpBody = try JSONEncoder().encode(likeData)
        
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
    
    // 좋아요 취소 요청
    func sendUnlike() async throws {
        let url = URL(string: "\(baseURL)/postlike/delete")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deleteData = [
            "postId": selectedContent.id,
            "userId": userId
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: deleteData)
        
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
    
    // 답글 작성 상태 초기화
    func resetReply() {
        showReply = false
        replyText = ""
        selectedComment = nil
    }
    
    // 게시글 삭제 처리
    func deletePost() async {
        do {
            let url = URL(string: "\(baseURL)/community/delete/\(selectedContent.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            await MainActor.run {
                selectedContent.deleted = true
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "게시글 삭제 중 오류가 발생했습니다."
                showAlert = true
            }
        }
    }
    
    // 데이터(댓글, 좋아요) 로드
    func loadData() async {
        await MainActor.run { isLoading = true }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadComments() }
            group.addTask { await loadLikes() }
        }
        await MainActor.run { isLoading = false }
    }
    
    // 댓글 로드
    func loadComments() async {
        do {
            let url = URL(string: "\(baseURL)/comment/select")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct CommentData: Decodable { let results: [CommentJSON] }
            let result = try JSONDecoder().decode(CommentData.self, from: data)
            
            await MainActor.run {
                commentList = result.results
                    .filter { comment in comment.postId == selectedContent.id && !comment.deleted }
                    .sorted { $0.createdAt < $1.createdAt }
            }
        } catch {
            await MainActor.run {
                errorMessage = "댓글을 불러올 수 없어요."
                showAlert = true
            }
        }
    }
    
    // 좋아요 로드
    func loadLikes() async {
        do {
            let url = URL(string: "\(baseURL)/postlike/select")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct LikeData: Decodable { let results: [PostLikeJSON] }
            let result = try JSONDecoder().decode(LikeData.self, from: data)
            
            await MainActor.run {
                let postLikes = result.results.filter { $0.postId == selectedContent.id }
                likeList = postLikes
                likeCount = postLikes.count
                isLiked = postLikes.contains { $0.userId == userId }
            }
        } catch {
            print("좋아요 조회 실패:", error.localizedDescription)
        }
    }
    
    // 댓글 등록 - 단순한 로그인 확인
    func addComment() async {
        guard userManager.isLoggedIn else {
            await MainActor.run {
                errorMessage = "댓글 작성은 로그인 후 이용 가능합니다"
                showAlert = true
            }
            return
        }
        
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                errorMessage = "댓글 내용을 입력해주세요"
                showAlert = true
            }
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/comment/insert")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let commentData = CommentJSON(
                id: "temp_id",
                postId: selectedContent.id,
                userId: userId,
                content: newComment.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: "", updatedAt: "",
                deleted: false, deletedAt: nil
            )
            req.httpBody = try JSONEncoder().encode(commentData)
            
            let (_, response) = try await URLSession.shared.data(for: req)
            
            if let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode {
                await MainActor.run {
                    newComment = ""
                }
                await loadData()
            } else {
                throw URLError(.badServerResponse)
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "댓글 작성에 실패했습니다."
                showAlert = true
            }
        }
    }
    
    // 댓글 삭제
    func deleteComment(id: String) async {
        do {
            let url = URL(string: "\(baseURL)/comment/delete/\(id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            
            let (_, response) = try await URLSession.shared.data(for: req)
            
            if let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode {
                await loadData()
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            await MainActor.run {
                errorMessage = "댓글 삭제 중 오류 발생."
                showAlert = true
            }
        }
    }
    
    // 작성시간을 상대적 시간으로 변환 (예: 3분 전, 2시간 전)
    func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 { return "\(Int(seconds))초 전" }
        if seconds < 3600 { return "\(Int(seconds/60))분 전" }
        if seconds < 86400 { return "\(Int(seconds/3600))시간 전" }
        if seconds < 604800 { return "\(Int(seconds/86400))일 전" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "ko_KR")
        dateFormatter.dateFormat = "MM월 dd일"
        return dateFormatter.string(from: date)
    }
}

// 답글 작성 시트
struct CommentReplySheet: View {
    let originalComment: CommentJSON?
    @Binding var replyText: String
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void
    
    @State var localText: String = ""
    @FocusState var isFocused: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let comment = originalComment {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.blue.opacity(0.3)).frame(width: 30, height: 30)
                            VStack(alignment: .leading) {
                                Text("사용자\(comment.userId.suffix(4))")
                                    .font(.caption).bold()
                                Text(getTime(comment.createdAt))
                                    .font(.caption2).foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        Text(comment.content)
                            .font(.body)
                            .padding(.leading, 35)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("답글 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            localText = replyText
            isFocused = true
        }
    }
    
    func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 { return "\(Int(seconds))초 전" }
        if seconds < 3600 { return "\(Int(seconds/60))분 전" }
        if seconds < 86400 { return "\(Int(seconds/3600))시간 전" }
        if seconds < 604800 { return "\(Int(seconds/86400))일 전" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .init(identifier: "ko_KR")
        dateFormatter.dateFormat = "MM월 dd일"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CommentDetail(
        selectedContent: .constant(
            ContentJSON(
                id: "1",
                userId: "user123",
                content: "테스트 게시글 내용",
                createdAt: "2025-08-20T12:00:00",
                updatedAt: "2025-08-20T12:00:00",
                deleted: false,
                deletedAt: nil
            )
        ),
        commentList: [],
        likeList: []
    )
    .environmentObject(UserManager.shared)
}
