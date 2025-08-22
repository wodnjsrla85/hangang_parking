//
//  BuskingStatusView.swift
//  hangang
//
//  Created by 김지호 on 8/21/25.
//

import SwiftUI

struct BuskingStatusView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var myBuskingList: [Busking] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("신청 현황을 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if myBuskingList.isEmpty {
                    // 신청 내역이 없는 경우
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("신청한 버스킹이 없습니다")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                     
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 신청 내역이 있는 경우
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(myBuskingList, id: \._id) { busking in
                                BuskingStatusCard(busking: busking)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("내 버스킹 신청현황")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadMyBuskingStatus()
            }
            .refreshable {
                loadMyBuskingStatus()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
        }

 
        
    }
    
    
    private func loadMyBuskingStatus() {
        isLoading = true
        
        Task {
            do {
                let allBuskings = try await loadData(url: URL(string: "http://127.0.0.1:8000/busking/select")!)
                
                await MainActor.run {
                    // 현재 로그인한 사용자의 신청만 필터링
                    myBuskingList = allBuskings.filter { $0.userid == userManager.currentUserID }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "신청 현황을 불러오는데 실패했습니다."
                    showAlert = true
                }
            }
        }
    }
    
    private func loadData(url: URL) async throws -> [Busking] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(BuskingListResponse.self, from: data)
        return decoded.results
    }
}

struct BuskingStatusCard: View {
    let busking: Busking
    
    var statusInfo: (text: String, color: Color, icon: String) {
        switch busking.state {
        case 0:
            return ("승인대기", .orange, "clock.fill")
        case 1:
            return ("승인", .green, "checkmark.circle.fill")
        case 2:
            return ("불가", .red, "xmark.circle.fill")
        default:
            return ("알 수 없음", .gray, "questionmark.circle.fill")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 상태와 밴드명
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(busking.bandName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("신청자: \(busking.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 상태 표시
                HStack(spacing: 6) {
                    Image(systemName: statusInfo.icon)
                        .foregroundColor(statusInfo.color)
                    
                    Text(statusInfo.text)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusInfo.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    statusInfo.color.opacity(0.1)
                )
                .cornerRadius(20)
            }
            
            // 구분선
            Divider()
            
            // 상세 정보
            VStack(alignment: .leading, spacing: 8) {
                InfoRow2(icon: "calendar", title: "공연 일시", content: busking.date)
                InfoRow2(icon: "music.note", title: "장르", content: busking.category)
                
                if !busking.content.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("공연 내용")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(busking.content)
                            .font(.caption)
                            .lineLimit(3)
                            .padding(.leading, 28)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
 
   }

struct InfoRow2: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    BuskingStatusView()
        .environmentObject(UserManager.shared)
}
