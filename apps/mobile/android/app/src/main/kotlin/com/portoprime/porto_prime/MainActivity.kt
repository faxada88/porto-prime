package com.portoprime.porto_prime

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    override fun attachBaseContext(newBase: Context) {
        val tag = newBase.getSharedPreferences("porto_language", Context.MODE_PRIVATE)
            .getString("language", "pt-BR") ?: "pt-BR"
        val locale = Locale.forLanguageTag(tag)
        Locale.setDefault(locale)
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        config.setLayoutDirection(locale)
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }

    @Suppress("DEPRECATION")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "porto_prime/language")
            .setMethodCallHandler { call, result ->
                if (call.method != "setLanguage") {
                    result.notImplemented()
                } else {
                    val tag = call.argument<String>("language")
                    if (tag !in listOf("pt-BR", "es-ES", "en-US")) {
                        result.error("INVALID_LANGUAGE", "Unsupported language", null)
                    } else {
                        getSharedPreferences("porto_language", Context.MODE_PRIVATE)
                            .edit().putString("language", tag).apply()
                        val locale = Locale.forLanguageTag(tag)
                        Locale.setDefault(locale)
                        val config = Configuration(resources.configuration)
                        config.setLocale(locale)
                        config.setLayoutDirection(locale)
                        resources.updateConfiguration(config, resources.displayMetrics)
                        applicationContext.resources.updateConfiguration(config, applicationContext.resources.displayMetrics)
                        result.success(null)
                    }
                }
            }
    }
}
