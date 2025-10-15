
import Foundation
import AppKit
import Essentials

struct AsyncToSync {
    /// ```
    /// //Sample of usage (try/throws)
    ///
    /// let html = getSyncResultFrom {
    ///    let loader = await MyInternetLoader()
    ///
    ///    return try? await loader.getHTML(from: URL(string: url)!)
    /// }
    /// ```
    @available(macOS 10.15, *)
    static func getFrom<T>(@_implicitSelfCapture _ operation: @Sendable @escaping () async throws -> T) throws -> T {
        try RunBlocking().runBlocking(operation)
    }
}

//
// Helpers
//

@available(macOS 10.15, *)
fileprivate final class RunBlocking<T, Failure: Error> {
    fileprivate var value: Result<T, Failure>? = nil
}

@available(macOS 10.15, *)
extension RunBlocking where Failure == Error {
    func runBlocking(_ operation: @Sendable @escaping () async throws -> T) throws -> T {
        let box = Box<Result<T, Error>>()
        
        Task {
            do { box.value = .success(try await operation()) }
            catch { box.value = .failure(error) }
        }
        
        let runLoop = RunLoop.current
        runLoop.add(Port(), forMode: .default)
        
        while box.value == nil {
            runLoop.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }
        
        switch box.value! {
            case .success(let v): return v
            case .failure(let e): throw e
        }
    }
}

fileprivate final class Box<T> {
    private let lock = NSLock()
    private var _value: T?
    
    var value: T? {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }
}
