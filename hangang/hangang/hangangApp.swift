//
//  hangangApp.swift
//  hangang
//
//  Created by 김재원 on 8/18/25.
//

import SwiftUI

@main
struct hangangApp: App {
    @StateObject var userManager = UserManager() // 앱 전체에 UserManager 연결
    var body: some Scene {
        WindowGroup {
            NoticeView()
                .environmentObject(userManager) // ****
        }
    }
}
