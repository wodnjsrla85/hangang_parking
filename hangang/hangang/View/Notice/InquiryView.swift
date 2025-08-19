//
//  InquiryView.swift
//  hangang
//
//  Created by 정서윤 on 8/18/25.
//

import SwiftUI

struct InquiryView: View {
    var body: some View {

            VStack (alignment: .leading){
                NavigationLink(destination: OneOnOneInquiry()) {
                    Text("1 : 1 문의")
                }
                .padding()
                
                NavigationLink(destination: MyInquiryHistory()) {
                    Text("나의 문의내역")
                }
                .padding()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("문의사항")
            .navigationBarTitleDisplayMode(.large)
        
    } // body
} // view

#Preview {
    InquiryView()
}
