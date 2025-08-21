//
//  ContentUpdateView.swift
//  hangang
//


import SwiftUI
import PhotosUI

struct ContentUpdateView: View {
    @Binding var content: ContentJSON                // 편집 중인 게시글 데이터 바인딩
    
    @State private var editText: String = ""          // 수정할 텍스트 내용
    @FocusState private var textFocused: Bool          // 텍스트 에디터 포커스 상태
    
    @State private var image: UIImage?                  // 선택된 이미지 (현재 미사용)
    @State private var photoItem: PhotosPickerItem?    // 사진 선택 아이템 (현재 미사용)
    
    @State private var showUpdate = false               // 수정 완료 알림 표시 여부
    @State private var showDelete = false               // 삭제 완료 알림 표시 여부
    @Environment(\.dismiss) private var dismiss          // 뷰 닫기 처리
    
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
            
            // 수정 / 삭제 버튼
            HStack(spacing: 20) {
                Button("수정") {
                    Task { await updatePost() }
                }
                .frame(width: 140, height: 50)
                .background(.blue).foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 30))
                .alert("수정되었습니다", isPresented: $showUpdate) {
                    Button("네, 알겠습니다") { dismiss() }
                }
                
                Button("삭제") {
                    Task { await deletePost() }
                }
                .frame(width: 140, height: 50)
                .background(.red).foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 30))
                .alert("삭제되었습니다", isPresented: $showDelete) {
                    Button("네, 알겠습니다") { dismiss() }
                }
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
    
    // 게시글 수정 서버 요청
    private func updatePost() async {
        content.content = editText
        
        do {
            let url = URL(string: "\(baseURL)/community/update/\(content.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["content": editText])
            
            let (_, response) = try await URLSession.shared.data(for: req)
            if let r = response as? HTTPURLResponse, 200...299 ~= r.statusCode {
                await MainActor.run { showUpdate = true }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            print("수정 실패:", error.localizedDescription)
        }
    }
    
    // 게시글 삭제 서버 요청
    private func deletePost() async {
        do {
            let url = URL(string: "\(baseURL)/community/delete/\(content.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "DELETE"
            
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            
            await MainActor.run {
                content.deleted = true
                showDelete = true
            }
        } catch {
            print("삭제 실패:", error.localizedDescription)
        }
    }
    
    // 작성시간을 상대 기준 시간으로 변환해 표시
    private func getTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "날짜 없음" }
        let seconds = Date().timeIntervalSince(date)
        
        switch seconds {
        case ..<60:      return "\(Int(seconds))초 전"
        case ..<3600:    return "\(Int(seconds/60))분 전"
        case ..<86400:   return "\(Int(seconds/3600))시간 전"
        case ..<604800:  return "\(Int(seconds/86400))일 전"
        default:
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
