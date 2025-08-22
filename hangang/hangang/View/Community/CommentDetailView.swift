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
    @State var showLoginAlert = false                     // 댓글 로그인 필요 알림 표시 여부
    @State var showLikeLoginAlert = false                 // 🔄 추가: 좋아요 로그인 알림 표시 여부
    @State var showLoginPage = false                      // 로그인 페이지 표시 여부
    @Environment(\.dismiss) var dismiss                   // 현재 뷰 닫기 처리
    
    @State var showReply = false                          // 답글 작성 시트 표시 여부
    @State var selectedComment: CommentJSON?             // 답글 대상 댓글
    @State var replyText = ""                             // 답글 텍스트
    
    // 키보드 높이 추적을 위한 상태
    @State private var keyboardHeight: CGFloat = 0
    
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
        ZStack {
            backgroundView
            mainContentView
            bottomInputView
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        
        // 커스텀 네비게이션 바
        .safeAreaInset(edge: .top) {
            ModernNavigationBar(
                title: "게시글",
                canEdit: userManager.isLoggedIn && selectedContent.userId == userManager.currentUserID,
                onBack: { dismiss() },
                onAction: { showActions = true }
            )
        }
        
        // 초기 좋아요 및 댓글 데이터 로드
        .onAppear {
            setupLike()
            Task { await loadData() }
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        
        // 로딩 상태 오버레이 표시
        .overlay {
            if isLoading {
                CommentLoadingOverlay(message: "댓글을 불러오는 중...")
            }
        }
        
        // 에러 알림창
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        
        // 🔄 추가: 좋아요 로그인 필요 알림창
        .alert("로그인 필요", isPresented: $showLikeLoginAlert) {
            Button("로그인하기") {
                showLoginPage = true  // 로그인 페이지 표시
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("좋아요 기능은 로그인 후 이용 가능합니다.")
        }
        
        // 댓글 로그인 필요 알림창
        .alert("로그인 필요", isPresented: $showLoginAlert) {
            Button("로그인하기") {
                showLoginPage = true
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("댓글을 작성하려면 로그인이 필요합니다.")
        }
        
        // 게시글 수정/삭제 액션시트
        .confirmationDialog("옵션 선택", isPresented: $showActions, titleVisibility: .visible) {
            Button("수정") { showUpdate = true }
            Button("삭제", role: .destructive) { showDelete = true }
            Button("취소", role: .cancel) {}
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
        
        // 로그인 페이지 시트
        .sheet(isPresented: $showLoginPage) {
            LoginView()  // 실제 로그인 뷰로 교체 필요
                .onDisappear {
                    // 로그인 완료 후 데이터 새로고침
                    if userManager.isLoggedIn {
                        Task { await loadData() }
                    }
                }
        }
        
        // 답글 작성 화면 시트
        .sheet(isPresented: $showReply) {
            CommentReplySheet(
                originalComment: selectedComment,
                replyText: $replyText,
                onSubmit: { reply in /* 답글 등록 로직 필요 */ },
                onDismiss: { resetReply() }
            )
        }
        
        // 배경 탭으로 키보드 내림
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
    
    // 좋아요 초기값 설정 (서버 데이터 불러오기 전 임시)
    func setupLike() {
        likeCount = 3
        isLiked = false
        print("초기 상태 설정: count=\(likeCount), liked=\(isLiked)")
    }
    
    // 🔄 수정: 좋아요 토글 - 로그인 확인 후 alert 표시
    func toggleLike() {
        guard userManager.isLoggedIn else {
            showLikeLoginAlert = true  // 🔄 수정: 좋아요 전용 alert 표시
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
    
    // MARK: - View Components
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            postCardView
            commentSectionView
            Spacer()
        }
    }
    
    private var postCardView: some View {
        ModernPostDetailCard(
            post: selectedContent,
            likeCount: likeCount,
            commentCount: filteredComments.count,
            isLiked: isLiked,
            onLikeTap: { toggleLike() }
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var commentSectionView: some View {
        VStack(spacing: 0) {
            commentHeaderView
            commentListView
        }
    }
    
    private var commentHeaderView: some View {
        ModernCommentHeader(commentCount: filteredComments.count)
            .padding(.horizontal, 20)
            .padding(.top, 20)
    }
    
    private var commentListView: some View {
        Group {
            if filteredComments.isEmpty {
                ModernEmptyComments()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
            } else {
                commentsScrollView
            }
        }
    }
    
    private var commentsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedComments, id: \.id) { comment in
                    commentCardView(for: comment)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 180)
        }
    }
    
    private var bottomInputView: some View {
        VStack {
            Spacer()
            ModernCommentInputBar(
                text: $newComment,
                isLoggedIn: userManager.isLoggedIn,
                canSubmit: canAddComment,
                isFocused: _isFocused,
                onSubmit: {
                    Task { await addComment() }
                    isFocused = false
                },
                onLoginRequired: {
                    showLoginPage = true  // 바로 로그인 페이지 표시
                }
            )
            .offset(y: keyboardHeight > 0 ? -keyboardHeight + 50 : 0)
            .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
        }
    }
    
    private var filteredComments: [CommentJSON] {
        commentList.filter { $0.postId == selectedContent.id && !$0.deleted }
    }
    
    private var sortedComments: [CommentJSON] {
        filteredComments.sorted { $0.createdAt < $1.createdAt }
    }
    
    private func commentCardView(for comment: CommentJSON) -> some View {
        ModernCommentCard(
            comment: comment,
            canDelete: userManager.isLoggedIn && comment.userId == userManager.currentUserID,
            canReply: userManager.isLoggedIn,
            onDelete: {
                Task { await deleteComment(id: comment.id) }
            },
            onReply: {
                selectedComment = comment
                replyText = "@사용자\(comment.userId.suffix(4)) "
                showReply = true
            }
        )
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
    
    // MARK: - 키보드 관련 메서드
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

// MARK: - 모던 네비게이션 바
struct ModernNavigationBar: View {
    let title: String
    let canEdit: Bool
    let onBack: () -> Void
    let onAction: () -> Void
    
    var body: some View {
        HStack {
            // 뒤로가기 버튼
            Button(action: onBack) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            
            // 타이틀
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 액션 버튼 (수정/삭제)
            if canEdit {
                Button(action: onAction) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            } else {
                // 빈 공간
                Circle()
                    .fill(Color.clear)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 모던 게시글 상세 카드
struct ModernPostDetailCard: View {
    let post: ContentJSON
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let onLikeTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 게시글 헤더: 작성자 및 작성시간
            HStack(spacing: 12) {
                // 프로필 아바타
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple.opacity(0.7), .blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(String(post.userId.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(post.userId.suffix(20)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(getTime(post.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 게시글 본문
            Text(post.content)
                .font(.body)
                .lineSpacing(6)
                .foregroundColor(.primary)
            
            // 인터랙션 바
            HStack(spacing: 24) {
                // 좋아요 버튼
                Button(action: onLikeTap) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(isLiked ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text("\(likeCount)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isLiked ? .red : .secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isLiked ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLiked)
                
                // 댓글 수 표시
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text("\(commentCount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    private func getTime(_ dateString: String) -> String {
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

// MARK: - 모던 댓글 헤더
struct ModernCommentHeader: View {
    let commentCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text("댓글")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text("(\(commentCount))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - 모던 댓글 카드
struct ModernCommentCard: View {
    let comment: CommentJSON
    let canDelete: Bool
    let canReply: Bool
    let onDelete: () -> Void
    let onReply: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 프로필 아바타
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.cyan.opacity(0.6), .blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                
                Text(String(comment.userId.prefix(1)).uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // 댓글 내용
            VStack(alignment: .leading, spacing: 8) {
                // 댓글 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(comment.userId.suffix(20)))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(getTime(comment.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 액션 버튼들
                    HStack(spacing: 8) {
                        if canDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // 댓글 텍스트
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func getTime(_ dateString: String) -> String {
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

// MARK: - 빈 댓글 화면
struct ModernEmptyComments: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bubble.left")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text("아직 댓글이 없어요")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("첫 번째 댓글을 남겨보세요!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 40)
        .padding(.bottom, 150)
    }
}

// MARK: - 모던 댓글 입력창
struct ModernCommentInputBar: View {
    @Binding var text: String
    let isLoggedIn: Bool
    let canSubmit: Bool
    @FocusState var isFocused: Bool
    let onSubmit: () -> Void
    let onLoginRequired: () -> Void
    
    init(text: Binding<String>,
         isLoggedIn: Bool,
         canSubmit: Bool,
         isFocused: FocusState<Bool>,
         onSubmit: @escaping () -> Void,
         onLoginRequired: @escaping () -> Void) {
        self._text = text
        self.isLoggedIn = isLoggedIn
        self.canSubmit = canSubmit
        self._isFocused = isFocused
        self.onSubmit = onSubmit
        self.onLoginRequired = onLoginRequired
    }
    
    var body: some View {
        VStack(spacing: 0) {
            dividerView
            inputContentView
        }
    }
    
    private var dividerView: some View {
        Divider()
            .background(Color.white.opacity(0.2))
    }
    
    private var inputContentView: some View {
        HStack(spacing: 12) {
            profileAvatarView
            textInputView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .padding(.bottom, 70)
        .background(.ultraThinMaterial)
    }
    
    private var profileAvatarView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [.green.opacity(0.6), .blue.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 32, height: 32)
            
            Image(systemName: "person.fill")
                .foregroundColor(.white)
                .font(.caption)
        }
    }
    
    private var textInputView: some View {
        HStack {
            textFieldView
            sendButtonView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(textFieldBackground)
    }
    
    // TextField에서 disabled 제거하고 onChange 추가
    private var textFieldView: some View {
        TextField(
            isLoggedIn ? "댓글을 입력하세요..." : "로그인 후 댓글을 작성할 수 있어요",
            text: $text
        )
        .font(.body)
        .focused($isFocused)
        .foregroundColor(isLoggedIn ? .primary : .secondary)
        .onChange(of: isFocused) { focused in
            // 포커스가 갔을 때 로그인 체크
            if focused && !isLoggedIn {
                // 포커스 해제
                isFocused = false
                // 로그인 페이지 표시
                onLoginRequired()
            }
        }
    }
    
    private var sendButtonView: some View {
        Button(action: onSubmit) {
            ZStack {
                Circle()
                    .fill(sendButtonGradient)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.caption)
            }
        }
        .disabled(!canSubmit)
        .scaleEffect(canSubmit ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSubmit)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var sendButtonGradient: LinearGradient {
        canSubmit ?
        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing) :
        LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - 댓글용 로딩 오버레이
struct CommentLoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.3)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
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

// MARK: - 답글 작성 시트
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
                
                VStack(spacing: 20) {
                    // 원본 댓글 표시
                    if let comment = originalComment {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("답글 대상")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                // 프로필 아바타
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: [.cyan.opacity(0.6), .blue.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 36, height: 36)
                                    
                                    Text(String(comment.userId.prefix(1)).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("사용자\(comment.userId.suffix(4))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text(getTime(comment.createdAt))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(comment.content)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
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
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    }
                    
                    // 답글 작성 영역
                    VStack(alignment: .leading, spacing: 12) {
                        Text("답글 작성")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $localText)
                            .font(.body)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .frame(minHeight: 100)
                            .focused($isFocused)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 답글 전송 버튼
                    Button(action: {
                        onSubmit(localText)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("답글 보내기")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                    LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .shadow(
                            color: localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .blue.opacity(0.3),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .disabled(localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("답글 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            localText = replyText
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
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

#Preview {
    NavigationView {
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
}
