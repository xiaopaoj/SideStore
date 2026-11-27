import Foundation
import XCTest
import CodeSignKit
@testable import SideSign
final class OSRecoveryTests: XCTestCase {
    func testOverflowLengthRejectedWithoutTrap() {
        XCTAssertNil(ASN1Helper.parseTLV(from: Data([0x30, 0x88] + Array(repeating: 0xff, count: 8))))
        XCTAssertNil(ASN1Helper.parseTLV(from: Data([0x30, 0x88, 0x7f] + Array(repeating: 0xff, count: 7))))
    }
    func testInvalidOffsetsAndTruncation() {
        XCTAssertNil(ASN1Helper.parseTLV(from: Data([0x30, 0x00]), at: -1))
        XCTAssertNil(ASN1Helper.parseTLV(from: Data([0x30, 0x00]), at: Int.max))
        let samples: [[UInt8]] = [[], [0x30], [0x30, 0x80], [0x30, 0x82, 0x01], [0x30, 0x03, 0x01]]
        for bytes in samples {
            XCTAssertNil(ASN1Helper.parseTLV(from: Data(bytes)))
        }
    }
    func testValidDERAndNonZeroBasedData() throws {
        let short = Data([0x04, 0x02, 0xaa, 0xbb])
        XCTAssertEqual(try XCTUnwrap(ASN1Helper.parseTLV(from: short)).value, Data([0xaa, 0xbb]))
        let long = Data([0x04, 0x81, 0x80] + Array(repeating: 0xaa, count: 128))
        XCTAssertEqual(try XCTUnwrap(ASN1Helper.parseTLV(from: long)).totalLength, 131)
        let sliced = Data([0xff, 0x04, 0x01, 0xaa]).dropFirst()
        XCTAssertEqual(try XCTUnwrap(ASN1Helper.parseTLV(from: sliced)).value, Data([0xaa]))
    }
    func testMalformedP12ThrowsInsteadOfCrashing() {
        XCTAssertThrowsError(try SideSign.PKCS12Parser.extract(Data([0x30, 0x88] + Array(repeating: 0xff, count: 8)), password: "wrong"))
    }
    func testDeterministicMalformedDERCorpus() {
        var state: UInt64 = 42
        for size in 0..<96 {
            for _ in 0..<32 {
                let bytes = (0..<size).map { _ -> UInt8 in
                    state = state &* 6364136223846793005 &+ 1
                    return UInt8(truncatingIfNeeded: state >> 24)
                }
                if let result = ASN1Helper.parseTLV(from: Data(bytes)) {
                    XCTAssertGreaterThanOrEqual(result.totalLength, 2)
                    XCTAssertLessThanOrEqual(result.totalLength, size)
                }
            }
        }
    }
}
