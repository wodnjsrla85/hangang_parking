//
//  Inquiry.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import Foundation

// MARK: - Inquiry 모델 (서버 JSON과 완전 호환)
struct Inquiry: Codable, Identifiable {
    let id: String?          // MongoDB의 _id
    let userID: String?      // Optional로 변경 (빈 값 허용)
    let adminID: String?
    let qdate: String?       // qdate (소문자 'd')
    let adate: String?       // adate (소문자 'd')
    let title: String?       // Optional로 변경 (빈 값 허용)
    let content: String?     // Optional로 변경 (빈 값 허용)
    let answerContent: String?
    let state: String?       // Optional로 변경 (빈 값 허용)
    
    // JSON 키와 Swift 프로퍼티 매핑
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userID
        case adminID
        case qdate  // 서버에서 qdate로 오는 경우
        case adate  // 서버에서 adate로 오는 경우
        case title
        case content
        case answerContent
        case state
    }
    
    // 추가 CodingKeys for 대소문자 혼용 케이스
    enum AlternateCodingKeys: String, CodingKey {
        case qDate  // 서버에서 qDate로 오는 경우
        case aDate  // 서버에서 aDate로 오는 경우
    }
    
    // 커스텀 디코딩 (대소문자 혼용 처리)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 기본 필드들
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        adminID = try container.decodeIfPresent(String.self, forKey: .adminID)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        answerContent = try container.decodeIfPresent(String.self, forKey: .answerContent)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        
        // qdate/qDate 처리
        if let qdateValue = try container.decodeIfPresent(String.self, forKey: .qdate) {
            qdate = qdateValue
        } else {
            // qDate로 시도
            let altContainer = try decoder.container(keyedBy: AlternateCodingKeys.self)
            qdate = try altContainer.decodeIfPresent(String.self, forKey: .qDate)
        }
        
        // adate/aDate 처리
        if let adateValue = try container.decodeIfPresent(String.self, forKey: .adate) {
            adate = adateValue
        } else {
            // aDate로 시도
            let altContainer = try decoder.container(keyedBy: AlternateCodingKeys.self)
            adate = try altContainer.decodeIfPresent(String.self, forKey: .aDate)
        }
    }
    
    // Computed properties for date conversion
    var createdAt: Date? {
        guard let qdate = qdate, !qdate.isEmpty else { return nil }
        return DateFormatter.flexibleDateFormatter.date(from: qdate)
    }
    
    var answeredAt: Date? {
        guard let adate = adate, !adate.isEmpty else { return nil }
        return DateFormatter.flexibleDateFormatter.date(from: adate)
    }
    
    // 상태 체크 헬퍼 (빈 값 처리)
    var isPending: Bool {
        let normalized = state?.lowercased() ?? ""
        return normalized == "pending" || normalized == "0" || normalized.isEmpty || normalized == "답변대기"
    }
    
    var isAnswered: Bool {
        let normalized = state?.lowercased() ?? ""
        return normalized == "answered" || normalized == "1" || normalized == "true" || normalized == "답변완료"
    }
    
    // 표시용 안전한 값들
    var safeTitle: String {
        return title?.isEmpty == false ? title! : "제목 없음"
    }
    
    var safeContent: String {
        return content?.isEmpty == false ? content! : "내용 없음"
    }
    
    var safeUserID: String {
        return userID?.isEmpty == false ? userID! : "사용자 미확인"
    }
    
    var displayState: String {
        if isAnswered {
            return "답변완료"
        } else {
            return "답변대기"
        }
    }
}

// MARK: - 문의 생성용 모델
struct InquiryCreate: Codable {
    let userID: String
    let qdate: String
    let title: String
    let content: String
    let state: String
    
    init(userID: String, title: String, content: String) {
        self.userID = userID
        self.title = title
        self.content = content
        self.qdate = DateFormatter.serverDateFormatter.string(from: Date())
        self.state = "pending"
    }
}

// MARK: - 답변 업데이트용 모델
struct InquiryUpdate: Codable {
    let adminID: String?
    let adate: String?
    let answerContent: String?
    let state: String?
    
    init(adminID: String, answerContent: String) {
        self.adminID = adminID
        self.answerContent = answerContent
        self.adate = DateFormatter.serverDateFormatter.string(from: Date())
        self.state = "answered"
    }
}

// MARK: - APIConfig
class APIConfig {
    static let shared = APIConfig()
    
    // 시뮬레이터용 설정
    var baseURL: URL {
        return URL(string: "http://127.0.0.1:8000")!
    }
    
    // API 엔드포인트들
    struct Endpoints {
        static let select = "/select"
        static let selectByUser = "/select"
        static let insert = "/insert"
        static let update = "/update"
    }
    
    private init() {}
    
    // URL 생성 헬퍼 메서드들
    func selectAllURL() -> URL {
        return baseURL.appendingPathComponent(Endpoints.select)
    }
    
    func selectUserURL(userID: String) -> URL {
        return baseURL.appendingPathComponent("\(Endpoints.selectByUser)/\(userID)")
    }
    
    func insertURL() -> URL {
        return baseURL.appendingPathComponent(Endpoints.insert)
    }
    
    func updateURL(userID: String) -> URL {
        return baseURL.appendingPathComponent("\(Endpoints.update)/\(userID)")
    }
}

// MARK: - 날짜 포매터 (유연한 형식 지원)
extension DateFormatter {
    // 서버에서 받는 다양한 날짜 형식 처리
    static let flexibleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // 서버로 보낼 때 사용하는 형식
    static let serverDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // ISO 형식
    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    // 화면 표시용 포매터
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

// 날짜 문자열을 유연하게 파싱하는 확장
extension DateFormatter {
    static func parseFlexibleDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - 네트워크 응답 모델들
struct InquiryListResponse: Codable {
    let results: [Inquiry]
}

struct InquiryDetailResponse: Codable {
    let result: Inquiry
}

struct APISuccessResponse: Codable {
    let result: String
}

// MARK: - 에러 타입
enum InquiryError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .noData:
            return "데이터가 없습니다"
        case .decodingError:
            return "데이터 형식이 올바르지 않습니다"
        case .serverError(let message):
            return "서버 오류: \(message)"
        case .networkError:
            return "네트워크 연결을 확인해주세요"
        }
    }
}

// MARK: - UserDefaults 확장 (사용자 ID 관리)
extension UserDefaults {
    private enum Keys {
        static let userID = "currentUserID"
    }
    
    var currentUserID: String? {
        get { string(forKey: Keys.userID) }
        set { set(newValue, forKey: Keys.userID) }
    }
}
