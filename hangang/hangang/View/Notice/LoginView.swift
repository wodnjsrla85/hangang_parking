//
//  LoginView.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct LoginView: View {
    // ✅ 로그인 성공 시 부모에 알려줄 콜백 (기본값: 아무것도 안 함)
        var onLoginSuccess: () -> Void = {}

        @Environment(\.dismiss) private var dismiss
    
    var body: some View {
                VStack(spacing: 16) {
                    Text("Login")
                        .font(.largeTitle)

                    // 데모용: 임시 로그인 성공 버튼
                    Button("임시 로그인 성공") {
                        onLoginSuccess()   // 부모에 성공 알림
                        dismiss()          // 시트 닫기
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            
    } // body
} // view

#Preview {
    LoginView()
}
