//
//  MainView.swift
//  hangang
//
//  Created by 김재원 on 8/20/25.
//

import SwiftUI
import MapKit

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

// 개선된 WeatherViewModel
@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherText: String = "날씨 정보 로딩 중..."
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentTemperature: Double = 0
    @Published var currentHumidity: Double = 0
    @Published var currentDiscomfortIndex: Double = 0
    @Published var weatherDescription: String = ""
    @Published var isConnected: Bool = false
    
    private let weatherService = OpenWeatherService()
    
    func fetchWeather() async {
        isLoading = true
        errorMessage = nil
        
        // API 키 확인
        guard weatherService.isAPIKeyValid() else {
            errorMessage = "API 키가 설정되지 않았습니다"
            weatherText = "API 키를 설정해주세요"
            isLoading = false
            return
        }
        
        do {
            let weatherData = try await weatherService.fetchCurrentWeather()
            
            currentTemperature = weatherData.temperature
            currentHumidity = weatherData.humidity
            currentDiscomfortIndex = weatherData.discomfortIndex
            weatherDescription = weatherData.description
            isConnected = true
            
            // 깔끔한 형식으로 텍스트 구성
            weatherText = formatWeatherText(
                temp: weatherData.temperature,
                humidity: weatherData.humidity,
                description: weatherData.description
            )
            
            print("✅ 날씨 업데이트 완료: \(weatherText)")
            
        } catch {
            print("❌ 날씨 가져오기 실패: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isConnected = false
            
            // 에러 상황에 따른 적절한 메시지 설정
            if error.localizedDescription.contains("API 키") {
                weatherText = "API 키 설정 필요"
            } else if error.localizedDescription.contains("네트워크") {
                weatherText = "네트워크 연결 확인 필요"
            } else {
                weatherText = "날씨 정보 일시적 오류"
            }
        }
        
        isLoading = false
    }
    
    func fetchWeatherForDateTime(date: Date, hour: Int) async -> (temperature: Double, humidity: Double, description: String, discomfortIndex: Double)? {
        guard weatherService.isAPIKeyValid() else {
            print("⚠️ API 키가 설정되지 않음")
            return nil
        }
        
        do {
            return try await weatherService.fetchWeatherForecast(for: date, hour: hour)
        } catch {
            print("❌ 예보 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 테스트 연결 함수
    func testConnection() async {
        let result = await weatherService.testConnection()
        print("🔍 연결 테스트 결과: \(result)")
    }
    
    private func formatWeatherText(temp: Double, humidity: Double, description: String) -> String {
        // 온도는 소수점 1자리, 습도는 정수로 표시
        let tempString = String(format: "%.1f", temp)
        let humidityString = String(format: "%.0f", humidity)
        
        // 설명은 첫 글자만 대문자로 변경
        let cleanDescription = description.isEmpty ? "맑음" : description
        
        return "\(tempString)°C, \(cleanDescription), 습도 \(humidityString)%"
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
        isLoading = true
        errorMessage = nil
        predictionResult = nil
        
        guard let url = URL(string: "\(baseURL)/") else {
            errorMessage = "잘못된 URL"
            isLoading = false
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
                errorMessage = "서버 응답 오류"
                isLoading = false
                return
            }
            
            let predictionResponse = try JSONDecoder().decode(PredictionResponse.self, from: data)
            
            predictionResult = predictionResponse
            isLoading = false
            
        } catch {
            errorMessage = "예측 요청 실패: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

struct MainView: View {
    @StateObject private var viewModel = MarkerViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @StateObject private var predictionViewModel = PredictionViewModel()
    @EnvironmentObject var userManager: UserManager
    @State private var selectedCategory: String = "전체"
    @State private var selectedMarker: Marker?
    @State private var showingBottomSheet = false
    @State private var showingCategoryList = false
    @State private var showingLoginSheet = false
    @State private var showingLogoutAlert = false
    @State private var showingPredictionSheet = false
    
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
                        
                        // 예측 버튼
                        FloatingActionButton(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple,
                            action: {
                                showingPredictionSheet = true
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
            PredictionSheet(
                predictionViewModel: predictionViewModel,
                weatherViewModel: weatherViewModel
            )
            .presentationDetents([.height(700), .large])
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
}

// MARK: - 자동 피크시간 계산이 포함된 PredictionSheet
struct PredictionSheet: View {
    @ObservedObject var predictionViewModel: PredictionViewModel
    @ObservedObject var weatherViewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedHour = 12
    @State private var discomfortIndex = 0.0
    @State private var isPeakTime = false
    @State private var isLoadingWeather = false
    @State private var weatherInfo: String = "날씨 정보 로딩 중..."
    @State private var isAutoDiscomfort = true // 자동 계산 모드
    @State private var isAutoPeakTime = true // 자동 피크시간 계산 모드 추가
    
    // 2025년 공휴일 목록 (월-일 형태)
    private let holidays2025: Set<String> = [
        "01-01", "01-28", "01-29", "01-30", "03-01", "05-05",
        "05-15", "06-06", "08-15", "10-03", "10-06", "10-09", "12-25"
    ]
    
    private var availableHours: [Int] {
        let calendar = Calendar.current
        let now = Date()
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        if selectedDateComponents == todayComponents {
            let currentHour = calendar.component(.hour, from: now)
            let maxHour = min(23, currentHour + 12)
            return Array(currentHour...maxHour)
        } else {
            return []
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return today...today
    }
    
    private var autoMode: String {
        let month = Calendar.current.component(.month, from: selectedDate)
        return [3, 4, 7, 8, 11].contains(month) ? "승차" : "하차"
    }
    
    private var isAutoHoliday: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        
        if weekday == 1 || weekday == 7 {
            return true
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        return holidays2025.contains(dateString)
    }
    
    // 자동 피크시간 계산 함수
    private var autoPeakTime: Bool {
        let currentMode = autoMode
        let isHoliday = isAutoHoliday
        
        if currentMode == "승차" {
            if isHoliday {
                // 공휴일 승차 피크시간: 19, 20, 21, 22시
                return [19, 20, 21, 22].contains(selectedHour)
            } else {
                // 평일 승차 피크시간: 20, 21, 22시
                return [20, 21, 22].contains(selectedHour)
            }
        } else { // 하차
            if isHoliday {
                // 공휴일 하차 피크시간: 16, 17, 18, 19, 20시
                return [16, 17, 18, 19, 20].contains(selectedHour)
            } else {
                // 평일 하차 피크시간: 18, 19, 20시
                return [18, 19, 20].contains(selectedHour)
            }
        }
    }
    
    // 피크시간 설명 텍스트
    private var peakTimeDescription: String {
        let currentMode = autoMode
        let isHoliday = isAutoHoliday
        
        if currentMode == "승차" {
            if isHoliday {
                return "공휴일 승차 피크시간: 19~22시"
            } else {
                return "평일 승차 피크시간: 20~22시"
            }
        } else { // 하차
            if isHoliday {
                return "공휴일 하차 피크시간: 16~20시"
            } else {
                return "평일 하차 피크시간: 18~20시"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("예측 설정") {
                    DatePicker("날짜 선택", selection: $selectedDate, in: dateRange, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .onChange(of: selectedDate) { _ in
                            if let firstHour = availableHours.first {
                                selectedHour = firstHour
                            }
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
                            Task {
                                await loadWeatherInfo()
                            }
                        }
                    }
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
        
        // 실제 OpenWeatherMap API 호출
        if let weatherData = await weatherViewModel.fetchWeatherForDateTime(date: selectedDate, hour: selectedHour) {
            await MainActor.run {
                weatherInfo = String(format: "기온: %.1f°C, 습도: %.0f%%, %s",
                                   weatherData.temperature,
                                   weatherData.humidity,
                                   weatherData.description)
                
                if isAutoDiscomfort {
                    discomfortIndex = weatherData.discomfortIndex
                }
                isLoadingWeather = false
            }
        } else {
            await MainActor.run {
                weatherInfo = "날씨 정보를 가져올 수 없습니다"
                isLoadingWeather = false
            }
        }
    }
    
    private func performPrediction() {
        guard !availableHours.isEmpty else { return }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 불쾌지수 결정
        let finalDiscomfortIndex = isAutoDiscomfort ? discomfortIndex : discomfortIndex
        
        // 피크시간 결정
        let finalPeakTime = isAutoPeakTime ? autoPeakTime : isPeakTime
        
        let request = PredictionRequest(
            date: dateFormatter.string(from: selectedDate),
            hour: selectedHour,
            holiday: isAutoHoliday ? 1 : 0,
            discomfort: finalDiscomfortIndex,
            peak: finalPeakTime ? 1 : 0, // 자동 계산된 피크시간 사용
            month: calendar.component(.month, from: selectedDate),
            weekday: calendar.component(.weekday, from: selectedDate) - 1,
            mode: autoMode
        )
        
        print("🚗 예측 요청 정보:")
        print("   날짜: \(dateFormatter.string(from: selectedDate))")
        print("   시간: \(selectedHour)시")
        print("   모드: \(autoMode)")
        print("   공휴일: \(isAutoHoliday ? "예" : "아니오")")
        print("   피크시간: \(finalPeakTime ? "예" : "아니오") (\(isAutoPeakTime ? "자동" : "수동"))")
        print("   불쾌지수: \(String(format: "%.1f", finalDiscomfortIndex)) (\(isAutoDiscomfort ? "자동" : "수동"))")
        
        Task {
            await predictionViewModel.predict(request: request)
        }
    }
}

// MARK: - PredictionResultView
struct PredictionResultView: View {
    let result: PredictionResponse
    
    // 주차장별 최대 주차대수
    private let maxParkingPanpo1 = 332
    private let maxParkingPanpo23 = 337
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(result.hour)시 예측 결과")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                PredictionResultRow(
                    title: "반포1주차장",
                    value: result.hourly_parking_panpo1,
                    maxValue: maxParkingPanpo1,
                    icon: "car.fill",
                    color: .blue
                )
                
                PredictionResultRow(
                    title: "반포2,3주차장",
                    value: result.hourly_parking_panpo23,
                    maxValue: maxParkingPanpo23,
                    icon: "car.fill",
                    color: .green
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

// MARK: - PredictionResultRow
struct PredictionResultRow: View {
    let title: String
    let value: Double
    let maxValue: Int
    let icon: String
    let color: Color
    
    // 예측값이 최대값을 넘는지 확인
    private var isOverCapacity: Bool {
        value > Double(maxValue)
    }
    
    // 실제 표시할 값 (최대값 초과 시 최대값으로 제한)
    private var displayValue: Int {
        if isOverCapacity {
            return maxValue
        } else {
            return Int(value.rounded())
        }
    }
    
    // 주차 상황에 따른 색상 결정
    private var statusColor: Color {
        if isOverCapacity {
            return .red
        }
        
        let percentage = (value / Double(maxValue)) * 100
        if percentage >= 90 {
            return .red // 거의 만차
        } else if percentage >= 70 {
            return .orange // 혼잡
        } else if percentage >= 50 {
            return .yellow // 보통
        } else {
            return .green // 여유
        }
    }
    
    // 상태 텍스트
    private var statusText: String {
        if isOverCapacity {
            return "주차 불가"
        }
        
        let percentage = (value / Double(maxValue)) * 100
        if percentage >= 90 {
            return "거의 만차"
        } else if percentage >= 70 {
            return "혼잡"
        } else if percentage >= 50 {
            return "보통"
        } else {
            return "여유"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if isOverCapacity {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("만차")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("\(displayValue) / \(maxValue)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                    
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.1))
                        )
                }
            }
            
            // 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .opacity(0.3)
                        .foregroundColor(Color(.systemGray4))
                        .cornerRadius(3)
                    
                    Rectangle()
                        .frame(width: isOverCapacity ? geometry.size.width : min(CGFloat(value / Double(maxValue)) * geometry.size.width, geometry.size.width), height: 6)
                        .foregroundColor(statusColor)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.5), value: value)
                }
            }
            .frame(height: 6)
            
            // 주차 불가 메시지
            if isOverCapacity {
                HStack {
                    Image(systemName: "car.circle.fill")
                        .foregroundColor(.red)
                    Text("해당 시간대에는 주차장이 만차 예상됩니다")
                        .font(.caption)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ModernWeatherCard
struct ModernWeatherCard: View {
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    // 날씨 설명에 따른 아이콘 결정
    private func getWeatherIcon() -> String {
        if weatherViewModel.isLoading {
            return "cloud"
        }
        
        let description = weatherViewModel.weatherDescription.lowercased()
        
        if description.contains("맑") || description.contains("clear") {
            return "sun.max.fill"
        } else if description.contains("구름") || description.contains("cloud") {
            return "cloud.fill"
        } else if description.contains("비") || description.contains("rain") {
            return "cloud.rain.fill"
        } else if description.contains("눈") || description.contains("snow") {
            return "cloud.snow.fill"
        } else if description.contains("안개") || description.contains("fog") {
            return "cloud.fog.fill"
        } else {
            return "cloud.sun.fill"
        }
    }
    
    // 날씨에 따른 아이콘 색상
    private func getWeatherIconColor() -> Color {
        let description = weatherViewModel.weatherDescription.lowercased()
        
        if description.contains("맑") || description.contains("clear") {
            return .orange
        } else if description.contains("비") || description.contains("rain") {
            return .blue
        } else if description.contains("눈") || description.contains("snow") {
            return .cyan
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 날씨 아이콘
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [
                            getWeatherIconColor().opacity(0.3),
                            getWeatherIconColor().opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                if weatherViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: getWeatherIconColor()))
                } else {
                    Image(systemName: getWeatherIcon())
                        .foregroundColor(getWeatherIconColor())
                        .font(.title2)
                }
            }
            
            // 날씨 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("한강공원 날씨")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                if weatherViewModel.isLoading {
                    HStack(spacing: 8) {
                        Text("로딩 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = weatherViewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weatherViewModel.weatherText)
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        if errorMessage.contains("API 키") {
                            Text("설정에서 API 키 확인")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
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
                Image(systemName: weatherViewModel.isLoading ? "arrow.clockwise" : (weatherViewModel.isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"))
                    .foregroundColor(weatherViewModel.isConnected ? .green : .red)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(
                        (weatherViewModel.isConnected ? Color.green : Color.red).opacity(0.1)
                    )
                    .clipShape(Circle())
                    .rotationEffect(.degrees(weatherViewModel.isLoading ? 360 : 0))
                    .animation(
                        weatherViewModel.isLoading ?
                        .linear(duration: 1.0).repeatForever(autoreverses: false) :
                        .default,
                        value: weatherViewModel.isLoading
                    )
            }
            .disabled(weatherViewModel.isLoading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            weatherViewModel.isConnected ?
                            Color.green.opacity(0.3) :
                            Color.red.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .onAppear {
            // 앱 시작 시 연결 테스트
            Task {
                await weatherViewModel.testConnection()
            }
        }
    }
}

// MARK: - CategorySelectionView
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
            
            // 로그인/로그아웃 버튼
            Button(action: {
                if userManager.isLoggedIn {
                    showingLogoutAlert = true
                } else {
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

// MARK: - ModernMarkerView
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

// MARK: - FloatingActionButton
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

// MARK: - LoadingOverlay
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

// MARK: - ErrorToast
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
            .padding(.bottom, 140)
        }
    }
}

// MARK: - ModernMarkerDetailSheet
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
//            if let phone = marker.phone, !phone.isEmpty {
//                VStack(spacing: 12) {
//                    Button(action: {
//                        if let phoneURL = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
//                            UIApplication.shared.open(phoneURL)
//                        }
//                    }) {
//                        HStack {
//                            Image(systemName: "phone.fill")
//                            Text("전화 걸기")
//                        }
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.green)
//                        .cornerRadius(12)
//                    }
//                }
//                .padding(.horizontal, 24)
//                .padding(.bottom, 32)
//            }
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

// MARK: - ModernInfoRow
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

// MARK: - CategoryListSheet
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

// MARK: - CategoryListItem
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
