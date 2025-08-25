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
    @State private var isRefreshing = false
    
    // 승인된 버스킹만 필터링
    private var approvedBuskings: [Busking] {
        buskingModel.filter { $0.state == 1 } // 1은 승인 상태
    }
    
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
                    
                    // Today Busking 헤더 (새로고침 버튼 추가)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Approved Busking")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("예정된 버스킹 일정")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // 새로고침 버튼
                        Button {
                            refreshData()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.weight(.medium))
                                Text("새로고침")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .disabled(isRefreshing)
                        .opacity(isRefreshing ? 0.6 : 1.0)
                        
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    
                    // 승인된 버스킹 개수 표시
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("예정된 버스킹")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(approvedBuskings.count)개")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
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
                            .fill(Color.green.opacity(0.1))
                    )
                    .padding(.horizontal, 16)
                    
                    // 로딩 인디케이터
                    if isRefreshing {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("새로고침 중...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // 데이터 행들 (승인된 것만 표시)
                    if approvedBuskings.isEmpty && !isRefreshing {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("예정된 버스킹이 없습니다")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("예정된 버스킹만 표시됩니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if !isRefreshing {
                        LazyVStack(spacing: 8) {
                            ForEach(approvedBuskings, id: \._id) { row in
                                HStack(spacing: 16) {
                                    // 시간 섹션 (날짜와 시간 모두 표시)
                                    VStack(spacing: 2) {
                                        Text(dateFromDateString(row.date))
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.green)
                                        Text(timeFromDate(row.date))
                                            .font(.title3.bold())
                                            .foregroundColor(.green)
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
                                    .frame(width: 80, alignment: .leading)
                                    
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
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                        )
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
            .refreshable {
                await refreshDataAsync()
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
                loadBuskingData()
            }
        }
    }
    
    //---- Functions ----
    func loadBuskingData() {
        buskingModel.removeAll()
        Task {
            do {
                buskingModel = try await loadData(url: URL(string:"http://127.0.0.1:8000/busking/select")!)
                print("✅ 데이터 로딩 성공: \(buskingModel.count)개")
                print("✅ 승인된 버스킹: \(approvedBuskings.count)개")
                for busking in buskingModel {
                    print("- ID: \(busking._id), 밴드: \(busking.bandName), 상태: \(busking.state)")
                }
            } catch {
                print("❌ 데이터 로딩 실패: \(error)")
            }
        }
    }
    
    // 새로고침 함수 (동기)
    func refreshData() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = true
        }
        
        Task {
            do {
                let newData = try await loadData(url: URL(string:"http://127.0.0.1:8000/busking/select")!)
                await MainActor.run {
                    buskingModel = newData
                    print("🔄 새로고침 완료: \(buskingModel.count)개")
                    print("🔄 승인된 버스킹: \(approvedBuskings.count)개")
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRefreshing = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ 새로고침 실패: \(error)")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRefreshing = false
                    }
                }
            }
        }
    }
    
    // 새로고침 함수 (비동기 - pull to refresh용)
    func refreshDataAsync() async {
        do {
            let newData = try await loadData(url: URL(string:"http://127.0.0.1:8000/busking/select")!)
            await MainActor.run {
                buskingModel = newData
                print("🔄 Pull to Refresh 완료: \(buskingModel.count)개")
                print("🔄 승인된 버스킹: \(approvedBuskings.count)개")
            }
        } catch {
            print("❌ Pull to Refresh 실패: \(error)")
        }
    }
    
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
