//
//  WeatherService.swift
//  hangang
//
//  Created by 김재원 on 8/24/25.
//

import Foundation
import CoreLocation

// OpenWeatherMap API Response 모델
struct OpenWeatherMapResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
    let humidity: Int
    let feelsLike: Double
    
    enum CodingKeys: String, CodingKey {
        case temp, humidity
        case feelsLike = "feels_like"
    }
}

struct WeatherDescription: Codable {
    let main: String
    let description: String
}

// 예보 응답 모델
struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Int
    let main: MainWeather
    let weather: [WeatherDescription]
}

// 날씨 에러
enum WeatherError: Error, LocalizedError {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case apiKeyMissing
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .decodingError(let message):
            return "데이터 파싱 오류: \(message)"
        case .apiKeyMissing:
            return "API 키가 필요합니다. WeatherService.swift에서 API 키를 설정해주세요."
        case .httpError(let code):
            return "HTTP 오류 (코드: \(code)). API 키를 확인해주세요."
        }
    }
}

// 날씨 서비스 클래스
class OpenWeatherService: ObservableObject {
    // TODO: 여기에 실제 OpenWeatherMap API 키를 입력하세요
    // https://openweathermap.org/api 에서 무료 계정 생성 후 API 키를 받으세요
    private let apiKey = "c8777b97b5134b6100f849934a5a3e98"
    
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let forecastURL = "https://api.openweathermap.org/data/2.5/forecast"
    
    // 한강공원 좌표 (반포한강공원)
    private let hanRiverCoordinate = CLLocationCoordinate2D(
        latitude: 37.5097778,
        longitude: 126.9952838
    )
    
    // 현재 날씨 가져오기
    func fetchCurrentWeather() async throws -> (temperature: Double, humidity: Double, description: String, discomfortIndex: Double) {
        // API 키 체크
        guard !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" else {
            print("⚠️ API 키가 설정되지 않았습니다!")
            throw WeatherError.apiKeyMissing
        }
        
