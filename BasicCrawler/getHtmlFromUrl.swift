
import Foundation
import Essentials

func getHtmlAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> String {
    guard let url = URL(string: urlStr) else { throw WTF("Wrong URL") }
    
    let session = createSession(cookies: cookies)
    
    let (data, _) = try await session.data(from: url)
    
    if let tmp = String(data: data, encoding: .utf8) {
        return tmp.removingPercentEncoding ?? tmp
    }
    
    throw WTF("Failed to get json string from data")
}

func getHtmlFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
    return Flow.Future {
        try await getHtmlAsync(from: urlStr, cookies: cookies)
    }
}
