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
    
    @State private var content = ""                     // 작성 중인 게시글 텍스트
    @State private var image: UIImage?                   // 선택한 이미지
    @State private var photoItem: PhotosPickerItem?     // 사진 선택 아이템
    @FocusState private var isFocused: Bool              // 텍스트 에디터 포커스 상태
    @State private var uploading = false                  // 게시글 업로드 중 상태
    @State private var showAlert = false                   // 알림 표시 여부
    @State private var alertMessage = ""                   // 알림 메시지
    @Environment(\.dismiss) private var dismiss            // 현재 뷰 닫기 처리
    
    // 로그인 사용자 ID 가져오기
    private var userId: String {
        UserDefaults.standard.string(forKey: "USER_ID") ?? "default_user_id"
    }
    
    // 게시글 작성 버튼 활성화 조건
    private var buttonEnabled: Bool {
        !uploading && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
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
                
                // 작성 완료 버튼
                Button("작성 완료") {
                    Task { await writePost() }
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
    
    // 게시글 작성 서버 요청 및 로컬 목록 추가
    private func writePost() async {
        guard let url = URL(string: "\(baseURL)/community/insert") else { return }
        await MainActor.run { uploading = true }
        
        do {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let newPost = ContentJSON(
                id: UUID().uuidString,
                userId: userId,
                content: content,
                createdAt: "",
                updatedAt: "",
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
                dismiss()                   // 현재 뷰 닫기
            }
        } catch {
            await MainActor.run {
                alertMessage = "게시글 작성에 실패했습니다."
                showAlert = true
            }
        }
        await MainActor.run { uploading = false }
    }
}

#Preview {
    ContentAddView(posts: .constant([]))
}
