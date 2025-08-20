//
//  InquiryModel.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import Foundation

// MARK: - API 함수들

// 전체 조회 (GET /select)
func apiFetchInquiries() async throws -> [Inquiry] {
    let url = APIConfig.shared.baseURL.appendingPathComponent("select")
    print("🌐 API 호출 URL: \(url)")
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 응답 상태 코드: \(httpResponse.statusCode)")
    }
    if let jsonString = String(data: data, encoding: .utf8) {
        print("📦 받은 JSON 데이터: \(jsonString)")
    }
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    struct Response: Codable { let results: [Inquiry] }
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    print("✅ 디코딩 성공 - 문의 개수: \(decoded.results.count)")
    return decoded.results
}

// 개별 조회 (GET /select/{userID})
func apiFetchInquiry(userID: String) async throws -> Inquiry {
    let url = APIConfig.shared.baseURL.appendingPathComponent("select/\(userID)")
    print("🌐 개별 문의 조회 URL: \(url)")
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 개별 조회 응답 상태: \(httpResponse.statusCode)")
    }
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    struct Response: Codable { let result: Inquiry }
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    return decoded.result
}

// 추가 (POST /insert)
func apiInsertInquiry(inquiry: InquiryCreate) async throws {
    let url = APIConfig.shared.baseURL.appendingPathComponent("insert")
    print("🌐 문의 추가 URL: \(url)")
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONEncoder().encode(inquiry)
    
    if let bodyData = req.httpBody,
       let bodyString = String(data: bodyData, encoding: .utf8) {
        print("📤 전송할 데이터: \(bodyString)")
    }

    let (_, response) = try await URLSession.shared.data(for: req)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 추가 응답 상태: \(httpResponse.statusCode)")
    }
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
}

// 수정 (PUT /update/{userID})
func apiUpdateInquiry(userID: String, answerContent: String, adminID: String) async throws {
    let url = APIConfig.shared.baseURL.appendingPathComponent("update/\(userID)")
    print("🌐 문의 수정 URL: \(url)")
    
    var req = URLRequest(url: url)
    req.httpMethod = "PUT"
    req.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = [
        "adminID": adminID,
        "answerContent": answerContent,
        "adate": DateFormatter.isoDateFormatter.string(from: Date()),
        "state": "answered"
    ]
    req.httpBody = try JSONEncoder().encode(body)

    let (_, response) = try await URLSession.shared.data(for: req)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("📊 수정 응답 상태: \(httpResponse.statusCode)")
    }
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
}

// 특정 사용자의 모든 문의 조회 (GET /select/user/{userID})
func apiFetchUserInquiries(userID: String) async throws -> [Inquiry] {
    let url = APIConfig.shared.baseURL.appendingPathComponent("select/user/\(userID)")
    print("🌐 사용자 문의 조회 URL: \(url)")
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    struct Response: Codable { let results: [Inquiry] }
    let decoded = try JSONDecoder().decode(Response.self, from: data)
    return decoded.results
}

// MARK: - InquiryViewModel
@MainActor
class InquiryViewModel: ObservableObject {
    @Published var inquiries: [Inquiry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // 전체 조회
    func fetchInquiries() async {
        print("🚀 전체 문의 불러오기 시작")
        isLoading = true
        errorMessage = nil
        do {
            inquiries = try await apiFetchInquiries()
            print("✅ 전체 문의 로드 완료 - 개수: \(inquiries.count)")
        } catch {
            handleError(error, context: "전체 문의 불러오기 실패")
        }
        isLoading = false
    }
    
    // 특정 사용자 조회
    func fetchUserInquiries(userID: String) async {
        print("🚀 사용자 문의 불러오기 시작")
        isLoading = true
        errorMessage = nil
        do {
            inquiries = try await apiFetchUserInquiries(userID: userID)
            print("✅ 사용자 문의 로드 완료 - 개수: \(inquiries.count)")
        } catch {
            handleError(error, context: "사용자 문의 불러오기 실패")
        }
        isLoading = false
    }
    
    // 문의 추가
    func addInquiry(userID: String, title: String, content: String) async -> Bool {
        print("🚀 문의 추가 시작: \(title)")
        let newInquiry = InquiryCreate(userID: userID, title: title, content: content)
        do {
            try await apiInsertInquiry(inquiry: newInquiry)
            successMessage = "문의가 성공적으로 등록되었습니다"
            await fetchUserInquiries(userID: userID)
            return true
        } catch {
            handleError(error, context: "문의 등록 실패")
            return false
        }
    }
    
    // 답변 등록
    func answerInquiry(userID: String, answer: String, adminID: String) async -> Bool {
        print("🚀 답변 등록 시작")
        do {
            try await apiUpdateInquiry(userID: userID, answerContent: answer, adminID: adminID)
            successMessage = "답변이 성공적으로 등록되었습니다"
            await fetchUserInquiries(userID: userID)
            return true
        } catch {
            handleError(error, context: "답변 등록 실패")
            return false
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    private func handleError(_ error: Error, context: String) {
        print("❌ \(context): \(error)")
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: errorMessage = "인터넷 연결을 확인해주세요"
            case .timedOut: errorMessage = "서버 응답 시간이 초과되었습니다"
            case .cannotConnectToHost: errorMessage = "서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요"
            case .badServerResponse: errorMessage = "서버 응답 오류 (상태 코드 문제)"
            default: errorMessage = "네트워크 오류: \(urlError.localizedDescription)"
            }
        } else if error is DecodingError {
            errorMessage = "데이터 형식 오류 (JSON 파싱 실패)"
        } else {
            errorMessage = "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}

// MARK: - 네트워크 테스트 함수 (디버깅용)
@MainActor
class NetworkTester: ObservableObject {
    func testConnection() async {
        print("🧪 네트워크 연결 테스트 시작")
        let url = APIConfig.shared.baseURL.appendingPathComponent("select")
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 테스트 응답 상태: \(httpResponse.statusCode)")
                print("📋 응답 헤더: \(httpResponse.allHeaderFields)")
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 테스트 응답 데이터: \(jsonString)")
            }
            print("✅ 네트워크 연결 테스트 성공")
        } catch {
            print("❌ 네트워크 연결 테스트 실패: \(error)")
            print("❌ 상세 오류: \(error.localizedDescription)")
        }
    }
}
