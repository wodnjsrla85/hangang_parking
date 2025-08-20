//
//  OneOnOneInquiry.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct OneOnOneInquiry: View {
    
    @EnvironmentObject var userManager: UserManager // UserManager추가
    @StateObject var viewModel = InquiryViewModel() // vm
    
    @State var title: String = ""
    @State var content: String = ""
    @FocusState var isTextFieldFocused: Bool
    
    // 추가된 상태 변수들
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // 로그인 상태 표시 (디버깅용)
            HStack {
                Text("로그인 상태:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(userManager.isLoggedIn ? "\(userManager.currentUserID)님" : "로그인 필요")
                    .font(.caption)
                    .foregroundColor(userManager.isLoggedIn ? .green : .red)
                Spacer()
            }
            .padding(.bottom, 10)
            
            Text("문의 제목 *")
                .padding(.top, 50)
                
            TextField("문의 제목을 입력해주세요", text: $title)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 2))
                .focused($isTextFieldFocused)
                .padding(.bottom, 30)
            
            Text("문의 내용 *")
            
            ZStack {
                if content.isEmpty {
                    Text("문의 내용을 입력해주세요")
                        .foregroundColor(.gray)
                }
                
                TextEditor(text: $content)
                    .frame(minHeight: 100, maxHeight: 150) // 원하는 높이
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
            }
            
            Spacer()
            
            // 작성완료 버튼 (addInquiry 연결)
            Button(action: {
                submitInquiry()  // addInquiry 호출하는 함수
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isSubmitting ? "등록 중..." : "작성완료")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!canSubmit || isSubmitting)
            .padding(.bottom, 60)
        }
        .navigationTitle("1 : 1 문의")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .alert("문의 등록 완료", isPresented: $showSuccessAlert) {
            Button("확인") {
                // 성공 후 필드 초기화
                title = ""
                content = ""
                isTextFieldFocused = false
            }
        } message: {
            Text(viewModel.successMessage ?? "문의가 성공적으로 등록되었습니다!")
        }
        .alert("문의 등록 실패", isPresented: $showErrorAlert) {
            Button("확인") { }
        } message: {
            Text(viewModel.errorMessage ?? "문의 등록에 실패했습니다. 다시 시도해주세요.")
        }
    } // body
    
    // MARK: - 계산된 속성
    
    /// 제출 가능 여부 확인
    private var canSubmit: Bool {
        return userManager.isLoggedIn &&
               !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - 메서드
    
    /// 문의 제출 (addInquiry 사용!)
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
        isTextFieldFocused = false  // 키보드 숨기기
        
        Task {
            print("📝 addInquiry 호출: userID=\(userManager.currentUserID), title=\(title)")
            
            // 🎯 여기서 addInquiry 사용!
            let success = await viewModel.addInquiry(
                userID: userManager.currentUserID,  // 로그인된 사용자 ID
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // 메인 스레드에서 UI 업데이트
            await MainActor.run {
                isSubmitting = false
                
                if success {
                    print("✅ 문의 등록 성공!")
                    showSuccessAlert = true
                } else {
                    print("❌ 문의 등록 실패!")
                    showErrorAlert = true
                }
            }
        }
    }
} // view

#Preview {
    NavigationView {
        OneOnOneInquiry()
    }
    .environmentObject(UserManager())
}
