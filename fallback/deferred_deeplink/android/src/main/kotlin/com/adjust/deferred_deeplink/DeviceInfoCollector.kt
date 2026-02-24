package com.adjust.deferred_deeplink

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import android.os.SystemClock
import android.provider.Settings
import android.telephony.TelephonyManager
import android.text.format.DateFormat
import android.util.DisplayMetrics
import android.view.WindowManager
import android.view.accessibility.AccessibilityManager
import java.text.DecimalFormatSymbols
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Currency
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class DeviceInfoCollector(private val context: Context) {

    fun collect(): Map<String, Any?> {
        val info = HashMap<String, Any?>()

        // -- Device hardware --
        info["deviceModel"] = Build.MODEL
        info["deviceName"] = Build.DEVICE
        info["manufacturer"] = Build.MANUFACTURER
        info["brand"] = Build.BRAND
        info["product"] = Build.PRODUCT
        info["board"] = Build.BOARD
        info["hardware"] = Build.HARDWARE
        info["systemName"] = "Android"
        info["osVersion"] = Build.VERSION.RELEASE
        info["apiLevel"] = Build.VERSION.SDK_INT

        // -- Screen --
        collectScreenInfo(info)

        // -- Locale / Language --
        collectLocaleInfo(info)

        // -- Keyboard languages --
        collectKeyboardLanguages(info)

        // -- Timezone --
        collectTimezoneInfo(info)

        // -- Carrier info --
        collectCarrierInfo(info)

        // -- Disk space --
        collectDiskInfo(info)

        // -- System uptime --
        info["systemUptimeSeconds"] = SystemClock.elapsedRealtime() / 1000.0

        // -- Physical memory --
        collectMemoryInfo(info)

        // -- Processor count --
        info["processorCount"] = Runtime.getRuntime().availableProcessors()
        info["activeProcessorCount"] = Runtime.getRuntime().availableProcessors()

        // -- Battery --
        collectBatteryInfo(info)

        // -- Android ID (equivalent to identifierForVendor) --
        info["androidId"] = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        ) ?: ""

        // -- User interface idiom --
        info["userInterfaceIdiom"] = getDeviceIdiom()

        // -- Low power mode --
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        info["isLowPowerModeEnabled"] = powerManager?.isPowerSaveMode ?: false

        // -- Timestamps --
        val now = Date()
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        isoFormat.timeZone = TimeZone.getTimeZone("UTC")
        info["deviceTimestampUTC"] = isoFormat.format(now)
        info["deviceTimestampEpochMs"] = System.currentTimeMillis()

        // -- Locale formatting --
        collectLocaleFormattingInfo(info)

        // -- Time format --
        info["uses24HourTime"] = DateFormat.is24HourFormat(context)

        // -- Metric system --
        info["usesMetricSystem"] = usesMetricSystem()

        // -- Dark/light mode --
        val nightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        info["userInterfaceStyle"] = when (nightMode) {
            Configuration.UI_MODE_NIGHT_YES -> "dark"
            Configuration.UI_MODE_NIGHT_NO -> "light"
            else -> "unspecified"
        }

        // -- Font scale (comparable to iOS contentSizeCategory) --
        info["fontScale"] = context.resources.configuration.fontScale

        // -- Device orientation --
        info["deviceOrientation"] = getOrientationString()

        // -- Network type --
        collectNetworkType(info)

        // -- Build identifiers --
        info["buildFingerprint"] = Build.FINGERPRINT
        info["buildDisplay"] = Build.DISPLAY
        info["buildId"] = Build.ID
        info["buildTime"] = Build.TIME
        info["buildType"] = Build.TYPE
        info["buildTags"] = Build.TAGS
        info["bootloader"] = Build.BOOTLOADER
        info["supportedAbis"] = Build.SUPPORTED_ABIS.toList()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            info["securityPatch"] = Build.VERSION.SECURITY_PATCH
        }

        // -- Accessibility --
        collectAccessibilityInfo(info)

        // -- System features (hardware capabilities) --
        collectSystemFeatures(info)

        // -- System boot time (derived: current time - uptime) --
        val bootTimeMs = System.currentTimeMillis() - SystemClock.elapsedRealtime()
        info["systemBootTimeEpochMs"] = bootTimeMs

        // -- Screen timeout --
        try {
            info["screenTimeoutMs"] = Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_OFF_TIMEOUT
            )
        } catch (_: Exception) {}

        // -- Animator duration scale (0 = animations off) --
        try {
            info["animatorDurationScale"] = Settings.Global.getFloat(
                context.contentResolver,
                Settings.Global.ANIMATOR_DURATION_SCALE
            )
        } catch (_: Exception) {}

        // -- Number of available locales --
        info["availableLocalesCount"] = Locale.getAvailableLocales().size

        return info
    }

    // ── Private helpers ────────────────────────────────────────────

    private fun collectScreenInfo(info: HashMap<String, Any?>) {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        if (windowManager != null) {
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(metrics)

            info["screenScale"] = metrics.density.toDouble()
            info["nativeBoundsWidth"] = metrics.widthPixels.toDouble()
            info["nativeBoundsHeight"] = metrics.heightPixels.toDouble()
            info["screenBoundsWidth"] = (metrics.widthPixels / metrics.density).toDouble()
            info["screenBoundsHeight"] = (metrics.heightPixels / metrics.density).toDouble()
            info["screenDensityDpi"] = metrics.densityDpi
        }
    }

    private fun collectLocaleInfo(info: HashMap<String, Any?>) {
        val defaultLocale = Locale.getDefault()
        info["currentLocaleIdentifier"] = defaultLocale.toString()
        info["currentLocaleLanguageCode"] = defaultLocale.language
        info["currentLocaleRegionCode"] = defaultLocale.country

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val localeList = android.os.LocaleList.getDefault()
            val languages = mutableListOf<String>()
            for (i in 0 until localeList.size()) {
                languages.add(localeList.get(i).toLanguageTag())
            }
            info["preferredLanguages"] = languages
        } else {
            info["preferredLanguages"] = listOf(defaultLocale.toLanguageTag())
        }
    }

    private fun collectKeyboardLanguages(info: HashMap<String, Any?>) {
        try {
            val inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE)
                as? android.view.inputmethod.InputMethodManager
            if (inputMethodManager != null) {
                val keyboards = mutableListOf<String>()
                val inputMethods = inputMethodManager.enabledInputMethodList
                for (method in inputMethods) {
                    val subtypes = inputMethodManager.getEnabledInputMethodSubtypeList(method, true)
                    for (subtype in subtypes) {
                        val locale = subtype.languageTag.ifEmpty { subtype.locale }
                        if (locale.isNotEmpty()) {
                            keyboards.add(locale)
                        }
                    }
                }
                info["keyboardLanguages"] = keyboards.distinct()
            } else {
                info["keyboardLanguages"] = emptyList<String>()
            }
        } catch (_: Exception) {
            info["keyboardLanguages"] = emptyList<String>()
        }
    }

    private fun collectTimezoneInfo(info: HashMap<String, Any?>) {
        val tz = TimeZone.getDefault()
        info["timezoneIdentifier"] = tz.id
        info["timezoneAbbreviation"] = tz.getDisplayName(tz.inDaylightTime(Date()), TimeZone.SHORT, Locale.US)
        info["timezoneOffsetSeconds"] = tz.getOffset(System.currentTimeMillis()) / 1000
    }

    private fun collectCarrierInfo(info: HashMap<String, Any?>) {
        try {
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                info["carrierName"] = telephonyManager.networkOperatorName ?: ""
                val networkOperator = telephonyManager.networkOperator ?: ""
                if (networkOperator.length >= 5) {
                    info["mobileCountryCode"] = networkOperator.substring(0, 3)
                    info["mobileNetworkCode"] = networkOperator.substring(3)
                } else {
                    info["mobileCountryCode"] = ""
                    info["mobileNetworkCode"] = ""
                }
                info["isoCountryCode"] = telephonyManager.networkCountryIso ?: ""
            }
        } catch (_: Exception) {
            // No telephony permission or service unavailable
        }
    }

    private fun collectDiskInfo(info: HashMap<String, Any?>) {
        try {
            val stat = StatFs(Environment.getDataDirectory().path)
            info["totalDiskSpaceBytes"] = stat.totalBytes
            info["freeDiskSpaceBytes"] = stat.availableBytes
        } catch (_: Exception) {
            // StatFs may fail on some devices
        }
    }

    private fun collectMemoryInfo(info: HashMap<String, Any?>) {
        try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            if (activityManager != null) {
                val memInfo = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(memInfo)
                info["physicalMemoryBytes"] = memInfo.totalMem
            }
        } catch (_: Exception) {
            // Memory info may not be available
        }
    }

    private fun collectBatteryInfo(info: HashMap<String, Any?>) {
        try {
            val batteryIntent = context.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            )
            if (batteryIntent != null) {
                val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                if (level >= 0 && scale > 0) {
                    info["batteryLevel"] = level.toDouble() / scale.toDouble()
                }

                val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                info["batteryState"] = when (status) {
                    BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                    BatteryManager.BATTERY_STATUS_FULL -> "full"
                    BatteryManager.BATTERY_STATUS_DISCHARGING,
                    BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "unplugged"
                    else -> "unknown"
                }
            }
        } catch (_: Exception) {
            // Battery info may not be available
        }
    }

    private fun collectLocaleFormattingInfo(info: HashMap<String, Any?>) {
        val locale = Locale.getDefault()
        val symbols = DecimalFormatSymbols.getInstance(locale)
        info["decimalSeparator"] = symbols.decimalSeparator.toString()
        info["groupingSeparator"] = symbols.groupingSeparator.toString()

        try {
            val currency = Currency.getInstance(locale)
            info["currencyCode"] = currency.currencyCode
            info["currencySymbol"] = currency.symbol
        } catch (_: Exception) {
            info["currencyCode"] = ""
            info["currencySymbol"] = ""
        }

        val calendar = Calendar.getInstance(locale)
        info["calendarIdentifier"] = calendar.calendarType
        info["firstWeekday"] = calendar.firstDayOfWeek
    }

    private fun collectNetworkType(info: HashMap<String, Any?>) {
        try {
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null) {
                @Suppress("DEPRECATION")
                val networkType = telephonyManager.networkType
                info["currentRadioAccessTechnology"] = networkTypeToString(networkType)
            }
        } catch (_: SecurityException) {
            // READ_PHONE_STATE permission not granted
        } catch (_: Exception) {
            // Other telephony errors
        }
    }

    private fun networkTypeToString(type: Int): String {
        return when (type) {
            TelephonyManager.NETWORK_TYPE_GPRS -> "GPRS"
            TelephonyManager.NETWORK_TYPE_EDGE -> "EDGE"
            TelephonyManager.NETWORK_TYPE_UMTS -> "UMTS"
            TelephonyManager.NETWORK_TYPE_CDMA -> "CDMA"
            TelephonyManager.NETWORK_TYPE_EVDO_0 -> "EVDO_0"
            TelephonyManager.NETWORK_TYPE_EVDO_A -> "EVDO_A"
            TelephonyManager.NETWORK_TYPE_1xRTT -> "1xRTT"
            TelephonyManager.NETWORK_TYPE_HSDPA -> "HSDPA"
            TelephonyManager.NETWORK_TYPE_HSUPA -> "HSUPA"
            TelephonyManager.NETWORK_TYPE_HSPA -> "HSPA"
            TelephonyManager.NETWORK_TYPE_IDEN -> "iDEN"
            TelephonyManager.NETWORK_TYPE_EVDO_B -> "EVDO_B"
            TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
            TelephonyManager.NETWORK_TYPE_EHRPD -> "eHRPD"
            TelephonyManager.NETWORK_TYPE_HSPAP -> "HSPAP"
            TelephonyManager.NETWORK_TYPE_NR -> "NR"
            else -> "unknown"
        }
    }

    private fun getDeviceIdiom(): String {
        val config = context.resources.configuration
        val screenLayout = config.screenLayout and Configuration.SCREENLAYOUT_SIZE_MASK
        return when {
            screenLayout >= Configuration.SCREENLAYOUT_SIZE_XLARGE -> "tablet"
            screenLayout >= Configuration.SCREENLAYOUT_SIZE_LARGE -> "tablet"
            else -> "phone"
        }
    }

    private fun getOrientationString(): String {
        return when (context.resources.configuration.orientation) {
            Configuration.ORIENTATION_PORTRAIT -> "portrait"
            Configuration.ORIENTATION_LANDSCAPE -> "landscape"
            else -> "unknown"
        }
    }

    private fun usesMetricSystem(): Boolean {
        val country = Locale.getDefault().country.uppercase()
        return country !in listOf("US", "LR", "MM")
    }

    private fun collectAccessibilityInfo(info: HashMap<String, Any?>) {
        try {
            val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
            if (am != null) {
                info["isAccessibilityEnabled"] = am.isEnabled
                info["isTouchExplorationEnabled"] = am.isTouchExplorationEnabled
            }
        } catch (_: Exception) {}

        try {
            info["fontScale"] = context.resources.configuration.fontScale
        } catch (_: Exception) {}
    }

    private fun collectSystemFeatures(info: HashMap<String, Any?>) {
        val pm = context.packageManager
        info["hasNfc"] = pm.hasSystemFeature(PackageManager.FEATURE_NFC)
        info["hasBluetooth"] = pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)
        info["hasBluetoothLe"] = pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
        info["hasCamera"] = pm.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
        info["hasTelephony"] = pm.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        info["hasWifi"] = pm.hasSystemFeature(PackageManager.FEATURE_WIFI)
        info["hasGps"] = pm.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS)
        info["hasAccelerometer"] = pm.hasSystemFeature(PackageManager.FEATURE_SENSOR_ACCELEROMETER)
        info["hasGyroscope"] = pm.hasSystemFeature(PackageManager.FEATURE_SENSOR_GYROSCOPE)
        info["hasFingerprint"] = pm.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
        info["hasFaceDetection"] = pm.hasSystemFeature(PackageManager.FEATURE_FACE)
        info["hasIris"] = pm.hasSystemFeature(PackageManager.FEATURE_IRIS)
        info["hasMicrophone"] = pm.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)
        info["hasUsbHost"] = pm.hasSystemFeature(PackageManager.FEATURE_USB_HOST)
    }
}
