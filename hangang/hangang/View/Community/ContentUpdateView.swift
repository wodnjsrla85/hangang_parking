//
//  ContentUpdateView.swift
//  hangang
//

import SwiftUI
import PhotosUI

struct ContentUpdateView: View {
    @Binding var content: ContentJSON                // 편집 중인 게시글 데이터 바인딩
    
    @State var editText: String = ""          // 수정할 텍스트 내용
    @FocusState var textFocused: Bool          // 텍스트 에디터 포커스 상태
    
    @State var image: UIImage?                  // 선택된 이미지 (현재 미사용)
    @State var photoItem: PhotosPickerItem?    // 사진 선택 아이템 (현재 미사용)
    
    @State var showUpdate = false               // 수정 완료 알림 표시 여부
    //  추가: 업데이트 상태 관리
    @State var updating = false                 // 수정 중 상태
    @Environment(\.dismiss) private var dismiss          // 뷰 닫기 처리
    
    // 추가: 수정 버튼 활성화 조건 (if문 사용)
    var updateButtonEnabled: Bool {
        if updating {
            return false
        } else if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        } else if editText == content.content {
            return false  // 내용이 변경되지 않은 경우
        } else {
            return true
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            // 내용 입력 헤더
            HStack {
                Text("내용").font(.title).bold().padding(.horizontal, 20)
                Spacer()
            }
            
            // 내용 수정 텍스트 에디터
            TextEditor(text: $editText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .colorMultiply(.blue.opacity(0.2))
                .clipShape(.rect(cornerRadius: 10))
                .focused($textFocused)
            
            // 사진 첨부 헤더
            HStack {
                Text("사진").font(.title).bold().padding(.horizontal, 20)
                Spacer()
            }
            
            // 사진 선택 및 미리보기 (현재 UI만, 이미지 로드는 주석 처리됨)
            HStack {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text("+")
                        .frame(width: 70, height: 100)
                        .font(.system(size: 50))
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(.buttonBorder)
                }
                .padding()
                
                if let img = image {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(.rect(cornerRadius: 10))
                        .padding()
                }
                Spacer()
            }
            
            //수정 버튼만 남기고 삭제 버튼 제거
            Button(updating ? "수정 중..." : "수정") {
                // 즉시 상태 업데이트로 중복 클릭 방지
                if !updating {  // 추가 안전장치
                    updating = true
                    
                    // 즉시 햅틱 피드백
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    Task {
                        await updatePost()
                    }
                }
            }
            .frame(width: 300, height: 50)  // 전체 너비로 확장
            .background(updateButtonEnabled ? .blue : .gray)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 30))
            .font(.title3).bold()
            .disabled(!updateButtonEnabled)
            .alert("수정되었습니다", isPresented: $showUpdate) {
                Button("네, 알겠습니다") { dismiss() }
            }
            
            // 작성일 표시
            HStack {
                Text("작성일: \(getTime(content.createdAt))")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                Spacer()
            }
            .padding(.top, 10)
        }
        .navigationTitle("게시글 수정")
        .navigationBarTitleDisplayMode(.inline)
        // 사진 선택 시 이미지 로드 주석 처리 (필요 시 활성화)
        /*
        .onChange(of: photoItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
        */
        .onAppear {
            editText = content.content  // 현재 게시글 내용 초기화
        }
        .onChange(of: textFocused) { _, focused in
            if !focused {
                content.content = editText // 포커스 해제 시 내용 업데이트
            }
        }
    }
    
    /*
    // 선택한 사진을 UIImage로 변환하여 image 상태에 저장 (필요 시 사용)
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self) {
            Task { @MainActor in
                image = UIImage(data)
            }
        }
    }
    */
    
    // 수정: 게시글 수정 서버 요청 - 상태 관리 개선
    func updatePost() async {
        // 내용 변경 확인 (if문 사용)
        if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await MainActor.run {
                updating = false  // 실패 시 상태 복원
                // 에러 처리 추가 가능
            }
            return
        }
        
        if editText == content.content {
            await MainActor.run {
                updating = false  // 변경사항 없음
                // 변경사항 없음 알림 추가 가능
            }
            return
        }
        
        content.content = editText
        
        do {
            let url = URL(string: "\(baseURL)/community/update/\(content.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["content": editText])
            
            let (_, response) = try await URLSession.shared.data(for: req)
            if let r = response as? HTTPURLResponse, 200...299 ~= r.statusCode {
                await MainActor.run {
                    showUpdate = true
                    print(" 게시글 수정 성공: \(content.id)")
                    // 성공 시 updating은 dismiss에서 자동으로 해제됨
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            await MainActor.run {
                updating = false  // 실패 시에만 상태 복원
                print(" 게시글 수정 실패:", error.localizedDescription)
                // 에러 알림 추가 가능
            }
        }
    }
    
    
    // 작성시간을 상대 기준 시간으로 변환해 표시
    func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "\(Int(seconds))초 전"
        } else if seconds < 3600 {
            return "\(Int(seconds/60))분 전"
        } else if seconds < 86400 {
            return "\(Int(seconds/3600))시간 전"
        } else if seconds < 604800 {
            return "\(Int(seconds/86400))일 전"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = .init(identifier: "ko_KR")
            dateFormatter.dateFormat = "MM월 dd일"
            return dateFormatter.string(from: date)
        }
    }
}

#Preview {
    ContentUpdateView(content: .constant(
        ContentJSON(
            id: "1",
            userId: "user123",
            content: "테스트 내용",
            createdAt: "2025-08-20T12:00:00",
            updatedAt: "2025-08-20T12:00:00",
            deleted: false,
            deletedAt: nil
        )
    ))
}
