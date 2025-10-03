
import Foundation
import Essentials

public func getHtmlSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
    getHtmlFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
}

public func getHtmlDataFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Data> {
    guard let url = URL(string: urlStr) else {
        print()
        return .failed(WTF("Wrong URL"))
    }
    
    return Flow.Future {
        let config = URLSessionConfiguration.default
        config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        let cookieStorage = HTTPCookieStorage()
        
        for c in cookies {
            cookieStorage.setCookie(c)
        }
        
        let (data, _) = try await session.data(from: url)
        
        return data
    }
}

public func getHtmlFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
    guard let url = URL(string: urlStr) else {
        print()
        return .failed(WTF("Wrong URL"))
    }
    
    return Flow.Future {
        let config = URLSessionConfiguration.default
        config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
        
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        let cookieStorage = HTTPCookieStorage()
        
        for c in cookies {
            cookieStorage.setCookie(c)
        }
        
        let (data, _) = try await session.data(from: url)
        
        guard let tmp = String(data: data, encoding: .utf8)
        else { return "Error" }
        
        return tmp
    }
}

public func getHtmlAsync(from urlStr: String) async -> String? {
    return await getJsonAsync(from: urlStr)
}
