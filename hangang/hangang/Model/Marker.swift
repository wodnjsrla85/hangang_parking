//
//  Marker.swift
//  hangang
//
//  Created by 김재원 on 8/19/25.
//

import Foundation

struct Marker: Codable, Identifiable {
    let id = UUID() // SwiftUI에서 사용할 수 있도록
    var name: String
    var type: String
    var lat: Double
    var lng: Double
    var address: String
    var time: String?      // 옵셔널로 변경
    var method: String?    // 옵셔널로 변경
    var price: String?     // 옵셔널로 변경
    var phone: String?     // 옵셔널로 변경
    
    // MongoDB의 _id는 무시하고 위 필드들만 사용
    enum CodingKeys: String, CodingKey {
        case name, type, lat, lng, address, time, method, price, phone
    }
    
    // 디코딩할 때 nil 값을 빈 문자열로 처리
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        lat = try container.decode(Double.self, forKey: .lat)
        lng = try container.decode(Double.self, forKey: .lng)
        address = try container.decode(String.self, forKey: .address)
        
        // 옵셔널 필드들은 없어도 빈 문자열로 처리
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? ""
        method = try container.decodeIfPresent(String.self, forKey: .method) ?? ""
        price = try container.decodeIfPresent(String.self, forKey: .price) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
    }
    
    // 일반 초기화도 제공
    init(name: String, type: String, lat: Double, lng: Double, address: String,
         time: String = "", method: String = "", price: String = "", phone: String = "") {
        self.name = name
        self.type = type
        self.lat = lat
        self.lng = lng
        self.address = address
        self.time = time
        self.method = method
        self.price = price
        self.phone = phone
    }
}
