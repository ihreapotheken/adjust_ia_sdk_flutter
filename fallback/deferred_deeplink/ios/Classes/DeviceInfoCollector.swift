import UIKit
import CoreTelephony

class DeviceInfoCollector {

    func collect() -> [String: Any] {
        var info: [String: Any] = [:]

        // -- Device hardware --
        info["deviceModel"] = deviceModelIdentifier()
        info["deviceName"] = UIDevice.current.name
        info["systemName"] = UIDevice.current.systemName
        info["osVersion"] = UIDevice.current.systemVersion

        // -- Screen --
        let screen = UIScreen.main
        info["screenScale"] = screen.scale
        info["nativeBoundsWidth"] = screen.nativeBounds.width
        info["nativeBoundsHeight"] = screen.nativeBounds.height
        info["screenBoundsWidth"] = screen.bounds.width
        info["screenBoundsHeight"] = screen.bounds.height
        info["screenBrightness"] = screen.brightness

        // -- Locale / Language --
        info["preferredLanguages"] = Locale.preferredLanguages
        info["currentLocaleIdentifier"] = Locale.current.identifier
        info["currentLocaleLanguageCode"] = Locale.current.languageCode
        info["currentLocaleRegionCode"] = Locale.current.regionCode ?? ""

        // -- Keyboard languages --
        let keyboardLanguages = UITextInputMode.activeInputModes.compactMap {
            $0.primaryLanguage
        }
        info["keyboardLanguages"] = keyboardLanguages

        // -- Timezone --
        let tz = TimeZone.current
        info["timezoneIdentifier"] = tz.identifier
        info["timezoneAbbreviation"] = tz.abbreviation() ?? ""
        info["timezoneOffsetSeconds"] = tz.secondsFromGMT()

        // -- Carrier info (CTCarrier is deprecated in iOS 16.1 but still
        //    functional on deployment targets 12.0+) --
        let networkInfo = CTTelephonyNetworkInfo()
        if let carriers = networkInfo.serviceSubscriberCellularProviders,
           let firstCarrier = carriers.values.first {
            info["carrierName"] = firstCarrier.carrierName ?? ""
            info["mobileCountryCode"] = firstCarrier.mobileCountryCode ?? ""
            info["mobileNetworkCode"] = firstCarrier.mobileNetworkCode ?? ""
            info["isoCountryCode"] = firstCarrier.isoCountryCode ?? ""
        }

        // -- Disk space --
        if let attrs = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ) {
            if let totalSpace = attrs[.systemSize] as? Int64 {
                info["totalDiskSpaceBytes"] = totalSpace
            }
            if let freeSpace = attrs[.systemFreeSize] as? Int64 {
                info["freeDiskSpaceBytes"] = freeSpace
            }
        }

        // -- System uptime --
        info["systemUptimeSeconds"] = ProcessInfo.processInfo.systemUptime

        // -- Physical memory --
        info["physicalMemoryBytes"] = ProcessInfo.processInfo.physicalMemory

        // -- Processor count --
        info["processorCount"] = ProcessInfo.processInfo.processorCount
        info["activeProcessorCount"] = ProcessInfo.processInfo.activeProcessorCount

        // -- Battery --
        UIDevice.current.isBatteryMonitoringEnabled = true
        info["batteryLevel"] = UIDevice.current.batteryLevel
        info["batteryState"] = batteryStateString(UIDevice.current.batteryState)

        // -- Identifier for vendor --
        info["identifierForVendor"] = UIDevice.current.identifierForVendor?.uuidString ?? ""

        // -- User interface idiom --
        info["userInterfaceIdiom"] = idiomString(UIDevice.current.userInterfaceIdiom)

        // -- Low power mode --
        info["isLowPowerModeEnabled"] = ProcessInfo.processInfo.isLowPowerModeEnabled

        // -- Timestamps (comparable to JS Date.now() / new Date().toISOString()) --
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        info["deviceTimestampUTC"] = isoFormatter.string(from: now)
        info["deviceTimestampEpochMs"] = Int64(now.timeIntervalSince1970 * 1000)

        // -- Locale formatting (comparable to Intl.NumberFormat / Intl.DateTimeFormat) --
        let currentLocale = Locale.current
        info["decimalSeparator"] = currentLocale.decimalSeparator ?? ""
        info["groupingSeparator"] = currentLocale.groupingSeparator ?? ""
        info["currencyCode"] = currentLocale.currencyCode ?? ""
        info["currencySymbol"] = currentLocale.currencySymbol ?? ""
        info["calendarIdentifier"] = Calendar.current.identifier.debugDescription
        info["firstWeekday"] = Calendar.current.firstWeekday  // 1=Sunday in web, matches JS getDay()

