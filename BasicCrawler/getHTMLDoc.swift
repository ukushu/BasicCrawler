import Foundation
import Alamofire
import AsyncNinja
import Essentials
import SwiftSoup
import WebKit

public enum UrlAccessType {
    case Fast
    case Advanced
}

public func getHTMLDoc(from urlStr: String, accessType: UrlAccessType = .Fast , cookies: [HTTPCookie] = []) -> Document? {
    guard let url = URL(string: urlStr) else { return nil }
    
    if accessType == .Fast {
        guard let html = HTML.getFastFrom(from: url, cookies: cookies),
              let htmlFixed = html.removingPercentEncoding
        else { return nil }
        
        guard let doc: Document = try? SwiftSoup.parse(htmlFixed) else { return nil }
        return doc
    } else {
        guard let html = HTML.getFromAdvanced(url: urlStr, cookies: cookies),
              let htmlFixed = html.removingPercentEncoding
        else { return nil }
        
        guard let doc: Document = try? SwiftSoup.parse(htmlFixed) else { return nil }
        return doc
    }
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
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36
Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (Macintosh; Intel Mac OS X 14.5; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (X11; Linux i686; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (X11; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0
Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15
Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0)
Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)
Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)
Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)
Mozilla/4.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)
Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)
Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)
Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko
Mozilla/5.0 (Windows NT 6.2; Trident/7.0; rv:11.0) like Gecko
Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko
Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.2535.67
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.2535.67
Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35
Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35
Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 OPR/111.0.0.0
Mozilla/5.0 (Windows NT 10.0; WOW64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 OPR/111.0.0.0
Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 OPR/111.0.0.0
Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 OPR/111.0.0.0
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 YaBrowser/24.4.4.1160 Yowser/2.5 Safari/537.36
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 YaBrowser/24.4.4.1160 Yowser/2.5 Safari/537.36
""".split(separator: "\n").map{ $0.asStr() }
