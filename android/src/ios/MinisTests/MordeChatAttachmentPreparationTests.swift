import ImageIO
import PDFKit
import UIKit
import XCTest
@testable import Minis

@MainActor
final class MordeChatAttachmentPreparationTests: XCTestCase {
    func testProjectDerivativeRequestIsPersistedForExactReplay() throws {
        let text = Data("Synthetic local PDF text".utf8)
        let file = MordeProjectDerivativeFile(kind: "extracted_text", page: 0, name: "text.txt",
            media_type: "text/plain", sha256: MordeMessageChunking.digest(text), content_base64: text.base64EncodedString())
        let payload = try XCTUnwrap(MordeProjectDerivativeRequest(outcome: "completed", files: [file]).encoded(mode: "pdf"))
        let path = try MordeChatAttachmentPreparation.stageDerivativeRequest(payload)
        defer { MordeChatAttachmentPreparation.discardStagedFiles([path]) }
        let original = MordeOutboxAttachment(id: UUID().uuidString.lowercased(), attachmentID: nil,
            linked: true, derivedAssociationPending: true, projectDerivativeMode: "pdf",
            projectDerivativePayloadPath: path, projectDerivativePayloadDigest: MordeMessageChunking.digest(payload))
        let restored = try JSONDecoder().decode(MordeOutboxAttachment.self, from: JSONEncoder().encode(original))
        let savedPath = try XCTUnwrap(restored.projectDerivativePayloadPath)
        XCTAssertTrue(MordeChatAttachmentPreparation.validStagedPath(savedPath))
        let saved = try Data(contentsOf: URL(fileURLWithPath: savedPath))
        XCTAssertEqual(saved, payload)
        XCTAssertEqual(MordeMessageChunking.digest(saved), restored.projectDerivativePayloadDigest)
        XCTAssertEqual(try JSONDecoder().decode(MordeProjectDerivativeRequest.self, from: saved).encoded(mode: "pdf"), payload)
    }

    func testProjectAttachmentMetadataRejectsCrossScopeAndInvalidContent() {
        let projectID = "pca_" + String(repeating: "a", count: 32)
        let personalID = "pa_" + String(repeating: "a", count: 32)
        let digest = String(repeating: "b", count: 64)
        let valid = MordeProjectAttachmentMetadata(attachment_id: projectID, name: "local.pdf",
            media_type: "application/pdf", size_bytes: 42, sha256: digest)
        XCTAssertTrue(valid.isValid(for: projectID))
        XCTAssertFalse(valid.isValid(for: personalID))
        XCTAssertFalse(MordeProjectAttachmentMetadata(attachment_id: personalID, name: "local.pdf",
            media_type: "application/pdf", size_bytes: 42, sha256: digest).isValid(for: personalID))
        XCTAssertFalse(MordeProjectAttachmentMetadata(attachment_id: projectID, name: "../local.pdf",
            media_type: "application/pdf", size_bytes: 42, sha256: digest).isValid(for: projectID))
        XCTAssertFalse(MordeProjectAttachmentMetadata(attachment_id: projectID, name: "local.pdf",
            media_type: "application/pdf", size_bytes: MordeProjectAttachmentContract.maxBytes + 1,
            sha256: digest).isValid(for: projectID))
        XCTAssertFalse(MordeProjectAttachmentMetadata(attachment_id: projectID, name: "local.pdf",
            media_type: "application/pdf", size_bytes: 42, sha256: "not-a-digest").isValid(for: projectID))
        let nameAtLimit = String(repeating: "文", count: 85)
        XCTAssertEqual(nameAtLimit.utf8.count, 255)
        XCTAssertTrue(MordeProjectAttachmentMetadata(attachment_id: projectID, name: nameAtLimit,
            media_type: "application/pdf", size_bytes: 42, sha256: digest).isValid(for: projectID))
        XCTAssertFalse(MordeProjectAttachmentMetadata(attachment_id: projectID, name: nameAtLimit + "a",
            media_type: "application/pdf", size_bytes: 42, sha256: digest).isValid(for: projectID))
        let overlongFilename = String(repeating: "文", count: 84) + ".pdf"
        XCTAssertEqual(overlongFilename.utf8.count, 256)
        XCTAssertEqual(MordeChatAttachmentPreparation.stagingFilename(overlongFilename, index: 3), "attachment-3.pdf")
    }

