package com.aimemo.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.aimemo.app.ui.AIMemoApp
import com.aimemo.app.ui.AIMemoViewModel
import com.aimemo.app.ui.theme.AIMemoTheme

class MainActivity : ComponentActivity() {
    private val viewModel: AIMemoViewModel by viewModels {
        val container = (application as AIMemoApplication).container
        object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return AIMemoViewModel(
                    authRepository = container.authRepository,
                    taskRepository = container.taskRepository,
                    summaryRepository = container.summaryRepository,
                    clientConfigRepository = container.clientConfigRepository,
                ) as T
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AIMemoTheme {
                AIMemoApp(viewModel = viewModel)
            }
        }
    }
}
