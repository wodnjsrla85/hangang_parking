//
//  OneOnOneInquiry.swift
//  hangang
//
//  Created by 정서윤 on 8/19/25.
//

import SwiftUI

struct OneOnOneInquiry: View {
    @State var title: String = ""
    @State var content: String = ""
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("문의 제목 *")
                .padding(.top, 50)
                
            TextField("문의 제목을 입력해주세요", text: $title)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 2))
                .focused($isTextFieldFocused)
            
                .padding(.bottom, 30)
            
            Text("문의 내용 *")
            
            ZStack {
                
                if content.isEmpty {
                    Text("문의 내용을 입력해주세요")
                        .foregroundColor(.gray)
                }
                
                TextEditor(text: $content)
                    .frame(minHeight: 100, maxHeight: 150) // 원하는 높이
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                    )
                    .focused($isTextFieldFocused)
            }
                
            
            Spacer()
                        
            }
            .navigationTitle("1 : 1 문의")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        
        Button("작성완료", action: {
            //
        })
        .padding(.bottom, 60)
    } // body
} // view

#Preview {
    OneOnOneInquiry()
}
