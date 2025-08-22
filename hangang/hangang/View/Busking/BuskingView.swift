//
//  ContentView.swift
//  hangang
//
//  Created by 김지호 on 8/19/25.
//

import SwiftUI

struct BuskingView: View {
    @State var buskingModel: [Busking] = []
    @EnvironmentObject var userManager: UserManager
    @State private var showLoginAlert = false
    @State private var showLoginAlert2 = false
    @State private var showLoginSheet = false
    @State private var showLoginSheet2 = false
    @State private var goInquiry = false
    @State private var goStatus = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // 상단 대표 이미지
                Image("banpo")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                
                Text("Today Busking")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                
                // 표 형태 리스트
                List {
                    // 헤더
                    Section {
                        HStack {
                            Text("시간").bold().frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("아티스트").bold().frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("장르").bold()
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.gray.opacity(0.15))
                        
                        // 데이터 행
                        ForEach(buskingModel.filter { $0.state == 1 }, id: \._id) { row in
                            HStack {
                                Text(row.date)
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text(row.bandName)
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text(row.category)
                            }
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
                            )
                        }
                    }
                }
                .scrollContentBackground(.hidden) // 리스트 배경 흰색으로
                .background(Color.white)
                
                Spacer()
                VStack(content: {
                    
                    
                    
                    
                    NavigationLink(destination: BuskingInputView(), isActive: $goInquiry) {
                        // 신청 버튼
                        Button {
                            if userManager.currentUserID.isEmpty{
 
                                showLoginAlert = true
                                
                            } else {
                                goInquiry = true
                            }
                        } label: {
                            Text("버스킹 신청하기")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .frame(width: 200, height: 50)
                    }
                    .alert("로그인이 필요합니다", isPresented: $showLoginAlert) {
                        Button("로그인하기") {
                            showLoginSheet = true
                        }
                        Button("취소", role: .cancel) { }
                    } message: {
                        Text("로그인 후 이용 가능합니다.")
                    }
                    .sheet(isPresented: $showLoginSheet) {
                        LoginView {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                goInquiry = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
                    
                    NavigationLink(destination: BuskingStatusView(), isActive: $goStatus) {
                        // 신청 버튼
                        Button {
                            if userManager.currentUserID.isEmpty {
                                showLoginAlert = true
                            } else {
                               
                                goStatus = true
                            }
                        } label: {
                            Text("버스킹 신청 현황보기")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .frame(width: 200, height: 50)
                    }
                    .alert("로그인이 필요합니다", isPresented: $showLoginAlert2) {
                        Button("로그인하기") {
                            showLoginSheet2 = true
                        }
                        Button("취소", role: .cancel) { }
                    } message: {
                        Text("로그인 후 이용 가능합니다.")
                    }
                    .sheet(isPresented: $showLoginSheet2) {
                        LoginView {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                goStatus = true    
                            }
                        }
                        .environmentObject(userManager)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                })

                
                
                
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("한강공원 버스킹")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                buskingModel.removeAll()
                Task {
                    buskingModel = try await loadData(url: URL(string:"http://127.0.0.1:8000/busking/select")!)
                }
            }
        }
    }
    
    //---- Function ----
    func loadData(url: URL) async throws -> [Busking] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(BuskingListResponse.self, from: data)
        return decoded.results
    }
}

//#Preview {
//    BuskingView()
//        .environmentObject(UserManager.shared)
//}
