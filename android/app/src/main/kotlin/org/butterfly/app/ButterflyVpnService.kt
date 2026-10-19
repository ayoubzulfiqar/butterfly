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
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

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
    private var relayThread: Thread? = null
    private var dnsExecutor: ExecutorService? = null
    private var outputStream: FileOutputStream? = null
    private val tunLock = Any()
    private val packetIdGenerator = AtomicInteger(1000)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == ACTION_DISCONNECT) {
            stopVpn()
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_CONNECT) {
            stopVpn()

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

                pfd = builder.establish()

                if (pfd != null) {
                    isRunning = true
                    activeDns = listOfNotNull(primaryDns, secondaryDns?.takeIf { it.isNotBlank() })
                    startRelayLoop(pfd!!, primaryDns)
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

    private fun startRelayLoop(descriptor: ParcelFileDescriptor, defaultDns: String) {
        val inputStream = FileInputStream(descriptor.fileDescriptor)
        outputStream = FileOutputStream(descriptor.fileDescriptor)
        dnsExecutor = Executors.newFixedThreadPool(8)

        relayThread = Thread({
            val buffer = ByteArray(4096)
            try {
                while (isRunning && !Thread.currentThread().isInterrupted) {
                    val length = inputStream.read(buffer)
                    if (length <= 0) break
                    val packetData = buffer.copyOf(length)
                    dnsExecutor?.submit {
                        handleDnsPacket(packetData, defaultDns)
                    }
                }
            } catch (_: Exception) {
                // Expected when TUN descriptor is closed
            }
        }, "ButterflyDnsRelay").apply {
            isDaemon = true
            start()
        }
    }

    private fun handleDnsPacket(packetData: ByteArray, defaultDns: String) {
        if (packetData.size < 28) return

        val versionAndIhl = packetData[0].toInt() and 0xFF
        val version = versionAndIhl ushr 4
        if (version != 4) return

        val ihl = (versionAndIhl and 0x0F) * 4
        if (ihl < 20 || ihl > packetData.size) return

        val protocol = packetData[9].toInt() and 0xFF
        if (protocol != 17) return

        val srcPort = ((packetData[ihl].toInt() and 0xFF) shl 8) or (packetData[ihl + 1].toInt() and 0xFF)
        val dstPort = ((packetData[ihl + 2].toInt() and 0xFF) shl 8) or (packetData[ihl + 3].toInt() and 0xFF)
        val udpLen = ((packetData[ihl + 4].toInt() and 0xFF) shl 8) or (packetData[ihl + 5].toInt() and 0xFF)

        if (dstPort != 53 || udpLen < 8) return

        val dnsPayloadOffset = ihl + 8
        val dnsPayloadLen = udpLen - 8
        if (dnsPayloadOffset + dnsPayloadLen > packetData.size) return

        val clientIp = packetData.copyOfRange(12, 16)
        val targetIp = packetData.copyOfRange(16, 20)

        val destAddress = try {
            if (targetIp[0] == 10.toByte() && targetIp[1] == 0.toByte() && targetIp[2] == 0.toByte() && targetIp[3] == 2.toByte()) {
                InetAddress.getByName(defaultDns)
            } else {
                InetAddress.getByAddress(targetIp)
            }
        } catch (_: Exception) {
            return
        }

        var socket: DatagramSocket? = null
        try {
            socket = DatagramSocket()
            if (!protect(socket)) {
                return
            }
            socket.soTimeout = 3000

            val queryPacket = DatagramPacket(
                packetData,
                dnsPayloadOffset,
                dnsPayloadLen,
                destAddress,
                53
            )
            socket.send(queryPacket)

            val respBuf = ByteArray(4096)
            val respPacket = DatagramPacket(respBuf, respBuf.size)
            socket.receive(respPacket)
            val respDnsLen = respPacket.length

            val totalLen = 20 + 8 + respDnsLen
            val outPacket = ByteArray(totalLen)

            // IPv4 Header
            outPacket[0] = 0x45.toByte()
            outPacket[1] = 0x00.toByte()
            outPacket[2] = ((totalLen ushr 8) and 0xFF).toByte()
            outPacket[3] = (totalLen and 0xFF).toByte()

            val id = packetIdGenerator.incrementAndGet()
            outPacket[4] = ((id ushr 8) and 0xFF).toByte()
            outPacket[5] = (id and 0xFF).toByte()
            outPacket[6] = 0x40.toByte() // Don't fragment
            outPacket[7] = 0x00.toByte()
            outPacket[8] = 64.toByte()   // TTL
            outPacket[9] = 17.toByte()   // UDP (0x11)
            outPacket[10] = 0.toByte()
            outPacket[11] = 0.toByte()

            // Source IP: the DNS server IP
            System.arraycopy(targetIp, 0, outPacket, 12, 4)
            // Destination IP: client IP
            System.arraycopy(clientIp, 0, outPacket, 16, 4)

            // IPv4 header checksum
            val ipChecksum = computeIpChecksum(outPacket, 0, 20)
            outPacket[10] = ((ipChecksum ushr 8) and 0xFF).toByte()
            outPacket[11] = (ipChecksum and 0xFF).toByte()

            // UDP Header
            outPacket[20] = 0.toByte()
            outPacket[21] = 53.toByte()
            outPacket[22] = ((srcPort ushr 8) and 0xFF).toByte()
            outPacket[23] = (srcPort and 0xFF).toByte()
            val outUdpLen = 8 + respDnsLen
            outPacket[24] = ((outUdpLen ushr 8) and 0xFF).toByte()
            outPacket[25] = (outUdpLen and 0xFF).toByte()
            outPacket[26] = 0.toByte() // UDP checksum disabled per RFC 768
            outPacket[27] = 0.toByte()

            // DNS response payload
            System.arraycopy(respBuf, 0, outPacket, 28, respDnsLen)

            synchronized(tunLock) {
                outputStream?.write(outPacket)
            }
        } catch (_: Exception) {
            // Drop on timeout or error
        } finally {
            try {
                socket?.close()
            } catch (_: Exception) {}
        }
    }

    private fun computeIpChecksum(data: ByteArray, offset: Int, length: Int): Int {
        var sum = 0
        var i = offset
        while (i < offset + length) {
            val high = data[i].toInt() and 0xFF
            val low = data[i + 1].toInt() and 0xFF
            val word = (high shl 8) or low
            sum += word
            i += 2
        }
        while ((sum ushr 16) != 0) {
            sum = (sum and 0xFFFF) + (sum ushr 16)
        }
        return sum.inv() and 0xFFFF
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
        isRunning = false
        activeDns = emptyList()

        try {
            relayThread?.interrupt()
        } catch (_: Exception) {}
        relayThread = null

        try {
            dnsExecutor?.shutdownNow()
        } catch (_: Exception) {}
        dnsExecutor = null

        synchronized(tunLock) {
            try {
                outputStream?.close()
            } catch (_: Exception) {}
            outputStream = null
        }

        try {
            pfd?.close()
        } catch (_: Exception) {}
        pfd = null

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
