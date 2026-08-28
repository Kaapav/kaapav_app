package com.kaapav.app

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    private val METHOD_CHANNEL = "com.kaapav.app/sms_reader"
    private val EVENT_CHANNEL = "com.kaapav.app/sms_stream"

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel for on-demand SMS querying and permission checks
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSmsPermission" -> {
                    val readSms = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveSms = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(readSms && receiveSms)
                }
                "getRecentSms" -> {
                    val limit = call.argument<Int>("limit") ?: 30
                    try {
                        val messages = fetchRecentSms(limit)
                        result.success(messages)
                    } catch (e: Exception) {
                        result.error("SMS_READ_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel for real-time incoming SMS stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    SmsBroadcastReceiver.listener = { payload ->
                        runOnUiThread {
                            eventSink?.success(payload)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    SmsBroadcastReceiver.listener = null
                }
            }
        )
    }

    private fun fetchRecentSms(limit: Int): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            return list
        }

        val uri: Uri = Telephony.Sms.Inbox.CONTENT_URI
        val projection = arrayOf(
            Telephony.Sms.Inbox.ADDRESS,
            Telephony.Sms.Inbox.BODY,
            Telephony.Sms.Inbox.DATE
        )
        val sortOrder = "${Telephony.Sms.Inbox.DATE} DESC LIMIT $limit"

        var cursor: Cursor? = null
        try {
            cursor = contentResolver.query(uri, projection, null, null, sortOrder)
            if (cursor != null && cursor.moveToFirst()) {
                val addressIdx = cursor.getColumnIndex(Telephony.Sms.Inbox.ADDRESS)
                val bodyIdx = cursor.getColumnIndex(Telephony.Sms.Inbox.BODY)
                val dateIdx = cursor.getColumnIndex(Telephony.Sms.Inbox.DATE)

                do {
                    val address = if (addressIdx != -1) cursor.getString(addressIdx) ?: "" else ""
                    val body = if (bodyIdx != -1) cursor.getString(bodyIdx) ?: "" else ""
                    val date = if (dateIdx != -1) cursor.getLong(dateIdx) else System.currentTimeMillis()

                    list.add(mapOf(
                        "sender" to address,
                        "body" to body,
                        "timestamp" to date
                    ))
                } while (cursor.moveToNext())
            }
        } finally {
            cursor?.close()
        }
        return list
    }
}
