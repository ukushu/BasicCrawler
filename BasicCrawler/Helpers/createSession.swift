
import Foundation

func createSession(cookies: [HTTPCookie]) -> URLSession {
    let config = URLSessionConfiguration.default
    config.headers = [ "User-Agent": userAgentsList.randomElement()! ]
    
    let cookieStorage = HTTPCookieStorage()
    for c in cookies {
        cookieStorage.setCookie(c)
    }
    config.httpCookieStorage = cookieStorage
    
    let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    
    return session
}
