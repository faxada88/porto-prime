package com.portoprime.porto_prime

import android.app.LocaleManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.LocaleList
import io.flutter.embedding.android.FlutterFragmentActivity
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    // Localizes native SDK screens too, without changing the device language.
    @Suppress("DEPRECATION")
    override fun attachBaseContext(newBase: Context) {
        val locale = Locale.forLanguageTag("pt-BR")
        Locale.setDefault(locale)
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        config.setLayoutDirection(locale)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            val app = newBase.applicationContext
            app.resources.updateConfiguration(config, app.resources.displayMetrics)
        }
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val manager = getSystemService(LocaleManager::class.java)
            val locales = LocaleList.forLanguageTags("pt-BR")
            if (manager.applicationLocales != locales) {
                manager.applicationLocales = locales
            }
        }
        super.onCreate(savedInstanceState)
    }
}
