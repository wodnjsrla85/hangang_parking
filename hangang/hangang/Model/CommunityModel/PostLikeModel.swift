//
//  PostLike.swift
//  hangang
//
//  Created by we on 8/20/25.
//

import Foundation

// 좋아요 데이터 구조 정의
struct PostLikeJSON: Codable, Hashable {
    let id: String              // 좋아요 고유 ID
    let postId: String          // 좋아요 대상 게시글 ID
    let userId: String          // 좋아요 누른 사용자 ID
    let createdAt: String       // 좋아요 누른 시간
    let updatedAt: String?      // 수정 시간 (옵셔널)

    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
