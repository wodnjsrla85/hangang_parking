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
                ContainerRelativeShape()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 350, height: 200)
                    .clipShape(.buttonBorder)
                    .padding(.top)
                
                // 행사 공연 정보
                List(content: {
                    //
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
