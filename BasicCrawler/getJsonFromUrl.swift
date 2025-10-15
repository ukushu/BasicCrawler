
import Foundation
import Essentials

func getJsonAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> String {
    guard let url = URL(string: urlStr) else {
        throw WTF("Wrong URL")
    }
    
    let session = createSession(cookies: cookies)
    
    let (data, _) = try await session.data(from: url)
    
    if let tmp = String(data: data, encoding: .utf8) {
        return tmp.removingPercentEncoding ?? tmp
    }
    
    throw WTF("Failed to get json string from data")
}

func getJsonFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
    guard let url = URL(string: urlStr) else {
        return .failed(WTF("Wrong URL"))
    }
    
    return Flow.Future {
        let session = createSession(cookies: cookies)
        
        let (data, _) = try await session.data(from: url)
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let jsonString = String(data: prettyData, encoding: .utf8)
        {
           return jsonString
        }
        
        if let tmp = String(data: data, encoding: .utf8) {
            return tmp.removingPercentEncoding ?? tmp
        }
        
        throw WTF("Failed to get json string from data")
    }
}
