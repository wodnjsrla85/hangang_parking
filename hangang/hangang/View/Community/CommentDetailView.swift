//
//  CommentDetail.swift
//  hangang
//
import SwiftUI

struct CommentDetailView: View {
    @Binding var selectedContent: ContentJSON
    @State var commentList: [CommentJSON]
    @State var likeList: [PostLikeJSON]
    
    @State var likeCount: Int = 0
    @State var isLiked: Bool = false
    
    @State var newComment = ""
    @State var isLoading = false
    @State var errorMessage: String?
    @State var showAlert = false
    @FocusState var isFocused: Bool
    
    @State var showActions = false
    @State var showDelete = false
    @State var showUpdate = false
    @Environment(\.dismiss) var dismiss
    
    @State var showReply = false
    @State var selectedComment: CommentJSON?
    @State var replyText = ""
    
    // 로그인 관련 상태
    @State var showLoginAlert = false
    @State var showLoginSheet = false
    
    @EnvironmentObject var userManager: UserManager
    
    var userId: String {
        userManager.isLoggedIn ? userManager.currentUserID : "default_user_id"
    }
    
    private var canAddComment: Bool {
        return userManager.isLoggedIn && !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                postHeaderView
                postContentView
                postStatsView
                
                Divider()
                
                commentInputView
                
                Divider()
                
                commentSectionView
                commentListView
            }
            .padding()
        }
        .navigationTitle("게시글 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if userManager.isLoggedIn && selectedContent.userId == userManager.currentUserID {
                    Button {
                        showActions = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            setupLike()
            Task { await loadData() }
        }
        .overlay {
            if isLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
            }
        }
        // ✅ 수정: alert와 sheet를 body에 직접 추가
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .alert("로그인이 필요합니다", isPresented: $showLoginAlert) {
            Button("로그인하기") {
                showLoginSheet = true
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("댓글 작성은 로그인 후 이용 가능합니다.")
        }
        .alert("게시글 삭제", isPresented: $showDelete) {
            Button("삭제", role: .destructive) { Task { await deletePost() } }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 게시글을 삭제하시겠습니까?")
        }
        .confirmationDialog("옵션 선택", isPresented: $showActions, titleVisibility: .visible) {
            Button("수정") { showUpdate = true }
            Button("삭제", role: .destructive) { showDelete = true }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $showUpdate) {
            ContentUpdateView(content: $selectedContent)
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                showLoginSheet = false
            }
            .environmentObject(userManager)
        }
        .sheet(isPresented: $showReply) {
            CommentReplySheet(
                originalComment: selectedComment,
                replyText: $replyText,
                onSubmit: { reply in },
                onDismiss: { resetReply() }
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
    
    // MARK: - View Components
    
    private var postHeaderView: some View {
        HStack(spacing: 10) {
            Circle().fill(.gray).frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text("\(selectedContent.userId.suffix(20))")
                    .font(.headline).bold()
                Text(getTime(selectedContent.createdAt))
                    .font(.caption).foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var postContentView: some View {
        Text(selectedContent.content)
            .font(.body)
            .padding(.vertical, 8)
    }
    
    private var postStatsView: some View {
        HStack {
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
            
            HStack(spacing: 4) {
                Image(systemName: "bubble.left").foregroundColor(.green)
                Text("\(commentList.filter { comment in comment.postId == selectedContent.id && !comment.deleted }.count)")
                    .foregroundColor(.green)
            }
        }
        .font(.caption)
    }
    
    private var commentInputView: some View {
        HStack {
            ZStack {
                TextField("댓글을 입력하세요...", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .disabled(!userManager.isLoggedIn)
                
                if !userManager.isLoggedIn {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showLoginAlert = true
                        }
                }
            }
            
            Button("작성") {
                if userManager.isLoggedIn {
                    Task { await addComment() }
                    isFocused = false
                } else {
                    showLoginAlert = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(canAddComment ? .blue : .gray)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .background(Color(.systemBackground))
    }
    
    private var commentSectionView: some View {
        HStack {
            Text("댓글").font(.headline).bold()
            Text("(\(commentList.filter { comment in comment.postId == selectedContent.id && !comment.deleted }.count))")
                .font(.headline).foregroundColor(.gray)
            Spacer()
        }
    }
    
    private var commentListView: some View {
        ForEach(commentList.filter { comment in !comment.deleted && comment.postId == selectedContent.id }, id: \.id) { comment in
            CommentRowView(
                comment: comment,
                userManager: userManager,
                onDelete: { commentId in
                    Task { await deleteComment(id: commentId) }
                },
                onReply: { selectedComment in
                    self.selectedComment = selectedComment
                    replyText = "@사용자\(selectedComment.userId.suffix(4)) "
                    showReply = true
                },
                getTime: getTime
            )
        }
    }
    
    // MARK: - Functions (기존 함수들 유지)
    
    func setupLike() {
        likeCount = 3
        isLiked = false
    }
    
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
    
    func resetReply() {
        showReply = false
        replyText = ""
        selectedComment = nil
    }
    
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
    
    func loadData() async {
        await MainActor.run { isLoading = true }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadComments() }
            group.addTask { await loadLikes() }
        }
        await MainActor.run { isLoading = false }
    }
    
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

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: CommentJSON
    let userManager: UserManager
    let onDelete: (String) -> Void
    let onReply: (CommentJSON) -> Void
    let getTime: (String) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(.blue.opacity(0.3)).frame(width: 30, height: 30)
                VStack(alignment: .leading) {
                    Text("\(comment.userId.suffix(20))")
                        .font(.caption).bold()
                    Text(getTime(comment.createdAt))
                        .font(.caption2).foregroundColor(.gray)
                }
                Spacer()
                
                if userManager.isLoggedIn && comment.userId == userManager.currentUserID {
                    Button {
                        onDelete(comment.id)
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
            if userManager.isLoggedIn {
                onReply(comment)
            }
        }
    }
}

// 답글 작성 시트 (기존과 동일)
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
    CommentDetailView(
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
