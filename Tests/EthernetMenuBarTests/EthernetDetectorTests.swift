import Testing
@testable import EthernetMenuBar

struct EthernetDetectorTests {
    @Test func detectsAnActive25GigabitAdapter() {
        let runner = CommandRunner { executable, arguments in
            guard executable == "/sbin/ifconfig", arguments == ["en7"] else { return nil }
            return """
            en7: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST>
                media: autoselect (2500Base-T <full-duplex>)
                status: active
            """
        }
        let detector = EthernetDetector(runner: runner, interfaceNames: { ["en7"] })

        #expect(detector.activeConnection() == EthernetConnection(interfaceName: "en7", speedLabel: "2.5G"))
    }

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