    func testSelectedFilesAreStagedLocallyAndCanBeRecovered() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("fixture.docx")
        let bytes = Data("local-only-attachment".utf8)
        try bytes.write(to: source)
        let planned = try MordeChatAttachmentPreparation.planSources([source])
        XCTAssertEqual(planned.count, 1)
        let restored = try JSONDecoder().decode(MordeOutboxAttachment.self, from: JSONEncoder().encode(planned[0]))
        let path = try XCTUnwrap(restored.localPath)
        defer { MordeChatAttachmentPreparation.discardStagedFiles([path]) }
        XCTAssertFalse(MordeChatAttachmentPreparation.validStagedPath(path))
        XCTAssertEqual(try MordeChatAttachmentPreparation.ensureStagedSource(restored).path, path)
        XCTAssertTrue(MordeChatAttachmentPreparation.validStagedPath(path))
        try FileManager.default.removeItem(at: source)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), bytes)
        XCTAssertEqual(try MordeChatAttachmentPreparation.ensureStagedSource(restored).path, path)
        XCTAssertFalse(MordeChatAttachmentPreparation.validStagedPath(directory.path))
        var renamed = restored
        renamed.originalFilename = String(repeating: "文", count: 84) + ".docx"
        let recovered = try JSONDecoder().decode(MordeOutboxAttachment.self, from: JSONEncoder().encode(renamed))
        XCTAssertEqual(recovered.originalFilename, renamed.originalFilename)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: try XCTUnwrap(recovered.localPath))), bytes)
    }

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

    func testScannedPDFReportsUnreadPagesBeyondPreviewLimit() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("scanned-local-fixture.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 240, height: 180))
        let data = renderer.pdfData { context in
            for _ in 0..<12 {
                context.beginPage()
                UIColor.darkGray.setFill()
                context.cgContext.fill(CGRect(x: 10, y: 10, width: 200, height: 150))
            }
        }
        try data.write(to: source)
        let prepared = try MordeChatAttachmentPreparation.prepare(source)
        defer { prepared.discardTemporaryFiles() }
        XCTAssertEqual(prepared.files.count, 12, "The source, text summary, and at most 10 previews remain local.")
        let extracted = try Data(contentsOf: prepared.files[1].url)
        XCTAssertLessThanOrEqual(extracted.count, 48 * 1024)
        let summary = try XCTUnwrap(String(data: extracted, encoding: .utf8))
        XCTAssertTrue(summary.contains("未发现可选择文本"))
        XCTAssertTrue(summary.contains("前 10 页"))
        XCTAssertTrue(summary.contains("共 12 页"))
        XCTAssertTrue(summary.contains("其余页面未读取"))
        XCTAssertFalse(summary.contains("--- Page"))
    }

    func testOfficeAttachmentsKeepOriginalBytesAndUseOOXMLMediaTypes() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let payload = Data("local synthetic office fixture".utf8)
        let cases = [
            ("report.DOCX", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
            ("sheet.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        ]
        for (name, mediaType) in cases {
            let source = directory.appendingPathComponent(name)
            try payload.write(to: source)
            let prepared = try MordeChatAttachmentPreparation.prepare(source)
            XCTAssertEqual(prepared.name, name)
            XCTAssertEqual(prepared.files.map(\.url), [source])
            XCTAssertNil(prepared.temporaryDirectory)
            XCTAssertEqual(MordeChatAttachmentPreparation.uploadMediaType(for: source), mediaType)
            prepared.discardTemporaryFiles()
            XCTAssertEqual(try Data(contentsOf: source), payload)
        }
        XCTAssertTrue(MordeChatAttachmentPreparation.importContentTypes.contains {
            $0.identifier == "org.openxmlformats.wordprocessingml.document"
        })
        XCTAssertTrue(MordeChatAttachmentPreparation.importContentTypes.contains {
            $0.identifier == "org.openxmlformats.spreadsheetml.sheet"
        })
    }

    func testUnsupportedOfficeAndArchiveTypesAreRejected() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        for fileExtension in ["doc", "xls", "docm", "xlsm", "zip", "bin"] {
            let source = directory.appendingPathComponent("fixture.\(fileExtension)")
            try Data("unsupported".utf8).write(to: source)
            XCTAssertNil(MordeChatAttachmentPreparation.uploadMediaType(for: source), fileExtension)
            XCTAssertThrowsError(try MordeChatAttachmentPreparation.prepare(source), fileExtension) { error in
                XCTAssertEqual((error as NSError).code, 415)
            }
        }
        XCTAssertEqual(MordeChatAttachmentPreparation.uploadMediaType(for: directory.appendingPathComponent("page.jpg")), "image/jpeg")
        XCTAssertEqual(MordeChatAttachmentPreparation.uploadMediaType(for: directory.appendingPathComponent("page.png")), "image/png")
        XCTAssertEqual(MordeChatAttachmentPreparation.uploadMediaType(for: directory.appendingPathComponent("source.pdf")), "application/pdf")
        XCTAssertEqual(MordeChatAttachmentPreparation.uploadMediaType(for: directory.appendingPathComponent("pdf-text.txt")), "text/plain")
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
