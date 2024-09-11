package com.example.feeluownx

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class StartTermuxHandler(private val context: Activity) : MethodChannel.MethodCallHandler,
    ActivityCompat.OnRequestPermissionsResultCallback {
    @SuppressLint("SdCardPath")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "startInTermux") {
            // ask for permission
            if (ContextCompat.checkSelfPermission(
                    context,
                    "com.termux.permission.RUN_COMMAND"
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    context,
                    arrayOf("com.termux.permission.RUN_COMMAND"),
                    0
                );
                result.success(null);
            } else {
                runCommand(result)
            }
        } else {
            result.notImplemented();
        }
    }

    private fun runCommand(result: MethodChannel.Result?) {
        // start intent
        val intent = Intent()
        intent.setClassName("com.termux", "com.termux.app.RunCommandService")
        intent.setAction("com.termux.RUN_COMMAND")
        intent.putExtra(
            "com.termux.RUN_COMMAND_PATH",
            "/data/data/com.termux/files/home/.local/bin/fuo"
        )
        intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-nw"))
        intent.putExtra(
            "com.termux.RUN_COMMAND_WORKDIR",
            "/data/data/com.termux/files/home"
        )
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        context.startService(intent);
        result?.success(null)
    }

    companion object {
        const val CHANNEL = "channel.feeluown/termux"
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        runCommand(null);
    }
}
