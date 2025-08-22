//
//  ContentAddView.swift
//  hangang
//
//  게시글 작성 화면
//  - 텍스트 입력 기능 제공 (사진 기능 제거됨)
//  - 새 게시글 서버 전송 및 로컬 목록 업데이트
//

import SwiftUI
// import PhotosUI // ❌ 사진 관련 import 주석처리

struct ContentAddView: View {
    @Binding var posts: [ContentJSON]                  // 상위 뷰 게시글 목록 바인딩
    
    @State var content = ""                     // 작성 중인 게시글 텍스트
    // @State var image: UIImage?               // ❌ 선택한 이미지 주석처리
    // @State var photoItem: PhotosPickerItem?  // ❌ 사진 선택 아이템 주석처리
    @FocusState var isFocused: Bool              // 텍스트 에디터 포커스 상태
    @State var uploading = false                  // 게시글 업로드 중 상태
    @State var showAlert = false                   // 알림 표시 여부
    @State var alertMessage = ""                   // 알림 메시지
    @Environment(\.dismiss) var dismiss            // 현재 뷰 닫기 처리
    
    // 로그인한 사용자 정보를 가져오기 위한 UserManager
    @EnvironmentObject var userManager: UserManager
    
    // 로그인한 사용자 ID 가져오기
    var userId: String {
        userManager.currentUserID
    }
    
    var buttonEnabled: Bool {
        // 디버깅을 위한 상태 출력
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isLoggedIn = userManager.isLoggedIn
        let isNotUploading = !uploading
        
        print("🔍 버튼 상태 확인: hasContent=\(hasContent), isLoggedIn=\(isLoggedIn), isNotUploading=\(isNotUploading)")
        
        return hasContent && isLoggedIn && isNotUploading
    }
    
