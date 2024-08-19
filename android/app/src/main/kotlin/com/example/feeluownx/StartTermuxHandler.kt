package com.example.feeluownx

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class StartTermuxHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    @SuppressLint("SdCardPath")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "startInTermux") {
            val intent = Intent()
            intent.setClassName("com.termux", "com.termux.app.RunCommandService")
            intent.setAction("com.termux.RUN_COMMAND")
            intent.putExtra(
                "com.termux.RUN_COMMAND_PATH",
                "/data/data/com.termux/files/home/.local/bin/fuo"
            )
            intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-nw"))
            intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
            intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            context.startService(intent);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    companion object {
        const val CHANNEL = "channel.feeluown/start_termux"
    }
}
