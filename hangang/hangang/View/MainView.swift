//
//  MainView.swift
//  hangang
//
//  Created by 김재원 on 8/20/25.
//

import SwiftUI
import MapKit

// 날씨 정보 모델 추가
struct WeatherInfo: Codable {
    let title: String
}

struct WeatherResponse: Codable {
    let results: [WeatherInfo]
}

// 예측 요청 모델
struct PredictionRequest: Codable {
    let date: String
    let hour: Int
    let holiday: Int
    let discomfort: Double
    let peak: Int
    let month: Int
    let weekday: Int
    let mode: String
}

// 예측 응답 모델 - 날씨 정보 추가
struct PredictionResponse: Codable {
    let daily_parking_panpo1: Double
    let daily_parking_panpo23: Double
    let hourly_parking_panpo1: Double
    let hourly_parking_panpo23: Double
    let hour: Int
    let weather_info: WeatherData?
    let auto_discomfort: Double?
}

// 날씨 데이터 모델 추가
struct WeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let description: String
    let discomfort_index: Double
}

// WeatherViewModel 추가
@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherText: String = "날씨 정보 로딩 중..."
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://127.0.0.1:8000"  // 실제 서버 IP로 변경 필요
    
    func fetchWeather() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/weather") else {
            DispatchQueue.main.async {
                self.errorMessage = "잘못된 URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "서버 응답 오류"
                    self.isLoading = false
                }
                return
            }
            
            let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            
            DispatchQueue.main.async {
                if let firstWeather = weatherResponse.results.first {
                    self.weatherText = firstWeather.title
                } else {
                    self.weatherText = "날씨 정보 없음"
                }
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "날씨 정보를 가져올 수 없습니다"
                self.weatherText = "날씨 정보 오류"
                self.isLoading = false
            }
        }
    }
}

