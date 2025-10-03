import Foundation
import Alamofire
import AsyncNinja
import SwiftSoup
import WebKit

public enum UrlAccessType {
    case Fast
    case Advanced
}

public func getHTMLDoc(from urlStr: String, accessType: UrlAccessType = .Fast, cookies: [HTTPCookie] = []) -> Document? {
    guard let url = URL(string: urlStr) else { return nil }
    
    if accessType == .Fast {
        guard let html = //getHtmlSync(from: urlStr, cookies: cookies)
                
                HTML.getFastFrom(from: url, cookies: cookies)
        else { return nil }
        
        let htmlFixed = html.removingPercentEncoding ?? html
        
        guard let doc: Document = try? SwiftSoup.parse(htmlFixed) else { return nil }
        return doc
    } else {
        guard let html = HTML.getFromAdvanced(url: urlStr, cookies: cookies)
        else { return nil }
        
        let htmlFixed = html.removingPercentEncoding ?? html
        
        guard let doc: Document = try? SwiftSoup.parse(htmlFixed) else { return nil }
        return doc
    }
}

public func checkAccessibility(from urlStr: String) -> Bool {
    let url = URL(string: urlStr)!
    
    let config = URLSessionConfiguration.default
    config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
    let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    
    var failedCounter = 0
    
    for _ in 0..<8 {
        let response = session.data(at: url)
            .wait()
            .map{ $0.1 }
            .maybeSuccess
        
        if let response = response?.isResponseOK() {
            if response == true || failedCounter >= 2 {
                return response
            } else {
                failedCounter += 1
            }
        }
    }
    
    fatalError()
}

public func check404(from urlStr: String, tries: Int = 8, retriesSleep: TimeInterval) -> Bool {
    let url = URL(string: urlStr)!
    
    let config = URLSessionConfiguration.default
    config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
    let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    
    for _ in 0...tries {
        let response = session.data(at: url)
            .wait()
            .map{ $0.1 }
            .maybeSuccess
        
        if let statusCode = response?.getStatusCode() {
            return statusCode == 404
        }
        
        Thread.sleep(forTimeInterval: retriesSleep)
    }
    
    fatalError()
}

//////////////////////////////
//////////////////////////////

fileprivate class HTML {
    static func getFromAdvanced(url: String, cookies: [HTTPCookie]) -> String? {
        return getSyncResultFrom {
            let loader = await MyInternetLoader()
            
            return try? await loader.getHTML(from: URL(string: url)!, cookies: cookies)
        }
    }
    
    static func getFastFrom(from url: URL, cookies: [HTTPCookie]) -> String? {
        let config = URLSessionConfiguration.default
        config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        let cookieStorage = HTTPCookieStorage()
        
        for c in cookies {
            cookieStorage.setCookie(c)
        }
        
        session.configuration.httpCookieStorage = cookieStorage
        
        let html = session.data(at: url)
            .wait()
            .flatMap{ $0.0.asNonOptional }
            .flatMap{ $0.asString() }
            .maybeSuccess
        
        return html
    }
}


//////////////////
///HELPERS
//////////////////

@MainActor
fileprivate class MyInternetLoader: NSObject {
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

let userAgentsList = """
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36
""".split(separator: "\n").map{ $0.asStr() }.filter{ $0.count > 0 }

extension URLResponse {
    func getStatusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        return nil
    }
    
    func isResponseOK() -> Bool {
        guard let statusCode = getStatusCode() else { fatalError() }
        
        return (200...299).contains(statusCode)
    }
}
