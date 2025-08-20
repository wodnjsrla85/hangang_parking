//
//  NoticeView.swift
//  hangang
//
//  Created by 정서윤 on 8/18/25.
//

import SwiftUI

struct NoticeView: View {
    
    @EnvironmentObject var userManager: UserManager

    
    @State private var goInquiry = false
    @State private var showLoginAlert = false
    @State private var showLoginSheet = false

    var body: some View {
        NavigationView(content: {
            VStack(content: {
                // 분수일정
                    VStack(alignment: .leading) {
                        Text("분수일정")
                            .font(.headline)
                            .padding(.top, 20)
                        
                        HStack {
                            Text("비수기 (4월 - 6월, 9월 - 10월)")
                            
                            Text("매회 20분")
                                .background()
                        }
                        
                        Text("12:00, 19:30, 20:00, 20:30, 21:00")
                        
                        HStack {
                            Text("성수기 (7월 - 8월)")
                            
                            Text("매회 20분")
                                .background(Color.white)
                        }
                        
                        Text("12:00, 19:30, 20:00, 20:30, 21:00, 21:30")
                        
                        Text("무지개분수 가동 중지 조건 (전력낭비에방을 위해 기상상황에 따라 분수 가동 중지")
                    }
                    .padding()
                
                    
                
                // 행사 공연 정보
                List(content: {
                    HStack (alignment: .top){
                        Image("한강페스티벌")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack (alignment: .leading){
                            Text("2025 한강페스티벌 여름")
                                .font(.headline)
                            
                            HStack {
                                Text("기간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("2025-07-26(토) ~ 2025-08-24(일)")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("시간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("프로그램별 상이")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("참여")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("프로그램별 상이")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("장소")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("한강 수상과 10개 한강공원 일대")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                    HStack (alignment: .top){
                        Image("한강사진공모전")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack (alignment: .leading){
                            Text("제22회 아름다운 한강사진 공모전")
                                .font(.headline)
                                .lineLimit(1)              // 최대 1줄만
                                .truncationMode(.tail)     // 잘릴 경우 뒤쪽을 ... 으로
                            
                            HStack {
                                Text("기간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("2025-07-09(수) ~ 2025-08-28(목)")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("시간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("프로그램별 상이")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("참여")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("온라인 접수")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("장소")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("한강 및 한강공원 전역")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                    HStack (alignment: .top){
                        Image("서울 러닝크루")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack(alignment: .leading) {
                            Text("7979 서울 러닝크루")
                                .font(.headline)
                            
                            HStack {
                                Text("기간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("2025-04-10(목) ~ 2025-10-30(목)")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("시간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("저녁 7시~9시")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("참여")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("사전접수 및 현장참여")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("장소")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("반포한강공원 달빛광장, 여의도공원 문화의 마당")
                                    .font(.system(size: 10.5))
                                    .lineLimit(1)              // 최대 1줄만
                                    .truncationMode(.tail)     // 잘릴 경우 뒤쪽을 ... 으로
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                    HStack (alignment: .top){
                        Image("한강역사탐방")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack(alignment: .leading) {
                            Text("2025년 한강 역사탐방")
                                .font(.headline)
                            
                            HStack {
                                Text("기간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("2025-04-04(금) ~ 2025-11-30(일)")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("시간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("1일 2회 오전 10 ~ 12시, 오후 2 ~ 4시")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("참여")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("3월 28일(금)부터 선착순 진행, 참여희망일 5일전까지")
                                    .font(.system(size: 10.5))
                                    .lineLimit(1)              // 최대 1줄만
                                    .truncationMode(.tail)     // 잘릴 경우 뒤쪽을 ... 으로
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("장소")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("한강공원과 인근 문화유산(16코스)")
                                    .font(.system(size: 10.5))
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                })
                
                NavigationLink(destination: InquiryView(), isActive: $goInquiry) {
                    EmptyView()
                }
                .hidden()
                
            }) // VStack
            .navigationTitle(Text("공지사항"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button {
                        print("🔘 문의 버튼 클릭됨")
                        print("👤 현재 로그인 상태: \(userManager.isLoggedIn)")
                        
                        if userManager.isLoggedIn {  // ✅ UserManager 사용!
                            print("✅ 로그인됨 - InquiryView로 이동")
                            goInquiry = true
                        } else {
                            print("❌ 비로그인 - 로그인 Alert 표시")
                            showLoginAlert = true
                        }
                    } label: {
                        Image(systemName: "person.fill.questionmark")
                    }
                })
            })
            
            .alert("로그인이 필요합니다",
                   isPresented: $showLoginAlert) {
                Button("로그인하기") {
                    showLoginSheet = true
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("로그인 후 이용 가능합니다.")
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView {
                    print("🎉 로그인 성공 콜백 호출됨")
                    print("👤 UserManager 로그인 상태: \(userManager.isLoggedIn)")
                    
                    // 시트가 닫힌 후 약간의 딜레이를 두고 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        print("📍 goInquiry = true 설정")
                        goInquiry = true
                    }
                }
            }
            // 디버깅용 상태 변화 모니터링
            .onChange(of: goInquiry) {
                print("📍 goInquiry 상태 변경: \(goInquiry)")
            }
            .onChange(of: userManager.isLoggedIn) {
                print("👤 UserManager 로그인 상태 변경: \(userManager.isLoggedIn)")
            }
        })
        
    } // body
} // view

#Preview {
    NoticeView()
        .environmentObject(UserManager())
}
