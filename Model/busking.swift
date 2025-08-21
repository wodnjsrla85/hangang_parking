//
//  busking.swift
//  hangang
//
//  Created by 김지호 on 8/19/25.
//

import Foundation

// MARK: - Busking 모델 (서버 JSON과 1:1)
struct Busking: Codable, Identifiable, Equatable {
    let _id: String?
    let userid: String
    let name: String
    let date: String
    let category: String
    let content: String
    let bandName: String
    let state: Int
    // let image: String? // Base64 사용 시 활성화

    // SwiftUI List 추적용 고유 ID
    var id: String { _id ?? userid }
}

// MARK: - 서버 응답 DTO
struct BuskingListResponse: Codable {
    let results: [Busking]
}

// MARK: - 부분 수정 DTO
struct BuskingUpdateDTO: Codable {
    var name: String?
    var date: String?
    var category: String?
    var content: String?
    var bandName: String?
    var state: Int?
}

extension BuskingUpdateDTO {
    var isEmpty: Bool {
        name == nil && date == nil && category == nil &&
        content == nil && bandName == nil && state == nil
    }
}
