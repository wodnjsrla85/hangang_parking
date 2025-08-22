//
//  ContentUpdateView.swift
//  hangang
//

import SwiftUI
// import PhotosUI  // 사진 기능 주석처리로 불필요

struct ContentUpdateView: View {
    @Binding var content: ContentJSON                // 편집 중인 게시글 데이터 바인딩
    
    @State var editText: String = ""          // 수정할 텍스트 내용
    @FocusState var isFocused: Bool          // 텍스트 에디터 포커스 상태
    
    // 사진 관련 변수들 주석처리
    // @State var image: UIImage?                // 선택된 이미지
    // @State var photoItem: PhotosPickerItem?   // 사진 선택 아이템
    
    @State var showUpdate = false             // 수정 완료 알림 표시 여부
    @State var updating = false               // 수정 중 상태
    @State var showAlert = false              // 에러 알림
    @State var alertMessage = ""              // 에러 메시지
    
    @Environment(\.dismiss) private var dismiss
    
    // 수정 버튼 활성화 조건
    var updateButtonEnabled: Bool {
        !updating &&
        !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editText != content.content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 내용 입력 섹션
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("내용").font(.title).bold()
                        Spacer()
                    }
                    
                    //TextEditor 바인딩을 editText로 변경
                    TextEditor(text: $editText)  // $content 대신 $editText 사용
                        .frame(minHeight: 200, maxHeight: 400)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.3))
                                )
                        )
                        .focused($isFocused)
                }
                
                // 사진 첨부 섹션 - 전체 주석처리
                /*
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("사진").font(.title).bold()
                        Spacer()
                    }
                    
                    HStack {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text("+")
                                .frame(width: 70, height: 100)
                                .font(.system(size: 50))
                                .background(.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Spacer()
                    }
                }
                */
                
                // 수정 버튼
                Button(updating ? "수정 중..." : "수정") {
                    if !updating {
                        updating = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        Task { await updatePost() }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(updateButtonEnabled ? .blue : .gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .font(.title3).bold()
                .disabled(!updateButtonEnabled)
                
                // 작성일 표시
                HStack {
                    Text("작성일: \(getTime(content.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(20)
        }
        .navigationTitle("게시글 수정")
        .navigationBarTitleDisplayMode(.inline)
        
        // 뷰 진입 시 초기화
        .onAppear {
            editText = content.content  // 현재 게시글 내용으로 초기화
            updating = false           // 상태 초기화
            showAlert = false
            alertMessage = ""
        }
        
        // 알림창들
        .alert("수정되었습니다", isPresented: $showUpdate) {
            Button("확인") { dismiss() }
        }
        .alert("오류", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // 게시글 수정 함수
    func updatePost() async {
        let trimmedText = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 유효성 검사
        guard !trimmedText.isEmpty else {
            await MainActor.run {
                updating = false
                alertMessage = "내용을 입력해주세요."
                showAlert = true
            }
            return
        }
        
        guard trimmedText != content.content else {
            await MainActor.run {
                updating = false
                alertMessage = "변경된 내용이 없습니다."
                showAlert = true
            }
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/community/update/\(content.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 수정된 내용과 업데이트 시간을 포함
            let updateData: [String: Any] = [
                "content": trimmedText,
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            
            let (_, response) = try await URLSession.shared.data(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            await MainActor.run {
                // 로컬 데이터도 업데이트
                content.content = trimmedText
                content.updatedAt = ISO8601DateFormatter().string(from: Date())
                showUpdate = true
                print("✅ 게시글 수정 성공: \(content.id)")
            }
            
        } catch {
            await MainActor.run {
                updating = false
                alertMessage = "게시글 수정에 실패했습니다.\n\(error.localizedDescription)"
                showAlert = true
                print("❌ 게시글 수정 실패:", error.localizedDescription)
            }
        }
    }
    
    // 작성시간 변환 함수
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

#Preview {
    NavigationStack {
        ContentUpdateView(content: .constant(
            ContentJSON(
                id: "1",
                userId: "user123",
                content: "테스트 내용입니다. 이 내용을 수정할 수 있습니다.",
                createdAt: "2025-08-20T12:00:00.000Z",
                updatedAt: "2025-08-20T12:00:00.000Z",
                deleted: false,
                deletedAt: nil
            )
        ))
    }
}
