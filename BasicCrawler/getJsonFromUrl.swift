
import Foundation
import Essentials

public func getJsonSync(from urlStr: String, cookies: [HTTPCookie]) -> String? {
    getJsonFuture(from: urlStr, cookies: cookies).wait().maybeSuccess
}

public func getDataFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<Data> {
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

public func getJsonFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
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
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let jsonString = String(data: prettyData, encoding: .utf8)
        {
           return jsonString
        }
        
        return String(data: data, encoding: .utf8) ?? "Error"
    }
}

public func getJsonAsync(from urlStr: String) async -> String? {
    guard let url = URL(string: urlStr) else {
        print("Невірна URL")
        return nil
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let tmp = String(data: data, encoding: .utf8)
        
        return tmp?.removingPercentEncoding ?? tmp
    } catch {
        print("Помилка запиту: \(error)")
        return nil
    }
}
