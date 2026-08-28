package com.kaapav.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsBroadcastReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SmsBroadcastReceiver"
        var listener: ((Map<String, Any>) -> Unit)? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0]?.displayOriginatingAddress ?: ""
            val timestamp = messages[0]?.timestampMillis ?: System.currentTimeMillis()
            val bodyBuilder = StringBuilder()

            for (sms in messages) {
                sms?.displayMessageBody?.let { bodyBuilder.append(it) }
            }

            val fullBody = bodyBuilder.toString()
            Log.d(TAG, "SMS received from $sender: $fullBody")

            val payload = mapOf<String, Any>(
                "sender" to sender,
                "body" to fullBody,
                "timestamp" to timestamp
            )

            listener?.invoke(payload)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing incoming SMS", e)
        }
    }
}
