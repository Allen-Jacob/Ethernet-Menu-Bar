import Foundation
import SystemConfiguration

struct EthernetConnection: Equatable {
    let interfaceName: String
    let speedLabel: String
}

struct CommandRunner {
    var run: (_ executable: String, _ arguments: [String]) -> String? = { executable, arguments in
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        } catch {
            return nil
        }
    }
}

struct EthernetDetector {
    private let runner: CommandRunner
    private let interfaceNames: () -> [String]

    init(
        runner: CommandRunner = CommandRunner(),
        interfaceNames: @escaping () -> [String] = EthernetDetector.ethernetInterfaceNames
    ) {
        self.runner = runner
        self.interfaceNames = interfaceNames
    }

    func activeConnection() -> EthernetConnection? {
        for interface in interfaceNames() {
            guard let details = runner.run("/sbin/ifconfig", [interface]),
                  Self.isActive(ifconfigOutput: details) else { continue }

            return EthernetConnection(
                interfaceName: interface,
                speedLabel: Self.speedLabel(from: details) ?? "LAN"
            )
        }
        return nil
    }

    static func ethernetInterfaceNames() -> [String] {
        let interfaces = SCNetworkInterfaceCopyAll() as NSArray
        var names: [String] = []
        for case let interface as SCNetworkInterface in interfaces {
            guard SCNetworkInterfaceGetInterfaceType(interface) == kSCNetworkInterfaceTypeEthernet,
                  let name = SCNetworkInterfaceGetBSDName(interface) else { continue }
            names.append(name as String)
        }
        return names
    }

    static func isActive(ifconfigOutput: String) -> Bool {
        ifconfigOutput.range(
            of: #"(?m)^\s*status:\s*active\s*$"#,
            options: .regularExpression
        ) != nil
    }

    static func speedLabel(from output: String) -> String? {
        let patterns: [(String, String)] = [
            (#"(?i)\b(10Gbase|10000base)"#, "10G"),
            (#"(?i)\b(5Gbase|5000base)"#, "5G"),
            (#"(?i)\b(2\.5Gbase|2500base)"#, "2.5G"),
            (#"(?i)\b(1Gbase|1000base)"#, "1G"),
            (#"(?i)\b(100base)"#, "100M"),
            (#"(?i)\b(10base)"#, "10M")
        ]
        return patterns.first(where: { output.range(of: $0.0, options: .regularExpression) != nil })?.1
    }
}