    var body: some View {
        ZStack {
            backgroundView
            mainContentView
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            modernNavigationBar
        }
        .onAppear {
            setupInitialState()
        }
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onTapGesture {
            isFocused = false
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
        ScrollView {
            VStack(spacing: 24) {
                headerCardView
                contentInputSection
                // photoSection // ❌ 사진 섹션 주석처리
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .overlay(alignment: .bottom) {
            submitButtonView
        }
    }
    
    private var modernNavigationBar: some View {
        HStack {
            // 취소 버튼
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            
            // 타이틀
            Text("새 게시글")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 빈 공간 (대칭을 위해)
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    private var headerCardView: some View {
        VStack(spacing: 16) {
            // 아이콘과 제목
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.purple)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("게시글 작성")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("한강에서의 이야기를 들려주세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text("내용")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 글자수 카운터
                Text("\(content.count)/1000")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            // 텍스트 에디터
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                TextEditor(text: $content)
                    .font(.body)
                    .padding(16)
                    .background(Color.clear)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                
                if content.isEmpty && !isFocused {
                    Text("한강에서의 추억이나 경험을 공유해주세요...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // ❌ 사진 섹션 전체 주석처리
    /*
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "photo")
                        .foregroundColor(.orange)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text("사진")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("(선택사항)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // 사진 선택 영역
            HStack(spacing: 16) {
                // 사진 추가 버튼
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text("사진")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 선택된 이미지 미리보기
                if let img = image {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        // 삭제 버튼
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                image = nil
                                photoItem = nil
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                        .offset(x: 8, y: -8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
        }
    }
    */
    
    private var submitButtonView: some View {
        VStack(spacing: 0) {
            // 그라데이션 분리선
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.1), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            
            // 버튼 영역
            VStack(spacing: 16) {
                // 상태 표시
                if uploading {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("게시글을 작성하는 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                }
                
                // 제출 버튼
                Button(action: handleSubmit) {
                    HStack(spacing: 12) {
                        if uploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(uploading ? "작성 중..." : "게시글 올리기")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                buttonEnabled ?
                                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .shadow(
                        color: buttonEnabled ? .blue.opacity(0.3) : .clear,
                        radius: 8, x: 0, y: 4
                    )
                    .scaleEffect(buttonEnabled ? 1.0 : 0.95)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonEnabled)
                }
                .disabled(!buttonEnabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        print("ContentAddView 나타남")
        print("   - userManager.isLoggedIn: \(userManager.isLoggedIn)")
        print("   - userManager.currentUserID: '\(userManager.currentUserID)'")
        
        // 상태 초기화
        uploading = false
        content = ""
        alertMessage = ""
        showAlert = false
    }
    
    private func handleSubmit() {
        print("🎯 작성 완료 버튼 클릭됨")
        print("   - uploading: \(uploading)")
        print("   - content: '\(content)'")
        print("   - userId: '\(userId)'")
        print("   - buttonEnabled: \(buttonEnabled)")
        
        // 즉시 상태 업데이트로 중복 클릭 방지
        if !uploading {  // 추가 안전장치
            uploading = true
            
            // 즉시 햅틱 피드백
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            Task {
                await writePost()
            }
        }
    }
    
    // ❌ 사진 로드 함수 주석처리 (이미 주석처리 되어 있음)
    /*
    // 선택한 사진을 UIImage로 변환하여 저장 (필요 시 사용)
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item,
              let data = try? await item.loadTransferable(type: Data.self) else {
            return
        }
        
        // UI 업데이트는 메인 스레드에서 수행
        Task { @MainActor in
            image = UIImage(data: data)
        }
    }
    */
    
    //  수정: 게시글 작성 서버 요청 및 로컬 목록 추가 + 디버깅 로그 추가
    private func writePost() async {
        print("📝 writePost 시작")
        
        // 내용 입력 확인 (if문 사용)
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("❌ 빈 내용으로 인한 실패")
            await MainActor.run {
                uploading = false  // 실패 시 상태 복원
                alertMessage = "게시글 내용을 입력해주세요."
                showAlert = true
            }
            return
        }
        
        // 로그인 상태 재확인
        if !userManager.isLoggedIn || userManager.currentUserID.isEmpty {
            print("❌ 로그인 상태 문제")
            await MainActor.run {
                uploading = false
                alertMessage = "로그인이 필요합니다."
                showAlert = true
            }
            return
        }
        
        guard let url = URL(string: "\(baseURL)/community/insert") else {
            print("❌ URL 생성 실패")
            await MainActor.run { uploading = false }
            return
        }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 현재 시간으로 게시글 생성 (로그인한 사용자 정보 사용)
            let currentTime = ISO8601DateFormatter().string(from: Date())
            let newPost = ContentJSON(
                id: UUID().uuidString,
                userId: userManager.currentUserID,  // 로그인한 사용자 ID 사용
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: currentTime,             // 현재 시간으로 설정
                updatedAt: currentTime,             // 생성 시점이므로 동일하게 설정
                deleted: false,
                deletedAt: nil
            )
            req.httpBody = try JSONEncoder().encode(newPost)
            
            print("🌐 서버 요청 시작...")
            let (_, response) = try await URLSession.shared.data(for: req)
            
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            print("✅ 서버 응답 성공")
            
            await MainActor.run {
                posts.insert(newPost, at: 0)  // 상위 뷰 게시글 목록에 추가 (Community에 즉시 반영)
                print("✅ 게시글 작성 성공: 작성자=\(userManager.currentUserID), 시간=\(currentTime)")
                dismiss()                   // 성공 시 현재 뷰 닫기 (uploading = false 불필요)
            }
            
        } catch {
            print("❌ 네트워크 에러: \(error.localizedDescription)")
            await MainActor.run {
                uploading = false  // 실패 시에만 상태 복원
                alertMessage = "게시글 작성에 실패했습니다."
                showAlert = true
                print("❌ 게시글 작성 실패: \(error.localizedDescription)")
            }
        }
        
        // 추가: 성공/실패 관계없이 마지막에 상태 복원 (dismiss 되지 않은 경우를 위해)
        await MainActor.run {
            if !Task.isCancelled {  // 화면이 닫히지 않은 경우만
                uploading = false
            }
        }
    }
}

#Preview {
    ContentAddView(posts: .constant([]))
        .environmentObject(UserManager.shared)
}
