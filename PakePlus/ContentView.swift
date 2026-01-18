//
//  ContentView.swift
//  PakePlus
//
//  Created by Song on 2025/3/29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // BottomMenuView()
        WebView(url: URL(string: "http://100.86.55.29:8000")!)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
