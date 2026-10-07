package com.banghuazhao.swiftcomp

import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.compositesai/auth"
        ).setMethodCallHandler { call, result ->
            if (call.method != "getMicrosoftAndroidSigningInfo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                result.success(
                    mapOf(
                        "packageName" to packageName,
                        "signatureHash" to microsoftSigningHash()
                    )
                )
            } catch (_: Exception) {
                result.error(
                    "signing_certificate_unavailable",
                    "Microsoft sign-in is temporarily unavailable. Please use email or another sign-in option.",
                    null
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun microsoftSigningHash(): String {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            PackageManager.GET_SIGNATURES
        }
        val info = packageManager.getPackageInfo(packageName, flags)
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.signingInfo?.let {
                if (it.hasMultipleSigners()) it.apkContentsSigners else it.signingCertificateHistory
            }
        } else {
            info.signatures
        }
        // MSAL validates the first certificate in this same signing-history order.
        val certificate = signatures?.firstOrNull()
            ?: throw IllegalStateException("Signing certificate unavailable")
        return Base64.encodeToString(
            MessageDigest.getInstance("SHA-1").digest(certificate.toByteArray()),
            Base64.NO_WRAP
        )
    }
}
