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
            VStack(spacing: 24) {
                
                // 헤더 섹션
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "music.mic")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("버스킹 신청서")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text("반포한강공원에서 버스킹을 위한 신청서를 작성해주세요. 승인 결과는 마이페이지에서 확인하실 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // 입력 폼 섹션
                VStack(spacing: 20) {
                    // 밴드 정보 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "밴드 정보", icon: "person.2.fill", color: .blue)
                        
                        modernTextField(
                            title: "밴드 이름",
                            placeholder: "밴드 이름을 입력하세요",
                            text: $bandname,
                            icon: "music.note.house"
                        )
                        
                        modernTextField(
                            title: "대표자 이름",
                            placeholder: "대표자 이름을 입력하세요",
                            text: $name,
                            icon: "person.fill"
                        )
                        
                        modernTextField(
                            title: "장르",
                            placeholder: "음악 장르를 입력하세요 (예: 록, 팝, 재즈)",
                            text: $category,
                            icon: "music.note"
                        )
                    }
                    
                    // 공연 정보 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "공연 정보", icon: "calendar", color: .orange)
                        
                        // 날짜 선택
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                Text("공연 날짜 및 시간")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            DatePicker("공연 날짜", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // 공연 내용
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                Text("공연 내용 설명")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .frame(height: 120)
                                
                                if content.isEmpty {
                                    Text("공연 내용, 세트리스트, 특별한 퍼포먼스 등을 자세히 설명해주세요...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 12)
                                        .padding(.leading, 16)
                                        .font(.subheadline)
                                }
                                
                                TextEditor(text: $content)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 제출 버튼
                VStack(spacing: 12) {
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
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                            Text("버스킹 신청하기")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(bandname.isEmpty || name.isEmpty || category.isEmpty)
                    .opacity(bandname.isEmpty || name.isEmpty || category.isEmpty ? 0.6 : 1.0)
                    
                    Text("* 모든 필수 항목을 입력해주세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // 🔧 탭바 공간 확보
            }
        }
        .background(
            LinearGradient(
                colors: [Color(.systemGray6), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("반포한강공원 버스킹 신청서")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("확인")) {
                    if alertMessage.contains("신청 완료") {
                        dismiss()
                    }
                }
            )
        }
    }

    //---------- Custom Views -----------------
    
    @ViewBuilder
    func modernTextField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            TextField(placeholder, text: text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
        }
    }

    //---------- Original Functions (unchanged) -----------------

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

    //  insertAction: 성공 여부 반환 (unchanged)
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

// MARK: - 섹션 헤더 컴포넌트
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.primary)
            Spacer()
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(height: 2)
                .frame(maxWidth: 100)
        }
    }
}