        // -- Time format (comparable to Intl.DateTimeFormat resolvedOptions hour12) --
        let dateFormatter = DateFormatter()
        dateFormatter.locale = currentLocale
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let timeString = dateFormatter.string(from: now)
        let uses24Hour = !timeString.contains(dateFormatter.amSymbol)
            && !timeString.contains(dateFormatter.pmSymbol)
        info["uses24HourTime"] = uses24Hour

        // -- Metric system (comparable to navigator.language region conventions) --
        info["usesMetricSystem"] = currentLocale.usesMetricSystem

        // -- Dark/light mode (comparable to matchMedia prefers-color-scheme) --
        if #available(iOS 13.0, *) {
            let style = UITraitCollection.current.userInterfaceStyle
            switch style {
            case .dark: info["userInterfaceStyle"] = "dark"
            case .light: info["userInterfaceStyle"] = "light"
            default: info["userInterfaceStyle"] = "unspecified"
            }
        }

        // -- Accessibility font size (comparable to browser font-size / zoom) --
        info["contentSizeCategory"] = UIApplication.shared.preferredContentSizeCategory.rawValue

        // -- Device orientation (comparable to screen.orientation) --
        let orientation = UIDevice.current.orientation
        info["deviceOrientation"] = orientationString(orientation)

        // -- Network type (comparable to navigator.connection.effectiveType) --
        let netInfo = CTTelephonyNetworkInfo()
        if let radioType = netInfo.serviceCurrentRadioAccessTechnology?.values.first {
            info["currentRadioAccessTechnology"] = radioType
        }

        // -- Accessibility --
        info["isVoiceOverRunning"] = UIAccessibility.isVoiceOverRunning
        info["isSwitchControlRunning"] = UIAccessibility.isSwitchControlRunning
        info["isClosedCaptioningEnabled"] = UIAccessibility.isClosedCaptioningEnabled
        info["isReduceMotionEnabled"] = UIAccessibility.isReduceMotionEnabled
        info["isReduceTransparencyEnabled"] = UIAccessibility.isReduceTransparencyEnabled
        info["isBoldTextEnabled"] = UIAccessibility.isBoldTextEnabled
        info["isGrayscaleEnabled"] = UIAccessibility.isGrayscaleEnabled
        info["isInvertColorsEnabled"] = UIAccessibility.isInvertColorsEnabled
        info["isMonoAudioEnabled"] = UIAccessibility.isMonoAudioEnabled
        if #available(iOS 13.0, *) {
            info["shouldDifferentiateWithoutColor"] = UIAccessibility.shouldDifferentiateWithoutColor
        }

        // -- Thermal state --
        info["thermalState"] = thermalStateString(ProcessInfo.processInfo.thermalState)

        // -- System boot time (derived: current time - uptime) --
        let bootTimestamp = Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
        info["systemBootTimeEpochMs"] = Int64(bootTimestamp * 1000)

        // -- Multitasking --
        info["isMultitaskingSupported"] = UIDevice.current.isMultitaskingSupported

        // -- Screen max refresh rate (ProMotion) --
        if #available(iOS 15.0, *) {
            info["screenMaximumFramesPerSecond"] = UIScreen.main.maximumFramesPerSecond
        }

        // -- Number of available locales --
        info["availableLocalesCount"] = Locale.availableIdentifiers.count

        // -- App / process info --
        let processInfo = ProcessInfo.processInfo
        info["processName"] = processInfo.processName
        info["hostName"] = processInfo.hostName
        info["operatingSystemVersionString"] = processInfo.operatingSystemVersionString

        return info
    }

    // MARK: - Private helpers

    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
    }

    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .unplugged: return "unplugged"
        case .charging: return "charging"
        case .full: return "full"
        @unknown default: return "unknown"
        }
    }

    private func orientationString(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portraitUpsideDown"
        case .landscapeLeft: return "landscapeLeft"
        case .landscapeRight: return "landscapeRight"
        case .faceUp: return "faceUp"
        case .faceDown: return "faceDown"
        default: return "unknown"
        }
    }

    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    private func idiomString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone: return "phone"
        case .pad: return "pad"
        case .tv: return "tv"
        case .carPlay: return "carPlay"
        case .mac: return "mac"
        @unknown default: return "unknown"
        }
    }
}
