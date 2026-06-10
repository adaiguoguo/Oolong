import Foundation
import IOKit.ps

/// 原生采集系统状态。CPU 需要保存上一次 tick 快照做差值。
final class SystemStatsService {
    private var lastCPUTicks: host_cpu_load_info?

    func sample() -> SystemStats {
        var s = SystemStats()
        s.uptime = ProcessInfo.processInfo.systemUptime
        s.cpuPercent = cpuPercent()
        let mem = memory()
        s.memoryUsedBytes = mem.used
        s.memoryTotalBytes = mem.total
        let bat = battery()
        s.batteryPercent = bat.percent
        s.isCharging = bat.charging
        s.hasBattery = bat.percent != nil
        return s
    }

    // MARK: - CPU

    private func cpuPercent() -> Double {
        guard let cur = hostCPULoadInfo() else { return 0 }
        defer { lastCPUTicks = cur }
        guard let prev = lastCPUTicks else { return 0 }

        let user = Double(cur.cpu_ticks.0 &- prev.cpu_ticks.0)
        let system = Double(cur.cpu_ticks.1 &- prev.cpu_ticks.1)
        let idle = Double(cur.cpu_ticks.2 &- prev.cpu_ticks.2)
        let nice = Double(cur.cpu_ticks.3 &- prev.cpu_ticks.3)
        let used = user + system + nice
        let total = used + idle
        guard total > 0 else { return 0 }
        return (used / total) * 100
    }

    private func hostCPULoadInfo() -> host_cpu_load_info? {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info : nil
    }

    // MARK: - 内存 (近似 Activity Monitor 的 "已用内存")

    private func memory() -> (used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize = UInt64(vm_kernel_page_size)
        let appMemory = UInt64(stats.internal_page_count) &- UInt64(stats.purgeable_count)
        let wired = UInt64(stats.wire_count)
        let compressed = UInt64(stats.compressor_page_count)
        let usedPages = appMemory &+ wired &+ compressed
        return (usedPages &* pageSize, total)
    }

    // MARK: - 电池 (IOKit)

    private func battery() -> (percent: Int?, charging: Bool) {
        guard let snap = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snap)?.takeRetainedValue() as? [CFTypeRef]
        else { return (nil, false) }

        for src in sources {
            guard let desc = IOPSGetPowerSourceDescription(snap, src)?.takeUnretainedValue() as? [String: Any]
            else { continue }
            guard let type = desc[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType else { continue }
            let cur = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let pct = max > 0 ? min(100, Swift.max(0, Int((Double(cur) / Double(max) * 100).rounded()))) : nil
            let state = desc[kIOPSPowerSourceStateKey] as? String
            let charging = (desc[kIOPSIsChargingKey] as? Bool) ?? (state == kIOPSACPowerValue)
            return (pct, charging)
        }
        return (nil, false)
    }
}
