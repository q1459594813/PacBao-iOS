import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    // 保持模板要求的参数接收
    let url: URL 
    let debug = false

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // 使用安全方式开启全屏（防止编译器报错）
        if #available(iOS 15.4, *) {
            config.setValue(true, forKey: "allowsElementPresentingFullscreen")
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        
        // 基础优化
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator

        // 注入：全屏补丁 + 禁用缩放
        let tavernScript = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(meta);

            if (document.documentElement.webkitRequestFullscreen) {
                document.documentElement.requestFullscreen = document.documentElement.webkitRequestFullscreen;
                Element.prototype.requestFullscreen = Element.prototype.webkitRequestFullscreen || Element.prototype.webkitEnterFullscreen;
            }
        """
        let scriptInjection = WKUserScript(source: tavernScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(scriptInjection)
        
        // 加载网址
        webView.load(URLRequest(url: url))
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 模板要求的更新逻辑
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @objc func handleRightSwipe(_ gesture: UISwipeGestureRecognizer) {
            if let webView = gesture.view as? WKWebView, webView.canGoBack {
                webView.goBack()
            }
        }
    }
}
