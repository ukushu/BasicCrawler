
import WebKit

@MainActor
class MyInternetLoader: NSObject {
    lazy var webView: WKWebView = {
        let webView: WKWebView = WKWebView()
        webView.navigationDelegate = self
        webView.customUserAgent = userAgentsList.randomElement()!
        webView.allowsLinkPreview = true
        
        return webView
    }()
    
    private var resultHtml: String? = nil
        
    var continuation: UnsafeContinuation<String?, Error>?
    
    func getHTML(from url: URL, cookies: [HTTPCookie]) async throws -> String? {
        return try await withUnsafeThrowingContinuation { continuation in
            self.continuation = continuation
            
            for cookie in cookies{
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
            
            webView.load(URLRequest(url: url))
        }
    }
}

extension MyInternetLoader: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Thread.sleep(forTimeInterval: 6)
        
        webView.evaluateJavaScript("document.body.innerHTML") { [weak self] (result, error) in
            if let error = error {
                print("Error executing JavaScript: \(error.localizedDescription)")
            } else if let htmlContent = result as? String {
                self?.resultHtml = htmlContent
            }
            self?.continuation?.resume(returning: self?.resultHtml)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
    }
}
