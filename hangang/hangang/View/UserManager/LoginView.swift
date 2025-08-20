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
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 상단 여백
                    Spacer()
                        .frame(height: 30)
                    
                    // 로고
                    VStack(spacing: 8) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("한강 앱")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 30)
                    
                    // 모드 선택
                    Picker("모드", selection: $isLoginMode) {
                        Text("로그인").tag(true)
                        Text("회원가입").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 30)
                    
                    // 입력 폼
                    VStack(spacing: 15) {
                        
                        // 회원가입 시에만 전화번호 입력
                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("전화번호")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("전화번호를 입력하세요", text: $phone)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        
                        // 아이디 입력
                        VStack(alignment: .leading, spacing: 5) {
                            Text("아이디")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("아이디를 입력하세요", text: $userID)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        // 비밀번호 입력
                        VStack(alignment: .leading, spacing: 5) {
                            Text("비밀번호")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("비밀번호를 입력하세요", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // 회원가입 시에만 비밀번호 확인
                        if !isLoginMode {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("비밀번호 확인")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // 주 버튼
                    Button(action: {
                        if isLoginMode {
                            handleLogin()
                        } else {
                            handleSignUp()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isLoginMode ? "로그인" : "회원가입")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .disabled(!isFormValid || isLoading)
                    
                    // 임시 로그인 버튼 (개발용)
                    Button("임시 로그인 (개발용)") {
                        Task {
                            await userManager.tempLogin()
                            onLoginSuccess()
                            dismiss()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("알림", isPresented: $showAlert) {
                Button("확인") {
                    if alertMessage.contains("회원가입이 완료되었습니다") {
                        isLoginMode = true
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
            return !userID.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
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
    
    private func handleSignUp() {
        guard password == confirmPassword else {
            alertMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            let result = await userManager.signUp(userID: userID, password: password, phone: phone)
            
            DispatchQueue.main.async {
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

// MARK: - Custom Text Field Style
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
    .environmentObject(UserManager())
}
