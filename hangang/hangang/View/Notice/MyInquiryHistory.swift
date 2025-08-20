//
//  MyInquiryHistory.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct MyInquiryHistory: View {
    
    
    
    @EnvironmentObject var userManager: UserManager
    
    @StateObject var viewModel = InquiryViewModel()
    
    var body: some View {
        VStack(content: {
            List(viewModel.inquiries, id: \.id) { inquiry in
                NavigationLink(destination: InquiryDetail(inquiry: inquiry)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(inquiry.safeTitle)  // 안전한 제목
                            .font(.headline)
                        Text(inquiry.safeContent)  // 안전한 내용
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        HStack {
                            Text(inquiry.qdate ?? "날짜 미확인")  // 안전한 날짜
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(inquiry.displayState)  // 안전한 상태
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(inquiry.isAnswered ? Color.green : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        })
        .navigationTitle("나의 문의내역")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserInquiries(userID: userManager.currentUserID ?? "")
        }
        .refreshable {
            await viewModel.fetchInquiries()
        }
    } // body
} // view

#Preview {
    NavigationView {
        MyInquiryHistory()
            .environmentObject(UserManager())
    }
}
