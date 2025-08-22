//
//  dd.swift
//  hangang
//
//  Created by 김지호 on 8/19/25.
//
import SwiftUI

struct BuskingInputView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var name = ""
    @State private var bandname = ""
    @State private var category = ""
    @State private var dateTime = Date()
    @State private var place = ""
    @State private var genre = ""
    @State private var content = ""

    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                    
                    DatePicker("공연 날짜 ", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                           .datePickerStyle(.compact)
                           .padding()
                           .background(Color(.systemGray6))
                           .cornerRadius(10)
                }

                customTextEditor("공연 내용 상세 설명", text: $content)

                Spacer()

                Button(action: {
                    Task {
                        let success = await insertAction()
                        await MainActor.run {
                            if success {
                                alertMessage = "신청이 완료되었습니다. 결과는 마이페이지에서 확인 가능합니다."
                                showAlert = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    dismiss()
                                }
                            } else {
                                alertMessage = "신청 중 오류가 발생했습니다."
                                showAlert = true
                            }
                        }
                    }
                })
                {
                    Text("신청하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertMessage),
                         dismissButton: .default(Text("확인")) {
                             if alertMessage.contains("신청 완료") {
                                 dismiss()
                             }
                         }
                        
                    
                    )
                }
            }
            .padding()
        }
        .navigationTitle("반포한강공원 버스킹 신청서")
        .navigationBarTitleDisplayMode(.inline)
        
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
        let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd HH:mm"
          let dateString = formatter.string(from: dateTime)
        
        
        let body: [String: Any] = [
            "userid": userManager.currentUserID,
            "name": name,
            "date": dateString,
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
    detail()
}
