
import WebKit

extension URLResponse {
    func getStatusCode() -> Int? {
        if let httpResponse = self as? HTTPURLResponse {
            return httpResponse.statusCode
        }
        
        return nil
    }
    
    func isResponseOK() -> Bool {
        guard let statusCode = getStatusCode() else { return false } //fatalError() }
        
        return (200...299).contains(statusCode)
    }
}
