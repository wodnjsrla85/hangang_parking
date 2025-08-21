//
//  OneOnOneInquiry.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct OneOnOneInquiry: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject var viewModel = InquiryViewModel()
    
    @State var title: String = ""
    @State var content: String = ""
    @FocusState var isTextFieldFocused: Bool
    @FocusState var isTextEditorFocused: Bool
    
    // 추가된 상태 변수들
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더 카드
                    InquiryHeaderView()
                    
                    // 사용자 정보 카드
                    UserInfoCard(userManager: userManager)
                    
                    // 입력 폼
                    VStack(spacing: 20) {
                        // 제목 입력
                        ModernInputField(
                            title: "문의 제목",
                            placeholder: "문의 제목을 입력해주세요",
                            text: $title,
                            isRequired: true,
                            isFocused: $isTextFieldFocused
                        )
                        
                        // 내용 입력
                        ModernTextEditor(
                            title: "문의 내용",
                            placeholder: "문의 내용을 상세히 입력해주세요",
                            text: $content,
                            isRequired: true,
                            isFocused: $isTextEditorFocused
                        )
                    }
                    
                    // 제출 버튼
                    ModernSubmitButton(
                        isSubmitting: isSubmitting,
                        canSubmit: canSubmit,
                        action: submitInquiry
                    )
                    
                    Spacer(minLength: 100) // 탭바 + 키보드 공간 확보
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: keyboardHeight)
            }
        }
        .navigationTitle("1:1 문의")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.cgRectValue.height - 100
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
        .alert("문의 등록 완료", isPresented: $showSuccessAlert) {
            Button("확인") {
                // 성공 후 필드 초기화
                title = ""
                content = ""
                isTextFieldFocused = false
                isTextEditorFocused = false
            }
        } message: {
            Text(viewModel.successMessage ?? "문의가 성공적으로 등록되었습니다!")
        }
        .alert("문의 등록 실패", isPresented: $showErrorAlert) {
            Button("확인") { }
        } message: {
            Text(viewModel.errorMessage ?? "문의 등록에 실패했습니다. 다시 시도해주세요.")
        }
    }
    
    // MARK: - 계산된 속성
    
    /// 제출 가능 여부 확인
    private var canSubmit: Bool {
        return userManager.isLoggedIn &&
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - 메서드
    
    /// 문의 제출
    private func submitInquiry() {
        print("🚀 문의 제출 시작")
        
        // 로그인 확인
        guard userManager.isLoggedIn else {
            print("❌ 로그인되지 않음")
            viewModel.errorMessage = "로그인이 필요합니다"
            showErrorAlert = true
            return
        }
        
        // 입력 확인
        guard canSubmit else {
            print("❌ 입력값 부족")
            viewModel.errorMessage = "제목과 내용을 모두 입력해주세요"
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        isTextFieldFocused = false
        isTextEditorFocused = false
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            print("📝 addInquiry 호출: userID=\(userManager.currentUserID), title=\(title)")
            
            let success = await viewModel.addInquiry(
                userID: userManager.currentUserID,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // 메인 스레드에서 UI 업데이트
            await MainActor.run {
                isSubmitting = false
                
                if success {
                    print("✅ 문의 등록 성공!")
                    showSuccessAlert = true
                    
                    // 성공 햅틱
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                } else {
                    print("❌ 문의 등록 실패!")
                    showErrorAlert = true
                    
                    // 실패 햅틱
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - 문의 헤더 뷰
struct InquiryHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .cyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                    .font(.title)
            }
            
            // 텍스트
            VStack(spacing: 8) {
                Text("1:1 문의 작성")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("궁금한 사항이나 문의사항을 작성해주세요.\n빠른 시일 내에 답변드리겠습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - 사용자 정보 카드
struct UserInfoCard: View {
    let userManager: UserManager
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(userManager.isLoggedIn ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: userManager.isLoggedIn ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundColor(userManager.isLoggedIn ? .green : .red)
                    .font(.title3)
            }
            
            // 사용자 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("문의자 정보")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(userManager.isLoggedIn ? "\(userManager.currentUserID ?? "")님" : "로그인이 필요합니다")
                    .font(.caption)
                    .foregroundColor(userManager.isLoggedIn ? .green : .red)
            }
            
            Spacer()
            
            // 상태 배지
            Text(userManager.isLoggedIn ? "로그인됨" : "로그인 필요")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(userManager.isLoggedIn ? .green : .red)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            userManager.isLoggedIn ?
                            Color.green.opacity(0.3) :
                            Color.red.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 모던 입력 필드
struct ModernInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 라벨
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // 글자 수 표시
                Text("\(text.count)/100")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 입력 필드
            TextField(placeholder, text: $text)
                .focused(isFocused)
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isFocused.wrappedValue ? Color.blue : Color.gray.opacity(0.3),
                                    lineWidth: isFocused.wrappedValue ? 2 : 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
        }
    }
}

// MARK: - 모던 텍스트 에디터
struct ModernTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isRequired: Bool
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 라벨
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // 글자 수 표시
                Text("\(text.count)/500")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 텍스트 에디터
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFocused.wrappedValue ? Color.blue : Color.gray.opacity(0.3),
                                lineWidth: isFocused.wrappedValue ? 2 : 1
                            )
                    )
                    .frame(minHeight: 120)
                
                if text.isEmpty && !isFocused.wrappedValue {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(20)
                }
                
                TextEditor(text: $text)
                    .focused(isFocused)
                    .font(.body)
                    .padding(16)
                    .background(Color.clear)
                    .frame(minHeight: 120)
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
        }
    }
}

// MARK: - 모던 제출 버튼
struct ModernSubmitButton: View {
    let isSubmitting: Bool
    let canSubmit: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                }
                
                Text(isSubmitting ? "등록 중..." : "문의 등록")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        canSubmit ?
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: canSubmit ? .blue.opacity(0.3) : .clear,
                        radius: canSubmit ? 15 : 0,
                        x: 0,
                        y: canSubmit ? 8 : 0
                    )
            )
        }
        .disabled(!canSubmit || isSubmitting)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: canSubmit)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if canSubmit && !isSubmitting {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    NavigationView {
        OneOnOneInquiry()
    }
    .environmentObject(UserManager.shared)
}
