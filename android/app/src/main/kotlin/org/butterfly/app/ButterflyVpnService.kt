package org.butterfly.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat

class ButterflyVpnService : VpnService() {

    companion object {
        const val ACTION_CONNECT = "org.butterfly.app.CONNECT"
        const val ACTION_DISCONNECT = "org.butterfly.app.DISCONNECT"
        const val EXTRA_PRIMARY_DNS = "primary_dns"
        const val EXTRA_SECONDARY_DNS = "secondary_dns"
        const val CHANNEL_ID = "butterfly_vpn_channel"
        const val NOTIFICATION_ID = 1001

        @Volatile
        var isRunning: Boolean = false

        @Volatile
        var activeDns: List<String> = emptyList()
    }

    private var pfd: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == ACTION_DISCONNECT) {
            stopVpn()
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_CONNECT) {
            val primaryDns = intent.getStringExtra(EXTRA_PRIMARY_DNS) ?: "1.1.1.1"
            val secondaryDns = intent.getStringExtra(EXTRA_SECONDARY_DNS)

            createNotificationChannel()

            val notificationIntent = Intent(this, MainActivity::class.java).apply {
                this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                notificationIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Butterfly DNS Active")
                .setContentText("Protected via $primaryDns")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            try {
                val builder = Builder()
                    .setSession("Butterfly DNS Shield")
                    .addAddress("10.0.0.2", 32)
                    .addRoute(primaryDns, 32)
                    .addDnsServer(primaryDns)
                    .setBlocking(true)

                secondaryDns?.takeIf { it.isNotBlank() }?.let { sec ->
                    try {
                        builder.addRoute(sec, 32)
                        builder.addDnsServer(sec)
                    } catch (_: Exception) {}
                }

                pfd?.close()
                pfd = builder.establish()

                if (pfd != null) {
                    isRunning = true
                    activeDns = listOfNotNull(primaryDns, secondaryDns?.takeIf { it.isNotBlank() })
                } else {
                    stopVpn()
                    stopSelf()
                    return START_NOT_STICKY
                }
            } catch (_: Exception) {
                stopVpn()
                stopSelf()
                return START_NOT_STICKY
            }

            return START_STICKY
        }

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Butterfly DNS Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ongoing notification for Butterfly DNS shield"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun stopVpn() {
        try {
            pfd?.close()
        } catch (_: Exception) {}
        pfd = null
        isRunning = false
        activeDns = emptyList()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
