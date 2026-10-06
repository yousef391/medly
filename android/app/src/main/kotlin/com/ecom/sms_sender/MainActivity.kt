package com.ecom.sms_sender

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ecom.sms_sender/sms"
    private val SMS_PERMISSION_CODE = 101

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    val subscriptionId = call.argument<Int>("subscriptionId")

                    if (phone == null || message == null) {
                        result.error("INVALID_ARGS", "Phone and message are required", null)
                        return@setMethodCallHandler
                    }

                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val smsManager = if (subscriptionId != null && subscriptionId >= 0) {
                            // Use specific SIM
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                getSystemService(SmsManager::class.java).createForSubscriptionId(subscriptionId)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
                            }
                        } else {
                            // Use default SIM
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }
                        }

                        // Split long messages into parts
                        val parts = smsManager.divideMessage(message)
                        if (parts.size > 1) {
                            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                        } else {
                            smsManager.sendTextMessage(phone, null, message, null, null)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                }

                "getSimCards" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_PHONE_STATE), 102)
                        result.success(emptyList<Map<String, Any>>())
                        return@setMethodCallHandler
                    }

                    try {
                        val subscriptionManager = getSystemService(SubscriptionManager::class.java)
                        val sims = subscriptionManager.activeSubscriptionInfoList ?: emptyList()

                        val simList = sims.map { info ->
                            mapOf(
                                "subscriptionId" to info.subscriptionId,
                                "simSlot" to info.simSlotIndex,
                                "carrierName" to (info.carrierName?.toString() ?: "SIM ${info.simSlotIndex + 1}"),
                                "displayName" to (info.displayName?.toString() ?: "SIM ${info.simSlotIndex + 1}"),
                                "number" to (info.number ?: "")
                            )
                        }
                        result.success(simList)
                    } catch (e: Exception) {
                        result.error("SIM_ERROR", e.message, null)
                    }
                }

                "requestSmsPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.SEND_SMS,
                                Manifest.permission.READ_PHONE_STATE
                            ),
                            SMS_PERMISSION_CODE
                        )
                        result.success(false)
                    }
                }

                "hasSmsPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }

                else -> result.notImplemented()
            }
        }
    }
}
