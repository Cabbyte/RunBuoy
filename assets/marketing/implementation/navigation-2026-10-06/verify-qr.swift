import Foundation
import Vision
let url = URL(fileURLWithPath: CommandLine.arguments[1])
let request = VNDetectBarcodesRequest()
request.symbologies = [.qr]
try VNImageRequestHandler(url: url).perform([request])
let values = (request.results ?? []).compactMap(\.payloadStringValue)
guard values == ["https://apps.apple.com/cn/app/runbuoy/id6795591930"] else { fatalError("QR payload mismatch: \(values)") }
print("Decoded App Store QR: \(values[0])")
