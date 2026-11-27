import XCTest
@testable import FWOSRecovery
final class RecoveryTests: XCTestCase {
    func testRecentlyLockedIsNotInvalidTrust() {
        XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "invalid pairing file: device has not been unlocked recently"), .unlockPhone)
    }
    func testExtendedError1016() {
        XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "missing createListener.port: com.apple.dt.RemotePairingError Code=1016"), .unlockPhone)
    }
    func testBare1016DoesNotMisclassify() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "HTTP 1016"), .unknown) }
    func testUnlockMarkerSurvivesWrapping() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: FWOSRecoveryAdvice.unlockPhone.instruction), .unlockPhone) }
    func testActualVerificationFailure() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "PairVerifyFailed"), .pairing) }
    func testNetworkRefusalIsNotInvalidTrust() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "connection refused"), .network) }
    func testAppleAuthenticationNotClassifiedAsPairing() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "HTTP 401 Apple PTM/TK ADI -45063"), .unknown) }
    func testMissingListenerWithoutCauseIsUnknown() { XCTAssertEqual(FWOSRecoveryAdvice.classify(message: "missing createListener.port"), .unknown) }
    func testFirstRunIsNotAnUpgrade() { XCTAssertFalse(FWOSRecoveryAdvice.osChanged(previous: nil, current: "Version 27.2.1 (Build A)")) }
    func testSameVersionIsNotAnUpgrade() { XCTAssertFalse(FWOSRecoveryAdvice.osChanged(previous: "A", current: "A")) }
    func testFutureVersionAndBuildChanges() {
        XCTAssertTrue(FWOSRecoveryAdvice.osChanged(previous: "27.2.1 A", current: "28.0 B"))
        XCTAssertTrue(FWOSRecoveryAdvice.osChanged(previous: "27.2.1 A", current: "27.2.1 B"))
    }
    func testAdviceDoesNotExposeRawError() {
        let secret = "private-device-private-account"
        XCTAssertFalse(FWOSRecoveryAdvice.classify(message: "PairVerifyFailed " + secret).instruction.contains(secret))
    }
}
