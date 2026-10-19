package org.butterfly.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "butterfly/vpn"
        private const val VPN_REQUEST_CODE = 2026
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingPrimaryDns: String? = null
    private var pendingSecondaryDns: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val primary = call.argument<String>("primary") ?: "1.1.1.1"
                    val secondary = call.argument<String>("secondary")
                    handleStartVpn(primary, secondary, result)
                }
                "stopVpn" -> {
                    handleStopVpn(result)
                }
                "getVpnStatus" -> {
                    result.success(
                        mapOf(
                            "isRunning" to ButterflyVpnService.isRunning,
                            "dnsServers" to ButterflyVpnService.activeDns
                        )
                    )
                }
                "getNetworkTransport" -> {
                    result.success(getNetworkTransport())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun handleStartVpn(primary: String, secondary: String?, result: MethodChannel.Result) {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            if (pendingResult != null) {
                result.error("ALREADY_REQUESTING", "VPN permission request in progress", null)
                return
            }
            pendingResult = result
            pendingPrimaryDns = primary
            pendingSecondaryDns = secondary
            startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
        } else {
            startVpnService(primary, secondary)
            result.success(true)
        }
    }

    private fun handleStopVpn(result: MethodChannel.Result) {
        val intent = Intent(this, ButterflyVpnService::class.java).apply {
            action = ButterflyVpnService.ACTION_DISCONNECT
        }
        startService(intent)
        result.success(true)
    }

    private fun startVpnService(primary: String, secondary: String?) {
        val intent = Intent(this, ButterflyVpnService::class.java).apply {
            action = ButterflyVpnService.ACTION_CONNECT
            putExtra(ButterflyVpnService.EXTRA_PRIMARY_DNS, primary)
            putExtra(ButterflyVpnService.EXTRA_SECONDARY_DNS, secondary)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            val res = pendingResult
            val primary = pendingPrimaryDns ?: "1.1.1.1"
            val secondary = pendingSecondaryDns

            pendingResult = null
            pendingPrimaryDns = null
            pendingSecondaryDns = null

            if (resultCode == Activity.RESULT_OK) {
                startVpnService(primary, secondary)
                res?.success(true)
            } else {
                res?.error("VPN_PERMISSION_DENIED", "User denied VPN permission", null)
            }
        }
    }

    private fun getNetworkTransport(): String {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return "Wi-Fi"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val activeNetwork = cm.activeNetwork ?: return "Wi-Fi"
            val caps = cm.getNetworkCapabilities(activeNetwork) ?: return "Wi-Fi"
            return when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Cellular"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
                else -> "Wi-Fi"
            }
        } else {
            @Suppress("DEPRECATION")
            val info = cm.activeNetworkInfo ?: return "Wi-Fi"
            @Suppress("DEPRECATION")
            return when (info.type) {
                ConnectivityManager.TYPE_WIFI -> "Wi-Fi"
                ConnectivityManager.TYPE_MOBILE -> "Cellular"
                ConnectivityManager.TYPE_ETHERNET -> "Ethernet"
                else -> "Wi-Fi"
            }
        }
    }
}
