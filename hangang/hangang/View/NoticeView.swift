//
//  NoticeView.swift
//  hangang
//
//  Created by 정서윤 on 8/18/25.
//

import SwiftUI

struct NoticeView: View {
    var body: some View {
        NavigationView(content: {
            VStack(content: {
                // 분수일정
                ZStack(alignment: .topLeading) {
                    ContainerRelativeShape()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 350, height: 200)
                        .clipShape(.buttonBorder)
                        .padding(.top)
                    
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
                }
                    
                
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
                                    .font(.system(size: 10))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("시간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("프로그램별 상이")
                                    .font(.system(size: 10))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("참여")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("프로그램별 상이")
                                    .font(.system(size: 10))
                            }
                            .padding(.top, 1)
                            
                            HStack {
                                Text("장소")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("한강 수상과 10개 한강공원 일대")
                                    .font(.system(size: 10))
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
                            
                            HStack {
                                Text("기간")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("2025-07-26(토) ~ 2025-08-24(일)")
                                    .font(.system(size: 10))
                            }
                            .padding(.top, 1)
                        }
                    }
                    
                    HStack (alignment: .top){
                        Image("서울 러닝크루")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack {
                            Text("한강페스티벌")
                                .font(.headline)
                        }
                    }
                    
                    HStack (alignment: .top){
                        Image("한강역사탐방")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 110, height: 150)
                        
                        VStack {
                            Text("한강페스티벌")
                                .font(.headline)
                        }
                    }
                    
                })
                
            }) // VStack
            .navigationTitle(Text("공지사항"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: InquiryView()) {
                        Image(systemName: "person.fill.questionmark")
                    }
                })
            })
        })
        
    } // body
} // view

#Preview {
    NoticeView()
}
