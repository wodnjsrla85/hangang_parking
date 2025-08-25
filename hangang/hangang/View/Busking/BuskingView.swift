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
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 상단 대표 이미지 (모던한 디자인)
                    ZStack(alignment: .bottomLeading) {
                        Image("banpo")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BANPO")
                                .font(.title.bold())
                                .foregroundColor(.white)
                            Text("HANGANG PARK")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(20)
                    }
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    .padding(.horizontal, 16)
                    
                    // Today Busking 헤더
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Busking Schedule")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("모든 버스킹 일정")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    
                    // 헤더 (스타일 개선)
                    HStack {
                        Text("날짜/시간")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        Text("아티스트")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text("장르")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal, 16)
                    
                    // 데이터 행들 (카드 스타일) - 모든 데이터 표시
                    if buskingModel.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("등록된 버스킹이 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("첫 번째 버스킹을 신청해보세요!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(buskingModel, id: \._id) { row in
                                HStack(spacing: 16) {
                                    // 시간 섹션 (날짜와 시간 모두 표시)
                                    VStack(spacing: 2) {
                                        Text(dateFromDateString(row.date))
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.blue)
                                        Text(timeFromDate(row.date))
                                            .font(.title3.bold())
                                            .foregroundColor(.blue)
                                        Text("DATE & TIME")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 80, alignment: .center)
                                    
                                    // 구분선
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 1, height: 35)
                                    
                                    // 아티스트
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.bandName)
                                            .font(.headline.weight(.medium))
                                            .foregroundColor(.primary)
                                        Text("Artist")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    // 장르
                                    HStack(spacing: 6) {
                                        Image(systemName: "music.note")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text(row.category)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    // 상태 인디케이터
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    
                    // 액션 버튼들 (모던한 스타일)
                    VStack(spacing: 12) {
                        NavigationLink(destination: BuskingInputView(), isActive: $goInquiry) {
                            Button {
                                if userManager.currentUserID.isEmpty {
                                    showLoginAlert = true
                                } else {
                                    goInquiry = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
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
                        
                        NavigationLink(destination: BuskingStatusView(), isActive: $goStatus) {
                            Button {
                                if userManager.currentUserID.isEmpty {
                                    showLoginAlert2 = true
                                } else {
                                    goStatus = true
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "list.clipboard")
                                        .font(.title3)
                                    Text("버스킹 신청 현황보기")
                                        .font(.headline.weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
            .navigationTitle("한강공원 버스킹")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                buskingModel.removeAll()
                Task {
                    do {
                        buskingModel = try await loadData(url: URL(string:"http://127.0.0.1:8000/busking/select")!)
                        print("✅ 데이터 로딩 성공: \(buskingModel.count)개")
                        for busking in buskingModel {
                            print("- ID: \(busking._id), 밴드: \(busking.bandName), 상태: \(busking.state)")
                        }
                    } catch {
                        print("❌ 데이터 로딩 실패: \(error)")
                    }
                }
            }
        }
    }
    
    //---- Function ----
    func loadData(url: URL) async throws -> [Busking] {
        print("🌐 API 호출 시작: \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP 상태 코드: \(httpResponse.statusCode)")
        }
        
        let dataString = String(data: data, encoding: .utf8) ?? "nil"
        print("📄 받은 데이터: \(dataString)")
        
        let decoded = try JSONDecoder().decode(BuskingListResponse.self, from: data)
        print("🔍 디코딩된 결과 개수: \(decoded.results.count)")
        
        return decoded.results
    }
    
    // 날짜 추출 함수
    private func dateFromDateString(_ dateString: String) -> String {
        // ISO 8601 형식 처리 (2025-08-22T16:03:00)
        if dateString.contains("T") {
            let components = dateString.components(separatedBy: "T")
            if components.count >= 1 {
                let dateComponent = components[0] // 2025-08-22
                let dateComponents = dateComponent.components(separatedBy: "-")
                if dateComponents.count >= 3 {
                    let month = dateComponents[1]
                    let day = dateComponents[2]
                    return "\(month)/\(day)" // 08/22
                }
                return dateComponent
            }
        }
        
        // 기존 형식 처리 (2025-08-22 16:03)
        if let spaceRange = dateString.range(of: " ") {
            let dateComponent = String(dateString[..<spaceRange.lowerBound])
            let dateComponents = dateComponent.components(separatedBy: "-")
            if dateComponents.count >= 3 {
                let month = dateComponents[1]
                let day = dateComponents[2]
                return "\(month)/\(day)" // 08/22
            }
            return dateComponent
        }
        
        return dateString
    }
    
    // 시간 추출 함수 (ISO 8601 형식 지원)
    private func timeFromDate(_ dateString: String) -> String {
        // ISO 8601 형식 처리 (2025-08-22T16:03:00)
        if dateString.contains("T") {
            let components = dateString.components(separatedBy: "T")
            if components.count >= 2 {
                let timeWithSeconds = components[1]
                // 초 제거 (16:03:00 -> 16:03)
                let timeComponents = timeWithSeconds.components(separatedBy: ":")
                if timeComponents.count >= 2 {
                    return "\(timeComponents[0]):\(timeComponents[1])"
                }
                return timeWithSeconds
            }
        }
        
        // 기존 형식 처리 (2025-08-22 16:03)
        if let timeRange = dateString.range(of: " ") {
            return String(dateString[timeRange.upperBound...])
        }
        
        return dateString
    }
}
