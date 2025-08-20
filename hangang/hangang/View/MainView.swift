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

// WeatherViewModel 추가
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

struct MainView: View {
    @StateObject private var viewModel = MarkerViewModel()
    @StateObject private var weatherViewModel = WeatherViewModel()
    @State private var selectedCategory: String = "전체"
    @State private var selectedMarker: Marker?
    @State private var showingBottomSheet = false
    @State private var showingCategoryList = false
    
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
                    showingCategoryList: $showingCategoryList
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
            
            // 마커 개수 표시
            Text("\(getFilteredCount())개")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )
        }
        .padding(.horizontal, 20)
    }
    
    private func getFilteredCount() -> Int {
        // 실제 필터링된 마커 개수를 반환하는 로직
        return 42 // 임시값
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
            
//            // 액션 버튼들
//            if let phone = marker.phone, !phone.isEmpty {
//                VStack(spacing: 12) {
//                    Button(action: {
//                        if let phoneURL = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
//                            UIApplication.shared.open(phoneURL)
//                        }
//                    }) {
//                        HStack {
//                            Image(systemName: "phone.fill")
//                            Text("전화걸기")
//                        }
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 16)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color.blue)
//                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
//                        )
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
    MainView()
}
