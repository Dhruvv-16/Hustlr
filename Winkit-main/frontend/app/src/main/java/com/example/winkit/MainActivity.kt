package com.example.winkit

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.winkit.ui.navigation.AppNavigation
import com.example.winkit.ui.theme.WinkItTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Check if the user is already logged in
        val sharedPref = getSharedPreferences("WinkitPrefs", Context.MODE_PRIVATE)
        val isLoggedIn = sharedPref.getBoolean("isLoggedIn", false)

        setContent {
            WinkItTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // 2. Pass the state and the preferences file to your Navigator
                    AppNavigation(isLoggedIn = isLoggedIn, sharedPref = sharedPref)
                }
            }
        }
    }
}