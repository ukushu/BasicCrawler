
import Foundation
import Alamofire
import AsyncNinja
import SwiftSoup

public func getHTMLDoc(from urlStr: String, accessType: UrlAccessType = .fast, cookies: [HTTPCookie] = []) -> Document? {
    guard let html = Crawl.Html.getSync(from: urlStr, cookies: cookies, access: accessType),
       let doc: Document = try? SwiftSoup.parse(html)
    else { return nil }
    
    return doc
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
    if urlStr.count < 3 {
        return true
    }
    
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
