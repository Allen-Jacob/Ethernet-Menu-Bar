import Testing
@testable import EthernetMenuBar

struct EthernetDetectorTests {
    @Test func parsesCommonLinkSpeeds() {
        #expect(EthernetDetector.speedLabel(from: "media: autoselect (2500base-T <full-duplex>)") == "2.5G")
        #expect(EthernetDetector.speedLabel(from: "media: autoselect (1000baseT <full-duplex>)") == "1G")
        #expect(EthernetDetector.speedLabel(from: "media: autoselect (100baseTX <full-duplex>)") == "100M")
    }

    @Test func recognizesOnlyActiveStatus() {
        #expect(EthernetDetector.isActive(ifconfigOutput: "\tstatus: active\n"))
        #expect(!EthernetDetector.isActive(ifconfigOutput: "\tstatus: inactive\n"))
    }
}
