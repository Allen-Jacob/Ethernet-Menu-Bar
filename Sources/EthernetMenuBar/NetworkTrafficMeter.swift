import Foundation
import Darwin

struct NetworkTraffic: Equatable {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double

    static let zero = NetworkTraffic(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
}

struct InterfaceCounters: Equatable {
    let receivedBytes: UInt64
    let sentBytes: UInt64
}

struct NetworkTrafficMeter {
    private var previous: (interface: String, counters: InterfaceCounters, date: Date)?
    private var readCounters: (String) -> InterfaceCounters?

    init(readCounters: @escaping (String) -> InterfaceCounters? = Self.interfaceCounters) {
        self.readCounters = readCounters
    }

    mutating func sample(interface: String, at date: Date = Date()) -> NetworkTraffic {
        guard let counters = readCounters(interface) else {
            previous = nil
            return .zero
        }
        defer { previous = (interface, counters, date) }

        guard let previous,
              previous.interface == interface,
              date > previous.date,
              counters.receivedBytes >= previous.counters.receivedBytes,
              counters.sentBytes >= previous.counters.sentBytes else {
            return .zero
        }

        let elapsed = date.timeIntervalSince(previous.date)
        return NetworkTraffic(
            downloadBytesPerSecond: Double(counters.receivedBytes - previous.counters.receivedBytes) / elapsed,
            uploadBytesPerSecond: Double(counters.sentBytes - previous.counters.sentBytes) / elapsed
        )
    }

    mutating func reset() {
        previous = nil
    }

    private static func interfaceCounters(named wantedName: String) -> InterfaceCounters? {
        var firstAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddress) == 0 else { return nil }
        defer { freeifaddrs(firstAddress) }

        var address = firstAddress
        while let current = address {
            let entry = current.pointee
            if String(cString: entry.ifa_name) == wantedName,
               entry.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let rawData = entry.ifa_data {
                let data = rawData.assumingMemoryBound(to: if_data.self).pointee
                return InterfaceCounters(
                    receivedBytes: UInt64(data.ifi_ibytes),
                    sentBytes: UInt64(data.ifi_obytes)
                )
            }
            address = entry.ifa_next
        }
        return nil
    }
}

enum TrafficFormatter {
    static func string(bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.includesUnit = true
        formatter.includesCount = true
        formatter.isAdaptive = true
        let value = formatter.string(fromByteCount: Int64(max(0, bytesPerSecond)))
        return "\(value)/s"
    }
}
