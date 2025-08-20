//
//  InquiryDetail.swift
//  hangang
//
//  Created by 정서윤 on 8/20/25.
//

import SwiftUI

struct InquiryDetail: View {
    
    @EnvironmentObject var userManager: UserManager
    
    let inquiry: Inquiry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 문의 제목
                VStack(alignment: .leading, spacing: 8) {
                    Text("문의 제목")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(inquiry.safeTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 문의 내용
                VStack(alignment: .leading, spacing: 8) {
                    Text("문의 내용")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(inquiry.safeContent)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 문의 정보
                VStack(alignment: .leading, spacing: 8) {
                    Text("문의 정보")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("작성자:")
                                .fontWeight(.medium)
                            Text(inquiry.safeUserID)
                            Spacer()
                        }
                        
                        HStack {
                            Text("작성일:")
                                .fontWeight(.medium)
                            Text(inquiry.qdate ?? "날짜 미확인")
                            Spacer()
                        }
                        
                        HStack {
                            Text("상태:")
                                .fontWeight(.medium)
                            Text(inquiry.displayState)
                                .foregroundColor(inquiry.isAnswered ? .green : .orange)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 답변 섹션
                if inquiry.isAnswered {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("관리자 답변")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if let answerContent = inquiry.answerContent, !answerContent.isEmpty {
                            Text(answerContent)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if let adate = inquiry.adate {
                            Text("답변일: \(adate)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("답변 대기 중")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("관리자가 답변을 준비 중입니다.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("문의 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview 제거함