        let urlString = "\(baseURL)?lat=\(hanRiverCoordinate.latitude)&lon=\(hanRiverCoordinate.longitude)&appid=\(apiKey)&units=metric&lang=kr"
        print("🌤️ 날씨 API 호출: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL")
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // HTTP 응답 체크
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP 상태 코드: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("❌ API 키 인증 실패 (401)")
                    }
                    throw WeatherError.httpError(httpResponse.statusCode)
                }
            }
            
            // 응답 데이터 출력 (디버깅용)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 API 응답: \(jsonString)")
            }
            
            let weatherResponse = try JSONDecoder().decode(OpenWeatherMapResponse.self, from: data)
            
            let temperature = weatherResponse.main.temp
            let humidity = Double(weatherResponse.main.humidity)
            let description = weatherResponse.weather.first?.description ?? "정보 없음"
            
            // 불쾌지수 계산
            let discomfortIndex = calculateDiscomfortIndex(temperature: temperature, humidity: humidity)
            
            print("✅ 날씨 데이터 성공: 온도 \(temperature)°C, 습도 \(humidity)%, 설명: \(description)")
            
            return (temperature, humidity, description, discomfortIndex)
            
        } catch DecodingError.dataCorrupted(let context) {
            print("❌ 디코딩 오류 - dataCorrupted: \(context)")
            throw WeatherError.decodingError("데이터가 손상됨: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ 디코딩 오류 - keyNotFound: \(key), \(context)")
            throw WeatherError.decodingError("키를 찾을 수 없음: \(key.stringValue)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ 디코딩 오류 - typeMismatch: \(type), \(context)")
            throw WeatherError.decodingError("타입 불일치: \(type)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ 디코딩 오류 - valueNotFound: \(type), \(context)")
            throw WeatherError.decodingError("값을 찾을 수 없음: \(type)")
        } catch let networkError {
            print("❌ 네트워크 오류: \(networkError.localizedDescription)")
            throw WeatherError.networkError(networkError.localizedDescription)
        }
    }
    
    // 특정 날짜와 시간의 날씨 예보 (5일 예보 API 사용)
    func fetchWeatherForecast(for date: Date, hour: Int) async throws -> (temperature: Double, humidity: Double, description: String, discomfortIndex: Double) {
        // API 키 체크
        guard !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE" else {
            print("⚠️ API 키가 설정되지 않았습니다!")
            throw WeatherError.apiKeyMissing
        }
        
        let urlString = "\(forecastURL)?lat=\(hanRiverCoordinate.latitude)&lon=\(hanRiverCoordinate.longitude)&appid=\(apiKey)&units=metric&lang=kr"
        print("🌤️ 예보 API 호출: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL")
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP 상태 코드: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 401 {
                        print("❌ API 키 인증 실패 (401)")
                    }
                    throw WeatherError.httpError(httpResponse.statusCode)
                }
            }
            
            let forecastResponse = try JSONDecoder().decode(ForecastResponse.self, from: data)
            
            // 가장 가까운 시간의 예보 찾기
            let calendar = Calendar.current
            let targetDate = calendar.dateComponents([.year, .month, .day], from: date)
            
            var closestForecast: ForecastItem?
            var closestTimeDifference = Int.max
            
            for item in forecastResponse.list {
                let forecastDate = Date(timeIntervalSince1970: TimeInterval(item.dt))
                let forecastComponents = calendar.dateComponents([.year, .month, .day, .hour], from: forecastDate)
                
                // 같은 날짜인지 확인
                if forecastComponents.year == targetDate.year &&
                   forecastComponents.month == targetDate.month &&
                   forecastComponents.day == targetDate.day {
                    
                    let timeDifference = abs((forecastComponents.hour ?? 0) - hour)
                    if timeDifference < closestTimeDifference {
                        closestTimeDifference = timeDifference
                        closestForecast = item
                    }
                }
            }
            
            if let forecast = closestForecast {
                let temperature = forecast.main.temp
                let humidity = Double(forecast.main.humidity)
                let description = forecast.weather.first?.description ?? "정보 없음"
                let discomfortIndex = calculateDiscomfortIndex(temperature: temperature, humidity: humidity)
                
                print("✅ 예보 데이터 성공: 온도 \(temperature)°C, 습도 \(humidity)%, 설명: \(description)")
                
                return (temperature, humidity, description, discomfortIndex)
            } else {
                print("⚠️ 해당 시간의 예보를 찾을 수 없어 현재 날씨를 반환합니다.")
                // 해당 시간을 찾을 수 없으면 현재 날씨 반환
                return try await fetchCurrentWeather()
            }
            
        } catch let weatherError where weatherError is WeatherError {
            // 이미 적절한 에러이므로 다시 throw
            throw weatherError
        } catch DecodingError.dataCorrupted(let context) {
            print("❌ 예보 디코딩 오류 - dataCorrupted: \(context)")
            throw WeatherError.decodingError("데이터가 손상됨: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ 예보 디코딩 오류 - keyNotFound: \(key), \(context)")
            throw WeatherError.decodingError("키를 찾을 수 없음: \(key.stringValue)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ 예보 디코딩 오류 - typeMismatch: \(type), \(context)")
            throw WeatherError.decodingError("타입 불일치: \(type)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ 예보 디코딩 오류 - valueNotFound: \(type), \(context)")
            throw WeatherError.decodingError("값을 찾을 수 없음: \(type)")
        } catch let networkError {
            print("❌ 예보 네트워크 오류: \(networkError.localizedDescription)")
            throw WeatherError.networkError(networkError.localizedDescription)
        }
    }
    
    // 불쾌지수 계산 공식
    private func calculateDiscomfortIndex(temperature: Double, humidity: Double) -> Double {
        // 불쾌지수 계산 공식: DI = 1.8T - 0.55(1 - H/100)(1.8T - 26) + 32
        // T: 기온(°C), H: 상대습도(%)
        let discomfort = 1.8 * temperature - 0.55 * (1 - humidity/100) * (1.8 * temperature - 26) + 32
        return max(0, min(100, discomfort))
    }
    
    // API 키 유효성 검사
    func isAPIKeyValid() -> Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_API_KEY_HERE"
    }
    
    // 테스트용 함수 - API 키와 연결 상태 확인
    func testConnection() async -> String {
        if !isAPIKeyValid() {
            return "❌ API 키가 설정되지 않았습니다. WeatherService.swift에서 API 키를 설정해주세요."
        }
        
        do {
            let _ = try await fetchCurrentWeather()
            return "✅ 연결 성공! 날씨 데이터를 가져올 수 있습니다."
        } catch let connectionError {
            return "❌ 연결 실패: \(connectionError.localizedDescription)"
        }
    }
}

