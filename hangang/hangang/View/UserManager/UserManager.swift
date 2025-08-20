//
//  UserManager.swift
//  hangang
//
//  Created by 정서윤 on 8/20/25.
//

import Foundation

class UserManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var currentUserID: String = ""
    @Published var currentUserPhone: String = ""
    
    // MARK: - Initialization
    init() {
        loadUserFromStorage()
    }
    
    // MARK: - Authentication Methods
    
    /// 회원가입 (서버 API 사용)
    func signUp(userID: String, password: String, phone: String? = nil) async -> SignUpResult {
        do {
            _ = try await signUpUser(id: userID, pw: password, phone: phone)
            print("✅ 서버 회원가입 성공: \(userID)")
            return .success
        } catch {
            let errorMessage = error.localizedDescription
            print("❌ 서버 회원가입 실패: \(errorMessage)")
            return .failure(errorMessage)
        }
    }
    
    /// 로그인 (서버 API 사용)
    func login(userID: String, password: String) async -> LoginResult {
        do {
            let response = try await loginUser(id: userID, pw: password)
            
            // 🔧 메인 스레드에서 UI 업데이트
            await MainActor.run {
                self.currentUserID = response.user.id
                self.currentUserPhone = response.user.phone ?? ""
                self.isLoggedIn = true
                
                // UserDefaults에 현재 로그인 정보 저장
                UserDefaults.standard.set(response.user.id, forKey: "currentUserID")
                UserDefaults.standard.set(response.user.phone ?? "", forKey: "currentUserPhone")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            }
            
            print("✅ 서버 로그인 성공: \(response.user.id)")
            return .success
            
        } catch {
            let errorMessage = error.localizedDescription
            print("❌ 서버 로그인 실패: \(errorMessage)")
            return .failure(errorMessage)
        }
    }
    
    /// 로그아웃
    func logout() {
        print("🚪 로그아웃: \(currentUserID)")
        
        // 🔧 메인 스레드에서 UI 업데이트
        Task { @MainActor in
            self.currentUserID = ""
            self.currentUserPhone = ""
            self.isLoggedIn = false
        }
        
        // UserDefaults에서 제거
        UserDefaults.standard.removeObject(forKey: "currentUserID")
        UserDefaults.standard.removeObject(forKey: "currentUserPhone")
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
    
    /// 임시 로그인 (개발용) - 기존 데이터 사용
    func tempLogin() async {
        // 기존 MongoDB의 "1" 계정으로 로그인 시도
        let result = await login(userID: "1", password: "1")
        
        switch result {
        case .success:
            print("✅ 임시 로그인 성공 (기존 데이터 사용)")
        case .failure(let message):
            print("❌ 임시 로그인 실패: \(message)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 저장된 로그인 정보 불러오기
    private func loadUserFromStorage() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.currentUserID = UserDefaults.standard.string(forKey: "currentUserID") ?? ""
        self.currentUserPhone = UserDefaults.standard.string(forKey: "currentUserPhone") ?? ""
        
        if isLoggedIn && !currentUserID.isEmpty {
            print("📱 저장된 로그인 정보 로드: \(currentUserID)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// 현재 사용자 정보 반환
    var userInfo: (id: String, phone: String)? {
        guard isLoggedIn else { return nil }
        return (id: currentUserID, phone: currentUserPhone)
    }
    
    /// 특정 사용자 이름 조회
    func getUserName(for userID: String) -> String {
        return UserDefaults.standard.string(forKey: "user_\(userID)_name") ?? "사용자"
    }
}

// MARK: - Result Types
enum LoginResult {
    case success
    case failure(String)
}

enum SignUpResult {
    case success
    case failure(String)
}

// MARK: - UserManager Extensions
extension UserManager {
    /// 로그인 상태 문자열
    var statusDescription: String {
        if isLoggedIn {
            return "\(currentUserID)님 로그인 중"
        } else {
            return "로그인이 필요합니다"
        }
    }
    
    /// 현재 사용자의 문의 필터링
    func filterUserInquiries(_ inquiries: [Inquiry]) -> [Inquiry] {
        guard isLoggedIn else { return [] }
        
        return inquiries.filter { inquiry in
            inquiry.userID == currentUserID
        }
    }
}
