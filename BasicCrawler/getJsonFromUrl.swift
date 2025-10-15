
import Foundation
import Essentials

func getJsonAsync(from urlStr: String, cookies: [HTTPCookie]) async throws -> String {
    guard let url = URL(string: urlStr) else { throw WTF("Wrong URL") }
    
    let session = createSession(cookies: cookies)
    
    let (data, _) = try await session.data(from: url)
    
    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
       let jsonString = String(data: prettyData, encoding: .utf8)
    {
       return jsonString.removingPercentEncoding ?? jsonString
    }
    
    throw WTF("Failed to get json string from data")
}
