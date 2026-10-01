import XCTest
import UIKit

/// The host wrapper changes Simulator state; the UI test only exchanges files
/// inside its own container. No app font override or Settings slider is used.
final class SystemSizeSession {
    struct Readback: Decodable {
        let ok: Bool
        let error: String?
        let pid: Int?
        let originalSize: String?
        let originalCategory: String?
        let systemSize: String?
        let applicationCategory: String?
        let windowCategory: String?
    }

    private let session = UUID().uuidString
    private let directory: URL
    private let test: String
    private(set) var pid = 0
    private(set) var originalSize = ""
    private var originalCategory = ""
    private(set) var restored = false
    private(set) var lastRestoration: Readback?

    init(test: String) throws {
        self.test = test
        directory = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
            .appendingPathComponent("RunBuoySystemSizeControl", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let snapshot = try request("begin")
        pid = try XCTUnwrap(snapshot.pid)
        originalSize = try XCTUnwrap(snapshot.originalSize)
        originalCategory = try XCTUnwrap(snapshot.originalCategory)
        print("SYSTEM SIZE SNAPSHOT pid=\(pid) size=\(originalSize)")
    }

    func set(_ size: String, expected: UIContentSizeCategory) throws {
        let result = try request("set", category: size)
        verify(result, size: size, category: expected.rawValue)
    }

    func restore() throws {
        if restored { return }
        let result = try request("restore")
        verify(result, size: originalSize, category: originalCategory)
        lastRestoration = result
        restored = true
        print("SYSTEM SIZE RESTORED pid=\(pid) size=\(originalSize)")
    }

    private func verify(_ result: Readback, size: String, category: String) {
        XCTAssertEqual(result.pid, pid, "App PID must remain unchanged")
        XCTAssertEqual(result.systemSize, size)
        XCTAssertEqual(result.applicationCategory, category)
        XCTAssertEqual(result.windowCategory, category)
    }

    private func request(_ action: String, category: String? = nil) throws -> Readback {
        let identifier = UUID().uuidString
        let requestURL = directory.appendingPathComponent("\(identifier).request.json")
        let responseURL = directory.appendingPathComponent("\(identifier).response.json")
        var value = ["session": session, "test": test, "action": action]
        if let category { value["category"] = category }
        try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
            .write(to: requestURL, options: .atomic)
        let responseExists = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            FileManager.default.fileExists(atPath: responseURL.path)
        }, object: nil)
        guard XCTWaiter.wait(for: [responseExists], timeout: action == "begin" ? 20 : 100) == .completed else {
            throw NSError(domain: "RunBuoySystemSize", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Host size controller did not respond. Run xcodebuild through scripts/run_ios_system_size_tests.py; no setting was assumed to succeed."
            ])
        }
        let data = try Data(contentsOf: responseURL)
        print("SYSTEM SIZE HOST READBACK \(String(decoding: data, as: UTF8.self))")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(Readback.self, from: data)
        guard result.ok else {
            throw NSError(domain: "RunBuoySystemSize", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: result.error ?? "Unknown host error"])
        }
        return result
    }
}
