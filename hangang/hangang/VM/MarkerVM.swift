//
//  MarkerVM.swift
//  hangang
//
//  Created by 김재원 on 8/20/25.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "http://127.0.0.1:8000"
    
    private init() {}
    
    // 모든 마커 데이터 가져오기
    func fetchMarkers() async throws -> [Marker] {
        guard let url = URL(string: "\(baseURL)/marker/select") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("HTTP 상태 코드: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw APIError.networkError
        }
        
        // 디버깅: 응답 데이터 확인
        if String(data: data, encoding: .utf8) != nil {
            print("📡 서버 응답 데이터:")
        }
        
        do {
            let markers = try JSONDecoder().decode([Marker].self, from: data)
            print("✅ 성공적으로 \(markers.count)개의 마커를 디코딩했습니다.")
            return markers
        } catch {
            print("❌ 디코딩 에러: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("키를 찾을 수 없음: \(key.stringValue), 경로: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("타입 불일치: \(type), 경로: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("값을 찾을 수 없음: \(type), 경로: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("데이터 손상: \(context)")
                @unknown default:
                    print("알 수 없는 디코딩 에러")
                }
            }
            throw APIError.decodingError
        }
    }
}

// API 에러 정의
enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        case .decodingError:
            return "데이터 형식이 올바르지 않습니다."
        }
    }
}

// MARK: - SwiftUI에서 사용할 ViewModel
@MainActor
class MarkerViewModel: ObservableObject {
    @Published var markers: [Marker] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // 데이터 로드
    func loadMarkers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            markers = try await apiService.fetchMarkers()
            print("🎯 ViewModel: \(markers.count)개의 마커가 로드되었습니다.")
        } catch {
            errorMessage = error.localizedDescription
            print("💥 ViewModel 에러: \(error)")
        }
        
        isLoading = false
    }
}
