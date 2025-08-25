//
//  LoginView.swift
//  hangang
//
//  Created by 정서윤 on 8/20/25.
//

import SwiftUI

struct LoginView: View {
    // UserManager 사용
    var onLoginSuccess: () -> Void = { }
    
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    
    // 상태 변수들
    @State private var isLoginMode = true  // true: 로그인, false: 회원가입
    @State private var userID = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.cyan.opacity(0.05),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // 상단 여백
                        Spacer()
                            .frame(height: 20)
                        
                        // 로고 섹션
                        VStack(spacing: 20) {
                            // 로고 아이콘
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "water.waves")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 8) {
                                Text("한강 앱")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("한강공원의 모든 것을 만나보세요")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 모드 선택
                        Picker("모드", selection: $isLoginMode) {
                            Text("로그인").tag(true)
                            Text("회원가입").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                        
                        // 입력 폼
                        VStack(spacing: 20) {
                            
                            // 회원가입 시에만 전화번호 입력
                            if !isLoginMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("전화번호")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                            .frame(width: 20)
                                        
                                        TextField("010-1234-5678", text: $phone)
                                            .font(.body)
                                            .keyboardType(.numberPad)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                            }
                            
                            // 아이디 입력
                            VStack(alignment: .leading, spacing: 8) {
                                Text("아이디")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                        .frame(width: 20)
                                    
                                    TextField("아이디를 입력하세요", text: $userID)
                                        .font(.body)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // 비밀번호 입력
                            VStack(alignment: .leading, spacing: 8) {
                                Text("비밀번호")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                        .frame(width: 20)
                                    
                                    SecureField("비밀번호를 입력하세요", text: $password)
                                        .font(.body)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // 회원가입 시에만 비밀번호 확인
                            if !isLoginMode {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("비밀번호 확인")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                            .frame(width: 20)
                                        
                                        SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                            .font(.body)
                                            .textContentType(.none)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLoginMode)
                        
                        // 주 버튼
                        Button(action: {
                            if isLoginMode {
                                handleLogin()
                            } else {
                                handleSignUp()
                            }
                        }) {
                            HStack(spacing: 12) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: isLoginMode ? "arrow.right.circle.fill" : "person.badge.plus.fill")
                                        .font(.title3)
                                }
                                
                                Text(isLoginMode ? "로그인" : "회원가입")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        isFormValid ?
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
                                        color: isFormValid ? .blue.opacity(0.3) : .clear,
                                        radius: isFormValid ? 15 : 0,
                                        x: 0,
                                        y: isFormValid ? 8 : 0
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                        .disabled(!isFormValid || isLoading)
                        .animation(.easeInOut(duration: 0.3), value: isFormValid)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("알림", isPresented: $showAlert) {
                Button("확인") {
                    if alertMessage.contains("회원가입이 완료되었습니다") {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isLoginMode = true
                        }
                        clearFields()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: isLoginMode) {
                clearFields()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !userID.isEmpty && !password.isEmpty
        } else {
            return !userID.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && !phone.isEmpty
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isFormValid && !isLoading {
            return .blue
        } else {
            return .gray
        }
    }
    
    // MARK: - Methods
    
    private func handleLogin() {
        isLoading = true
        
        Task {
            let result = await userManager.login(userID: userID, password: password)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.onLoginSuccess()
                    self.dismiss()
                case .failure(let message):
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            alertMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            let result = await userManager.signUp(userID: userID, password: password, phone: phone)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.alertMessage = "회원가입이 완료되었습니다!\n로그인해주세요."
                    self.showAlert = true
                case .failure(let message):
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    private func clearFields() {
        userID = ""
        password = ""
        confirmPassword = ""
        phone = ""
    }
}

// MARK: - Custom Text Field Style (기존 유지)
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView {
        print("로그인 성공!")
    }
    .environmentObject(UserManager.shared)
}