// 예측 ViewModel 추가
@MainActor
class PredictionViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var predictionResult: PredictionResponse?
    
    private let baseURL = "http://127.0.0.1:8000"  // 실제 서버 IP로 변경 필요
    
    func predict(request: PredictionRequest) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.predictionResult = nil
        }
        
        guard let url = URL(string: "\(baseURL)/") else {
            DispatchQueue.main.async {
                self.errorMessage = "잘못된 URL"
                self.isLoading = false
            }
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.errorMessage = "서버 응답 오류"
                    self.isLoading = false
                }
                return
            }
            
            let predictionResponse = try JSONDecoder().decode(PredictionResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.predictionResult = predictionResponse
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "예측 요청 실패: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct MainView: View {
    @StateObject private var viewModel = MarkerViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var predictionViewModel = PredictionViewModel()
    @EnvironmentObject var userManager: UserManager // UserManager 추가
    @State private var selectedCategory: String = "전체"
    @State private var selectedMarker: Marker?
    @State private var showingBottomSheet = false
    @State private var showingCategoryList = false
    @State private var showingLoginSheet = false // 로그인 시트 상태 추가
    @State private var showingLogoutAlert = false // 로그아웃 확인 알림 추가
    @State private var showingPredictionSheet = false // 예측 시트 상태 추가
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5097778, longitude: 126.9952838),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    // 카테고리 목록
    private let categories = ["전체", "액티비티", "매점", "공연", "주차장", "화장실", "민간시설", "안내센터", "출입구", "응급시설", "흡연부스", "편의시설", "직영시설", "광장", "승강장"]
    
    // 필터링된 마커들
    private var filteredMarkers: [Marker] {
        if selectedCategory == "전체" {
            return viewModel.markers
        } else {
            return viewModel.markers.filter { marker in
                marker.type.lowercased() == selectedCategory.lowercased()
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 지도
            Map(coordinateRegion: $region, annotationItems: filteredMarkers) { marker in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lng)) {
                    ModernMarkerView(marker: marker) {
                        selectedMarker = marker
                        showingBottomSheet = true
                    }
                }
            }
            .ignoresSafeArea()
            
            // 상단 컨트롤 영역
            VStack(spacing: 16) {
                // 날씨 정보 카드
                ModernWeatherCard(weatherViewModel: weatherViewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // 카테고리 선택 영역
                CategorySelectionView(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    showingCategoryList: $showingCategoryList,
                    userManager: userManager,
                    showingLoginSheet: $showingLoginSheet,
                    showingLogoutAlert: $showingLogoutAlert,
                    showingPredictionSheet: $showingPredictionSheet
                )
                
                Spacer()
            }
            
            // 오른쪽 하단 플로팅 버튼들
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 현재 위치 버튼
                        FloatingActionButton(
                            icon: "location.fill",
                            color: .blue,
                            action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: 37.5097778, longitude: 126.9952838),
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    )
                                }
                            }
                        )
                        
                        // 새로고침 버튼
                        FloatingActionButton(
                            icon: "arrow.clockwise",
                            color: .green,
                            action: {
                                Task {
                                    await viewModel.loadMarkers()
                                    await weatherViewModel.fetchWeather()
                                }
                            }
                        )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 120) // 탭바 공간 확보
                }
            }
            
            // 로딩 오버레이
            if viewModel.isLoading {
                LoadingOverlay()
            }
            
            // 에러 알림
            if let errorMessage = viewModel.errorMessage {
                ErrorToast(message: errorMessage)
            }
        }
        .task {
            await viewModel.loadMarkers()
            await weatherViewModel.fetchWeather()
        }
        .sheet(isPresented: $showingBottomSheet) {
            if let marker = selectedMarker {
                ModernMarkerDetailSheet(marker: marker)
                    .presentationDetents([.height(500), .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingCategoryList) {
            CategoryListSheet(
                categories: categories,
                selectedCategory: $selectedCategory,
                showingCategoryList: $showingCategoryList
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLoginSheet) {
            LoginView {
                // 로그인 성공 후 아무것도 안 함 (시트만 닫힘)
            }
        }
        .sheet(isPresented: $showingPredictionSheet) {
            PredictionSheet(predictionViewModel: predictionViewModel)
                .presentationDetents([.height(600), .large])
                .presentationDragIndicator(.visible)
        }
        .alert("로그아웃", isPresented: $showingLogoutAlert) {
            Button("로그아웃", role: .destructive) {
                userManager.logout()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("정말로 로그아웃 하시겠습니까?")
        }
    }
    
    // 마커 타입에 따른 아이콘 반환
    private func getIconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "액티비티": return "figure.run"
        case "매점": return "basket.fill"
        case "공연": return "music.note"
        case "주차장": return "car.fill"
        case "화장실": return "toilet.fill"
        case "민간시설": return "building.2.fill"
        case "안내센터": return "info.circle.fill"
        case "출입구": return "door.left.hand.open"
        case "응급시설": return "cross.case.fill"
        case "흡연부스": return "smoke.fill"
        case "편의시설": return "wrench.and.screwdriver.fill"
        case "직영시설": return "house.fill"
        case "광장": return "square.grid.3x3.fill"
        case "승강장": return "tram.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    // 마커 타입에 따른 색상 반환
    private func getColorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "액티비티": return .green
        case "매점": return .orange
        case "공연": return .purple
        case "주차장": return .gray
        case "화장실": return .blue
        case "민간시설": return .brown
        case "안내센터": return .cyan
        case "출입구": return .indigo
        case "응급시설": return .red
        case "흡연부스": return .secondary
        case "편의시설": return .mint
        case "직영시설": return .teal
        case "광장": return .yellow
        case "승강장": return .pink
        case "전체": return .blue
        default: return .black
        }
    }
}

// MARK: - 예측 시트
struct PredictionSheet: View {
    @ObservedObject var predictionViewModel: PredictionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedHour = 12
    @State private var discomfortIndex = 0.0 // 0으로 초기화 (자동 계산)
    @State private var isPeakTime = false
    @State private var isLoadingWeather = false
    @State private var weatherInfo: String = "날씨 정보 로딩 중..."
    
    // 2025년 공휴일 목록 (월-일 형태)
    private let holidays2025: Set<String> = [
        "01-01", // 신정
        "01-28", "01-29", "01-30", // 설날
        "03-01", // 삼일절
        "05-05", // 어린이날
        "05-15", // 부처님오신날
        "06-06", // 현충일
        "08-15", // 광복절
        "10-03", "10-06", // 추석
        "10-09", // 한글날
        "12-25"  // 크리스마스
    ]
    
    // 예측 가능한 시간 범위 계산
    private var availableHours: [Int] {
        let calendar = Calendar.current
        let now = Date()
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        // 선택된 날짜가 오늘인지 확인
        if selectedDateComponents == todayComponents {
            let currentHour = calendar.component(.hour, from: now)
            let maxHour = min(23, currentHour + 12) // 현재 시간 + 12시간 또는 23시 중 작은 값
            return Array(currentHour...maxHour)
        } else {
            return [] // 오늘이 아니면 빈 배열
        }
    }
    
    // 오늘만 선택 가능한 날짜 범위
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return today...today
    }
    
    // 선택된 날짜에 따른 모드 자동 결정
    private var autoMode: String {
        let month = Calendar.current.component(.month, from: selectedDate)
        return [3, 4, 7, 8, 11].contains(month) ? "승차" : "하차"
    }
    
    // 선택된 날짜의 공휴일 여부 자동 결정
    private var isAutoHoliday: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate) // 1=일요일, 7=토요일
        
        // 주말인지 확인
        if weekday == 1 || weekday == 7 {
            return true
        }
        
        // 공휴일인지 확인
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        return holidays2025.contains(dateString)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("기본 정보") {
                    DatePicker("날짜 선택", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: selectedDate) { _ in
                            // 날짜 변경 시 첫 번째 가능한 시간으로 설정
                            if let firstHour = availableHours.first {
                                selectedHour = firstHour
                            }
                            // 날씨 정보 자동 로드
                            Task {
                                await loadWeatherInfo()
                            }
                        }
                    
                    if availableHours.isEmpty {
                        Text("오늘만 예측 가능합니다")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        Picker("시간", selection: $selectedHour) {
                            ForEach(availableHours, id: \.self) { hour in
                                Text("\(hour)시").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        .onChange(of: selectedHour) { _ in
                            // 시간 변경 시 날씨 정보 업데이트
                            Task {
                                await loadWeatherInfo()
                            }
                        }
                    }
                    
                    // 자동 결정된 모드 표시
                    HStack {
                        Text("모드")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(autoMode)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(autoMode == "승차" ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                            )
                    }
                    
                    // 자동 결정된 공휴일 여부 표시
                    HStack {
                        Text("공휴일/주말")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(isAutoHoliday ? "예" : "아니오")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isAutoHoliday ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                            )
                    }
                }
                
                Section("날씨 및 설정") {
                    // 날씨 정보 표시
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("날씨 정보")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            if isLoadingWeather {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        Text(weatherInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // 자동 계산된 불쾌지수 표시
                    VStack(alignment: .leading, spacing: 8) {
                        Text("불쾌지수: \(discomfortIndex == 0 ? "자동 계산" : String(format: "%.1f", discomfortIndex))")
                            .font(.subheadline)
                        
                        if discomfortIndex == 0 {
                            Text("날씨 정보를 바탕으로 자동 계산됩니다")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Text("수동 조정:")
                                    .font(.caption)
                                Slider(value: $discomfortIndex, in: 0...100, step: 1)
                                Button("자동") {
                                    discomfortIndex = 0
                                    Task {
                                        await loadWeatherInfo()
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                    }
                    
                    Toggle("피크타임", isOn: $isPeakTime)
                }
                
                Section("예측 결과") {
                    if predictionViewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("예측 중...")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else if let error = predictionViewModel.errorMessage {
                        Text("오류: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else if let result = predictionViewModel.predictionResult {
                        PredictionResultView(result: result)
                    } else {
                        Text("예측 버튼을 눌러 결과를 확인하세요")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .navigationTitle("주차장 예측")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") {
                    dismiss()
                },
                trailing: Button("예측") {
                    performPrediction()
                }
                .disabled(predictionViewModel.isLoading || availableHours.isEmpty)
            )
            .onAppear {
                // 초기 로드 시 날짜를 오늘로 설정하고 첫 번째 가능한 시간 선택
                selectedDate = Date()
                if let firstHour = availableHours.first {
                    selectedHour = firstHour
                }
                Task {
                    await loadWeatherInfo()
                }
            }
        }
    }
    
    private func loadWeatherInfo() async {
        isLoadingWeather = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // 실제 날씨 API 호출 시뮬레이션 (여기서는 Mock 데이터 사용)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        
        // Mock 날씨 데이터 (실제로는 OpenWeatherMap API 호출)
        let mockTemp = Double.random(in: 15...30)
        let mockHumidity = Double.random(in: 40...80)
        let mockDiscomfort = calculateDiscomfortIndex(temp: mockTemp, humidity: mockHumidity)
        
        await MainActor.run {
            weatherInfo = String(format: "기온: %.1f°C, 습도: %.0f%%, 불쾌지수: %.1f", mockTemp, mockHumidity, mockDiscomfort)
            if discomfortIndex == 0 { // 자동 계산 모드일 때만 업데이트
                discomfortIndex = mockDiscomfort
            }
            isLoadingWeather = false
        }
    }
    
    private func calculateDiscomfortIndex(temp: Double, humidity: Double) -> Double {
        // 불쾌지수 계산 공식
        let discomfort = 1.8 * temp - 0.55 * (1 - humidity/100) * (1.8 * temp - 26) + 32
        return max(0, min(100, discomfort))
    }
    
    private func performPrediction() {
        guard !availableHours.isEmpty else { return }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let request = PredictionRequest(
            date: dateFormatter.string(from: selectedDate),
            hour: selectedHour,
            holiday: isAutoHoliday ? 1 : 0,
            discomfort: discomfortIndex == 0 ? discomfortIndex : discomfortIndex, // 0이면 서버에서 자동 계산
            peak: isPeakTime ? 1 : 0,
            month: calendar.component(.month, from: selectedDate),
            weekday: calendar.component(.weekday, from: selectedDate) - 1, // 0-6 (월-일)
            mode: autoMode
        )
        
        Task {
            await predictionViewModel.predict(request: request)
        }
    }
}

// MARK: - 예측 결과 뷰
struct PredictionResultView: View {
    let result: PredictionResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(result.hour)시 예측 결과")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                PredictionResultRow(
                    title: "반포1주차장 (일별)",
                    value: result.daily_parking_panpo1,
                    icon: "calendar",
                    color: .blue
                )
                
                PredictionResultRow(
                    title: "반포2,3주차장 (일별)",
                    value: result.daily_parking_panpo23,
                    icon: "calendar",
                    color: .green
                )
                
                PredictionResultRow(
                    title: "반포1주차장 (시간별)",
                    value: result.hourly_parking_panpo1,
                    icon: "clock",
                    color: .orange
                )
                
                PredictionResultRow(
                    title: "반포2,3주차장 (시간별)",
                    value: result.hourly_parking_panpo23,
                    icon: "clock",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 예측 결과 행
struct PredictionResultRow: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(Int(value.rounded()))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 모던 날씨 카드
struct ModernWeatherCard: View {
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 날씨 아이콘
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
            }
            
            // 날씨 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("한강공원 날씨")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                if weatherViewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("로딩 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = weatherViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text(weatherViewModel.weatherText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // 새로고침 버튼
            Button(action: {
                Task {
                    await weatherViewModel.fetchWeather()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(weatherViewModel.isLoading)
            .scaleEffect(weatherViewModel.isLoading ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: weatherViewModel.isLoading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - 카테고리 선택 뷰
struct CategorySelectionView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    @Binding var showingCategoryList: Bool
    @ObservedObject var userManager: UserManager
    @Binding var showingLoginSheet: Bool
    @Binding var showingLogoutAlert: Bool
    @Binding var showingPredictionSheet: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 선택된 카테고리 표시
            Button(action: {
                showingCategoryList = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: getIconForCategory(selectedCategory))
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(selectedCategory)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(getColorForCategory(selectedCategory))
                        .shadow(color: getColorForCategory(selectedCategory).opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            
            Spacer()
            
            // 예측 버튼
            Button(action: {
                showingPredictionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("예측")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.indigo, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: Color.indigo.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
            }
            
            // 로그인/로그아웃 버튼
            Button(action: {
                if userManager.isLoggedIn {
                    // 로그아웃 확인 알림 표시
                    showingLogoutAlert = true
                } else {
                    // 로그인 시트 표시
                    showingLoginSheet = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: userManager.isLoggedIn ? "person.fill.checkmark" : "person.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text(userManager.isLoggedIn ? "로그아웃" : "로그인")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: userManager.isLoggedIn ?
                                [Color.red, Color.red.opacity(0.8)] :
                                [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: (userManager.isLoggedIn ? Color.red : Color.blue).opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "전체": return "square.grid.3x3"
        case "액티비티": return "figure.run"
        case "매점": return "basket.fill"
        case "공연": return "music.note"
        case "주차장": return "car.fill"
        case "화장실": return "toilet.fill"
        default: return "mappin"
        }
    }
    
    private func getColorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "전체": return .blue
        case "액티비티": return .green
        case "매점": return .orange
        case "공연": return .purple
        case "주차장": return .gray
        case "화장실": return .blue
        default: return .blue
        }
    }
}

// MARK: - 모던 마커 뷰
struct ModernMarkerView: View {
    let marker: Marker
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(getColorForType(marker.type))
                        .frame(width: 44, height: 44)
                        .shadow(color: getColorForType(marker.type).opacity(0.4), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: getIconForType(marker.type))
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(marker.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: marker.name)
    }
    
    private func getIconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "액티비티": return "figure.run"
        case "매점": return "basket.fill"
        case "공연": return "music.note"
        case "주차장": return "car.fill"
        case "화장실": return "toilet.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func getColorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "액티비티": return .green
        case "매점": return .orange
        case "공연": return .purple
        case "주차장": return .gray
        case "화장실": return .blue
        default: return .blue
        }
    }
}

// MARK: - 플로팅 액션 버튼
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
                )
        }
    }
}

// MARK: - 로딩 오버레이
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("마커를 불러오는 중...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - 에러 토스트
struct ErrorToast: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text("오류: \(message)")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                Capsule()
                    .fill(Color.red)
                    .shadow(radius: 10)
            )
            .padding(.horizontal)
            .padding(.bottom, 140) // 탭바 위에 표시
        }
    }
}

// MARK: - 모던 마커 상세 시트
struct ModernMarkerDetailSheet: View {
    let marker: Marker
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 16) {
                // 드래그 인디케이터
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 6)
                    .padding(.top, 8)
                
                // 마커 정보 헤더
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(getColorForType(marker.type))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: getIconForType(marker.type))
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(marker.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(marker.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(getColorForType(marker.type).opacity(0.1))
                            )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
            .background(Color(.systemGray6).opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 정보 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        ModernInfoRow(icon: "location", title: "주소", content: marker.address, color: .blue)
                        
                        if let time = marker.time, !time.isEmpty {
                            ModernInfoRow(icon: "clock", title: "운영시간", content: time, color: .green)
                        }
                        
                        if let method = marker.method, !method.isEmpty {
                            ModernInfoRow(icon: "creditcard", title: "결제방법", content: method, color: .purple)
                        }
                        
                        if let price = marker.price, !price.isEmpty {
                            ModernInfoRow(icon: "wonsign.circle", title: "가격", content: price, color: .orange)
                        }
                        
                        if let phone = marker.phone, !phone.isEmpty {
                            ModernInfoRow(icon: "phone", title: "전화번호", content: phone, color: .red)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // 액션 버튼들
            if let phone = marker.phone, !phone.isEmpty {
                VStack(spacing: 12) {
                    Button(action: {
                        if let phoneURL = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
                            UIApplication.shared.open(phoneURL)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("전화 걸기")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func getIconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "액티비티": return "figure.run"
        case "매점": return "basket.fill"
        case "공연": return "music.note"
        case "주차장": return "car.fill"
        case "화장실": return "toilet.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    private func getColorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "액티비티": return .green
        case "매점": return .orange
        case "공연": return .purple
        case "주차장": return .gray
        case "화장실": return .blue
        default: return .blue
        }
    }
}

// MARK: - 모던 정보 행
struct ModernInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(content)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 카테고리 리스트 시트
struct CategoryListSheet: View {
    let categories: [String]
    @Binding var selectedCategory: String
    @Binding var showingCategoryList: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.self) { category in
                    CategoryListItem(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        showingCategoryList = false
                    }
                }
            }
            .navigationTitle("카테고리 선택")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("완료") {
                showingCategoryList = false
            })
        }
    }
}

struct CategoryListItem: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: getIconForCategory(category))
                    .foregroundColor(getColorForCategory(category))
                    .frame(width: 24)
                
                Text(category)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "전체": return "square.grid.3x3"
        case "액티비티": return "figure.run"
        case "매점": return "basket.fill"
        case "공연": return "music.note"
        case "주차장": return "car.fill"
        case "화장실": return "toilet.fill"
        default: return "mappin"
        }
    }
    
    private func getColorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "전체": return .blue
        case "액티비티": return .green
        case "매점": return .orange
        case "공연": return .purple
        case "주차장": return .gray
        case "화장실": return .blue
        default: return .blue
        }
    }
}

#Preview {
    NavigationView(content: {
        MainView()
            .environmentObject(UserManager.shared)
    })
}
