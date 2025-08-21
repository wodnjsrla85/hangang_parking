//
//  ContentModel.swift
//  hangang
//
//  Created by we on 8/20/25.
//
import Foundation

// 게시글 데이터 구조 정의
struct ContentJSON: Codable, Hashable {
    let id: String              // 게시글 고유 ID
    let userId: String          // 작성자 ID
    var content: String         // 게시글 내용
    let createdAt: String       // 작성 시간
    var updatedAt: String       // 수정 시간

    var deleted: Bool           // 삭제 여부 (논리 삭제 방식)
    var deletedAt: String?      // 삭제 시간 (삭제되지 않으면 nil)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 서버 주소 설정
let baseURL = "http://127.0.0.1:8000"
