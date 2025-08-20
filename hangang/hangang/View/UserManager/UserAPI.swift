//
//  UserAPI.swift
//  hangang
//
//  Created by 정서윤 on 8/20/25.
//

import Foundation

// MARK: - User Models
struct User: Codable {
    let id: String
    let phone: String?
    let date: String?
}

struct UserCreate: Codable {
    let id: String
    let pw: String
    let phone: String?
}

struct UserLogin: Codable {
    let id: String
    let pw: String
}

// MARK: - Response Models
struct SignUpResponse: Codable {
    let result: String
    let message: String
    let userID: String
}

struct LoginResponse: Codable {
    let result: String
    let message: String
    let user: User
}

// MARK: - API Functions
func signUpUser(id: String, pw: String, phone: String? = nil) async throws -> SignUpResponse {
    let url = APIConfig.shared.baseURL.appendingPathComponent("api/user/signup")
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let userCreate = UserCreate(id: id, pw: pw, phone: phone)
    request.httpBody = try JSONEncoder().encode(userCreate)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = errorData["detail"] as? String {
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: detail])
        }
        throw URLError(.badServerResponse)
    }
    
    return try JSONDecoder().decode(SignUpResponse.self, from: data)
}

func loginUser(id: String, pw: String) async throws -> LoginResponse {
    let url = APIConfig.shared.baseURL.appendingPathComponent("api/user/login")
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let userLogin = UserLogin(id: id, pw: pw)
    request.httpBody = try JSONEncoder().encode(userLogin)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let detail = errorData["detail"] as? String {
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: detail])
        }
        throw URLError(.badServerResponse)
    }
    
    return try JSONDecoder().decode(LoginResponse.self, from: data)
}
