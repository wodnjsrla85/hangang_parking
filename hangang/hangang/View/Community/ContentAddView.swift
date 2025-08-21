//
//  ContentAddView.swift
//  hangang
//
//  게시글 작성 화면
//  - 텍스트 입력 및 사진 선택 기능 제공
//  - 새 게시글 서버 전송 및 로컬 목록 업데이트
//

import SwiftUI
import PhotosUI

struct ContentAddView: View {
    @Binding var posts: [ContentJSON]                  // 상위 뷰 게시글 목록 바인딩
    
    @State var content = ""                     // 작성 중인 게시글 텍스트
    @State var image: UIImage?                   // 선택한 이미지
    @State var photoItem: PhotosPickerItem?     // 사진 선택 아이템
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
        VStack {
            Spacer()
            
            // 내용 입력 헤더
            HStack {
                Text("내용").font(.title).bold().padding(.horizontal, 20)
                Spacer()
            }
            
            // 내용 입력 필드 (TextEditor)
            TextEditor(text: $content)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .colorMultiply(.blue.opacity(0.2))
                .clipShape(.rect(cornerRadius: 10))
                .focused($isFocused)
            
            // 사진 첨부 헤더
            HStack {
                Text("사진").font(.title).bold().padding(.horizontal, 20)
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
                .padding()
                
                // 선택된 이미지 미리보기
                if let img = image {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 10))
                        .padding()
                }
                
                Spacer()
            }
            
            // 수정: 작성 완료 버튼 - 즉시 상태 업데이트 적용 + 디버깅 로그 추가
            Button(uploading ? "작성 중..." : "작성 완료") {
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
            .frame(width: 300, height: 50)
            .background(buttonEnabled ? .blue : .gray)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 30))
            .font(.title3).bold()
            .disabled(!buttonEnabled)
        }
        .navigationTitle("게시글 작성")
        .navigationBarTitleDisplayMode(.inline)
        
        // \ 추가: 뷰 진입 시 상태 초기화 및 디버깅 로그
        .onAppear {
            print("ContentAddView 나타남")
            print("   - userManager.isLoggedIn: \(userManager.isLoggedIn)")
            print("   - userManager.currentUserID: '\(userManager.currentUserID)'")
            
            // 상태 초기화
            uploading = false
            content = ""
            alertMessage = ""
            showAlert = false
        }
        
        // 사진 선택 변경 시 이미지 로딩 처리 (주석 처리된 부분 - 필요시 활성화)
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
        print(" writePost 시작")
        
        // 내용 입력 확인 (if문 사용)
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print(" 빈 내용으로 인한 실패")
            await MainActor.run {
                uploading = false  // 실패 시 상태 복원
                alertMessage = "게시글 내용을 입력해주세요."
                showAlert = true
            }
            return
        }
        
        // 로그인 상태 재확인
        if !userManager.isLoggedIn || userManager.currentUserID.isEmpty {
            print(" 로그인 상태 문제")
            await MainActor.run {
                uploading = false
                alertMessage = "로그인이 필요합니다."
                showAlert = true
            }
            return
        }
        
        guard let url = URL(string: "\(baseURL)/community/insert") else {
            print(" URL 생성 실패")
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
            
            print("서버 요청 시작...")
            let (_, response) = try await URLSession.shared.data(for: req)
            
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            print(" 서버 응답 성공")
            
            await MainActor.run {
                posts.insert(newPost, at: 0)  // 상위 뷰 게시글 목록에 추가 (Community에 즉시 반영)
                print(" 게시글 작성 성공: 작성자=\(userManager.currentUserID), 시간=\(currentTime)")
                dismiss()                   // 성공 시 현재 뷰 닫기 (uploading = false 불필요)
            }
            
        } catch {
            print(" 네트워크 에러: \(error.localizedDescription)")
            await MainActor.run {
                uploading = false  // 실패 시에만 상태 복원
                alertMessage = "게시글 작성에 실패했습니다."
                showAlert = true
                print(" 게시글 작성 실패: \(error.localizedDescription)")
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
