
import Foundation
import Essentials

func getHtmlFuture(from urlStr: String, cookies: [HTTPCookie]) -> Flow.Future<String> {
    guard let url = URL(string: urlStr) else {
        return .failed( WTF("Wrong URL") )
    }
    
    return Flow.Future {
        let session = createSession(cookies: cookies)
        
        let (data, _) = try await session.data(from: url)
        
        if let tmp = String(data: data, encoding: .utf8) {
            return tmp.removingPercentEncoding ?? tmp
        }
        
        throw WTF("Failed to get json string from data")
    }
}
