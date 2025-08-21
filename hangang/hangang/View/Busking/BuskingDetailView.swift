
//
//  dd.swift
//  hangang
//
//  Created by 김지호 on 8/19/25.
//

import SwiftUI

struct BuskingDetailView: View {
    @State private var name = ""
    @State private var bandname = ""
    @State private var category = ""
    @State private var dateTime = ""
    @State private var place = ""
    @State private var genre = ""
    @State private var content = ""

    // 알림 상태
    @State private var showAlert = false
    @State private var alertMessage = ""


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("버스킹 신청을 위한 안내 문구를 작성합니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    Group {
                        customTextField("밴드 이름", text: $bandname)
                        customTextField("이름", text: $name)
                        customTextField("장르", text: $category)
                        customTextField("공연 날짜 및 시간", text: $dateTime)

                    }

                    // 멀티라인 필드
                    customTextEditor("공연 내용 상세 설명", text: $content)
                    Spacer()
                    // 신청하기 버튼
                    Button(action: {
                        Task {
                            let success = await insertAction()
                            if success {
                                alertMessage = "신청이 완료되었습니다 신청 결과는 마이페이지에서 확인 가능합니다."
                            } else {
                                alertMessage = "신청 중 오류가 발생했습니다."
                            }
                            showAlert = true
                        }
                    }) {
                        Text("신청하기")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text(alertMessage))
                    }

                }
                .padding()
            }
            .navigationTitle("반포한강공원 버스킹 신청서")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    //---------- Function -----------------

    func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }

    func customTextEditor(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            TextEditor(text: text)
                .frame(height: 200)
                .padding(6)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    //  insertAction: 성공 여부 반환
    func insertAction() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:8000/busking/insert") else { return false }

        let body: [String: Any] = [
            "userid": "212312312222",
            "name": name,
            "date": dateTime,
            "category": category,
            "content": content,
            "bandName": bandname,
            "state": 0
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("전송 실패:", error.localizedDescription)
            return false
        }
    }
}

#Preview {
    BuskingDetailView()
}
