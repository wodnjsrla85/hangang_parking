//
//  ContentAddView.swift
//  hangang
//
//  게시글 작성 화면
//  - 텍스트 입력 기능 제공
//  - 새 게시글 서버 전송 및 로컬 목록 업데이트
//

import SwiftUI
// import PhotosUI  // 사진 기능 사용 안 함

struct ContentAddView: View {
    @Binding var posts: [ContentJSON]                  // 상위 뷰 게시글 목록 바인딩
    
    @State var content = ""                     // 작성 중인 게시글 텍스트
    // @State var image: UIImage?               // 선택한 이미지 - 주석처리
    // @State var photoItem: PhotosPickerItem?  // 사진 선택 아이템 - 주석처리
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
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isLoggedIn = userManager.isLoggedIn
        let isNotUploading = !uploading
        
        return hasContent && isLoggedIn && isNotUploading
    }
    
    var body: some View {
        ScrollView {  // 스크롤 가능하도록 수정
            VStack(spacing: 20) {
                // 내용 입력 헤더
                HStack {
                    Text("내용").font(.title).bold()
                    Spacer()
                }
                
                // TextEditor
                TextEditor(text: $content)
                    .frame(minHeight: 200, maxHeight: 400)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    )
                    .focused($isFocused)
                
                // 사진 첨부 섹션 - 전체 주석처리
                /*
                // 사진 첨부 헤더
                HStack {
                    Text("사진").font(.title).bold()
                    Spacer()
                }
                
                // 사진 선택 및 미리보기 UI
                HStack {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Text("+").frame(width: 70, height: 100)
                            .font(.system(size: 50))
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(.buttonBorder)
                    }
                    
                    // 선택된 이미지 미리보기
                    if let img = image {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    
                    Spacer()
                }
                */
                
                // 작성 완료 버튼
                Button(uploading ? "작성 중..." : "작성 완료") {
                    if !uploading {
                        uploading = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        Task { await writePost() }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(buttonEnabled ? .blue : .gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .font(.title3).bold()
                .disabled(!buttonEnabled)
            }
            .padding(20)
        }
        .navigationTitle("게시글 작성")
        .navigationBarTitleDisplayMode(.inline)
        
        // 뷰 진입 시 상태 초기화
        .onAppear {
            uploading = false
            content = ""
            alertMessage = ""
            showAlert = false
        }
        
        // 사진 선택 변경 시 이미지 로딩 처리 - 주석처리
        /*
        .onChange(of: photoItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        */
        
        // 알림창 표시
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        // 배경 탭 시 키보드 내리기
        .onTapGesture { isFocused = false }
    }
    
    // 선택한 사진을 UIImage로 변환하여 저장 - 주석처리
    /*
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
    
    // 게시글 작성 서버 요청 및 로컬 목록 추가
    private func writePost() async {
        // 내용 입력 확인
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                uploading = false
                alertMessage = "게시글 내용을 입력해주세요."
                showAlert = true
            }
            return
        }
        
        // 로그인 상태 재확인
        guard userManager.isLoggedIn && !userManager.currentUserID.isEmpty else {
            await MainActor.run {
                uploading = false
                alertMessage = "로그인이 필요합니다."
                showAlert = true
            }
            return
        }
        
        guard let url = URL(string: "\(baseURL)/community/insert") else {
            await MainActor.run { uploading = false }
            return
        }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 현재 시간으로 게시글 생성
            let currentTime = ISO8601DateFormatter().string(from: Date())
            let newPost = ContentJSON(
                id: UUID().uuidString,
                userId: userManager.currentUserID,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: currentTime,
                updatedAt: currentTime,
                deleted: false,
                deletedAt: nil
            )
            req.httpBody = try JSONEncoder().encode(newPost)
            
            let (_, response) = try await URLSession.shared.data(for: req)
            
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            await MainActor.run {
                posts.insert(newPost, at: 0)  // 상위 뷰 게시글 목록에 추가
                print("게시글 작성 성공: 작성자=\(userManager.currentUserID)")
                dismiss()  // 성공 시 현재 뷰 닫기
            }
            
        } catch {
            await MainActor.run {
                uploading = false
                alertMessage = "게시글 작성에 실패했습니다.\n\(error.localizedDescription)"
                showAlert = true
                print("게시글 작성 실패:", error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContentAddView(posts: .constant([]))
            .environmentObject(UserManager.shared)
    }
}
