//
//  WebView.swift
//  PakePlus
//
//  整合了酒馆全屏补丁与优化版本
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    // 1️⃣ 这里已经改成了你的酒馆地址
    let url: URL = URL(string: "http://100.86.55.29:8000")!
    let debug = false

    func makeUIView(context: Context) -> WKWebView {
        // 2️⃣ 配置允许全屏 API 调用
        let config = WKWebViewConfiguration()
        config.allowsElementPresentingFullscreen = true 
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // 设置滚动效果：禁用回弹（让酒馆界面更稳固，不会上下晃动）
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator

        // 3️⃣ 调试脚本支持
        if debug, let debugScript = WebView.loadJSFile(named: "vConsole") {
            let fullScript = debugScript + "\nvar vConsole = new window.VConsole();"
            let userScript = WKUserScript(
                source: fullScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            webView.configuration.userContentController.addUserScript(userScript)
        }

        // 4️⃣ 核心注入：禁用缩放 + 注入全屏补丁
        let tavernScript = """
            // 禁用双击缩放
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(meta);

            // 🎬 注入全屏 API 支持（解决前端卡全屏按钮无效问题）
            if (document.documentElement.webkitRequestFullscreen) {
                document.documentElement.requestFullscreen = document.documentElement.webkitRequestFullscreen;
                Element.prototype.requestFullscreen = Element.prototype.webkitRequestFullscreen || Element.prototype.webkitEnterFullscreen;
            }
        """
        let scriptInjection = WKUserScript(source: tavernScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(scriptInjection)
        
        // 5️⃣ 加载自定义外部 JS 文件 (如有)
        if let customScript = WebView.loadJSFile(named: "custom") {
            let userScript = WKUserScript(
                source: customScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            webView.configuration.userContentController.addUserScript(userScript)
        }

        // 6️⃣ 执行加载
        webView.load(URLRequest(url: url))
        
        // 添加手势：左右滑动切换页面（可选，如果你习惯酒馆内滑动的可以保留）
        let rightSwipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRightSwipe(_:)))
        rightSwipeGesture.direction = .right
        webView.addGestureRecognizer(rightSwipeGesture)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLeftSwipe(_:)))
        leftSwipeGesture.direction = .left
        webView.addGestureRecognizer(leftSwipeGesture)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新逻辑：通常不需要重复 load，除非 URL 发生变化
        // print("WebView Updated")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate, WKNavigationDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil // 彻底禁止缩放
        }
        
        @objc func handleRightSwipe(_ gesture: UISwipeGestureRecognizer) {
            if let webView = gesture.view as? WKWebView, webView.canGoBack {
                webView.goBack()
            }
        }
        
        @objc func handleLeftSwipe(_ gesture: UISwipeGestureRecognizer) {
            if let webView = gesture.view as? WKWebView, webView.canGoForward {
                webView.goForward()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("酒馆连接成功: \(String(describing: webView.url))")
        }
    }
}

extension WebView {
    static func loadJSFile(named filename: String) -> String? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "js") else {
            return nil
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
