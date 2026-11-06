import ImageIO
import PDFKit
import UIKit
import XCTest
@testable import Minis

@MainActor
final class MordeChatAttachmentPreparationTests: XCTestCase {
    func testImageIsNormalizedToAReadableJPEG() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("fixture.png")
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1800, height: 900), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1800, height: 900))
        }
        try XCTUnwrap(image.pngData()).write(to: source)

        let prepared = try MordeChatAttachmentPreparation.prepare(source)
        defer { prepared.discardTemporaryFiles() }
        XCTAssertEqual(prepared.name, "fixture.jpg")
        XCTAssertEqual(prepared.files.count, 1)
        let outputURL = prepared.files[0].url
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
        XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 1280)
        XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 640)
        XCTAssertLessThanOrEqual(try Data(contentsOf: outputURL).count, 512 * 1024)
    }

    func testPDFProducesExtractedTextAndPageJPEG() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("fixture.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 320, height: 200))
        let data = renderer.pdfData { context in
            context.beginPage()
            ("Morde PDF fixture text" as NSString).draw(at: CGPoint(x: 24, y: 32),
                withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
        }
        try data.write(to: source)

        let prepared = try MordeChatAttachmentPreparation.prepare(source)
        defer { prepared.discardTemporaryFiles() }
        XCTAssertEqual(prepared.name, "fixture.pdf")
        XCTAssertEqual(prepared.files.count, 3)
        XCTAssertEqual(prepared.files[0].url, source)
        XCTAssertTrue(prepared.files[1].url.lastPathComponent.hasPrefix("morde-解析-"))
        let extractedText = try String(contentsOf: prepared.files[1].url, encoding: .utf8)
        XCTAssertTrue(extractedText.contains("Morde PDF fixture text"))
        let preview = try XCTUnwrap(CGImageSourceCreateWithURL(prepared.files[2].url as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(preview, 0, nil) as? [CFString: Any])
        XCTAssertLessThanOrEqual(properties[kCGImagePropertyPixelWidth] as? Int ?? .max, 1280)
        XCTAssertLessThanOrEqual(properties[kCGImagePropertyPixelHeight] as? Int ?? .max, 720)
        XCTAssertLessThanOrEqual(try Data(contentsOf: prepared.files[2].url).count, 512 * 1024)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
