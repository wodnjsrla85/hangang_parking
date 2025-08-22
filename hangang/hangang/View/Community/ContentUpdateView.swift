//
//  ContentUpdateView.swift
//  hangang
//

import SwiftUI
// import PhotosUI // ❌ 사진 관련 import 주석처리

struct ContentUpdateView: View {
    @Binding var content: ContentJSON                // 편집 중인 게시글 데이터 바인딩
    
    @State var editText: String = ""          // 수정할 텍스트 내용
    @FocusState var textFocused: Bool          // 텍스트 에디터 포커스 상태
    
    // @State var image: UIImage?              // ❌ 선택된 이미지 주석처리
    // @State var photoItem: PhotosPickerItem? // ❌ 사진 선택 아이템 주석처리
    
    @State var showUpdate = false               // 수정 완료 알림 표시 여부
    @State var updating = false                 // 수정 중 상태
    @Environment(\.dismiss) private var dismiss          // 뷰 닫기 처리
    
    // 수정 버튼 활성화 조건
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
        // ✅ 추가: Sheet 닫힐 때 변경사항 저장
        .onDisappear {
            saveChangesOnDismiss()
        }
        .alert("수정 완료", isPresented: $showUpdate) {
            Button("확인") { dismiss() }
        } message: {
            Text("게시글이 성공적으로 수정되었습니다.")
        }
        // ✅ 수정: onChange 개선
        .onChange(of: textFocused) { _, focused in
            if !focused {
                saveTemporaryChanges()
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
        ScrollView {
            VStack(spacing: 24) {
                headerCardView
                contentEditSection
                // photoSection // ❌ 사진 섹션 호출 주석처리
                postInfoSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .overlay(alignment: .bottom) {
            updateButtonView
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
            Text("게시글 수정")
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
                            colors: [.green.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("게시글 수정")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("내용을 자유롭게 수정해보세요")
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
    
    private var contentEditSection: some View {
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
                
                Text("내용 수정")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 변경 상태 표시
                if editText != content.content && !editText.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                        Text("수정됨")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                
                // 글자수 카운터
                Text("\(editText.count)/1000")
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
                            .stroke(textFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
                    .animation(.easeInOut(duration: 0.2), value: textFocused)
                
                TextEditor(text: $editText)
                    .font(.body)
                    .padding(16)
                    .background(Color.clear)
                    .focused($textFocused)
                    .scrollContentBackground(.hidden)
                
                if editText.isEmpty && !textFocused {
                    Text("게시글 내용을 입력해주세요...")
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
        // ... 사진 섹션 코드 주석처리 ...
    }
    */
    
    private var postInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text("게시글 정보")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // 정보 카드
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar",
                    title: "작성일",
                    content: getTime(content.createdAt),
                    color: .blue
                )
                
                if content.updatedAt != content.createdAt {
                    InfoRow(
                        icon: "pencil",
                        title: "수정일",
                        content: getTime(content.updatedAt),
                        color: .green
                    )
                }
                
                InfoRow(
                    icon: "person.circle",
                    title: "작성자",
                    content: String(content.userId.suffix(20)),
                    color: .purple
                )
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
    }
    
    private var updateButtonView: some View {
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
                if updating {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("게시글을 수정하는 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                }
                
                // 수정 버튼
                Button(action: handleUpdate) {
                    HStack(spacing: 12) {
                        if updating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(updating ? "수정 중..." : "수정 완료")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                updateButtonEnabled ?
                                LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .shadow(
                        color: updateButtonEnabled ? .green.opacity(0.3) : .clear,
                        radius: 8, x: 0, y: 4
                    )
                    .scaleEffect(updateButtonEnabled ? 1.0 : 0.95)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: updateButtonEnabled)
                }
                .disabled(!updateButtonEnabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        editText = content.content  // 현재 게시글 내용 초기화
        updating = false
    }
    
    // ✅ 추가: 임시 변경사항 저장 함수
    private func saveTemporaryChanges() {
        if !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            content.content = editText
        }
    }

    // ✅ 추가: Sheet 닫힐 때 변경사항 저장
    private func saveChangesOnDismiss() {
        if !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           editText != content.content {
            content.content = editText
            print("💾 Sheet 닫힘: 변경사항 저장됨")
        }
    }
    
    private func handleUpdate() {
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
    
    // ✅ 수정: 게시글 수정 서버 요청 - 상태 관리 개선
    func updatePost() async {
        // 내용 변경 확인 (if문 사용)
        if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            await MainActor.run {
                updating = false  // 실패 시 상태 복원
            }
            return
        }
        
        if editText == content.content {
            await MainActor.run {
                updating = false  // 변경사항 없음
            }
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/community/update/\(content.id)")!
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["content": editText])
            
            let (_, response) = try await URLSession.shared.data(for: req)
            if let r = response as? HTTPURLResponse, 200...299 ~= r.statusCode {
                await MainActor.run {
                    // ✅ 서버 성공 후에 바인딩 업데이트
                    content.content = editText
                    content.updatedAt = ISO8601DateFormatter().string(from: Date()) // 수정 시간 업데이트
                    showUpdate = true
                    print("✅ 게시글 수정 성공: \(content.id)")
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            await MainActor.run {
                updating = false  // 실패 시에만 상태 복원
                print("❌ 게시글 수정 실패:", error.localizedDescription)
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

// MARK: - 정보 행 컴포넌트
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(content)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView(content: {
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
        .environmentObject(UserManager.shared)
    })
}
