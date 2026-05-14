package com.aimemo.app.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

private object Routes {
    const val Onboarding = "onboarding"
    const val Auth = "auth"
    const val Tasks = "main/tasks"
    const val SummaryMain = "main/summary"
    const val TaskEdit = "task-edit/{taskId}"
    const val SummaryEntry = "summary-entry"
    const val SummaryResult = "summary-result"
    const val SummaryHistory = "summary-history"
    const val Profile = "profile"
    const val Settings = "settings"

    fun taskEdit(taskId: String) = "task-edit/$taskId"
}

@Composable
fun AIMemoApp(viewModel: AIMemoViewModel) {
    val state by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val navController = rememberNavController()

    LaunchedEffect(state.errorMessage, state.lastStatus) {
        val message = state.errorMessage ?: state.lastStatus
        if (message != null) {
            snackbarHostState.showSnackbar(message)
            viewModel.clearTransientMessages()
        }
    }

    if (state.isBooting) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    LaunchedEffect(state.isLoggedIn, state.onboardingCompleted, state.isBooting) {
        val target = when {
            !state.onboardingCompleted -> Routes.Onboarding
            !state.isLoggedIn -> Routes.Auth
            else -> Routes.Tasks
        }
        if (navController.currentDestination?.route != target) {
            navController.navigate(target) {
                popUpTo(0)
                launchSingleTop = true
            }
        }
    }

    Box(Modifier.fillMaxSize()) {
        NavHost(navController = navController, startDestination = Routes.Onboarding) {
            composable(Routes.Onboarding) {
                OnboardingScreen(
                    onContinue = {
                        viewModel.completeOnboarding()
                        navController.navigate(if (state.isLoggedIn) Routes.Tasks else Routes.Auth) { launchSingleTop = true }
                    },
                    onSkip = {
                        viewModel.completeOnboarding()
                        navController.navigate(if (state.isLoggedIn) Routes.Tasks else Routes.Auth) { launchSingleTop = true }
                    },
                )
            }
            composable(Routes.Auth) {
                AuthScreen(
                    state = state,
                    snackbarHostState = snackbarHostState,
                    onEmailChange = viewModel::updateAuthEmail,
                    onCodeChange = viewModel::updateAuthCode,
                    onSendCode = viewModel::sendLoginCode,
                    onLogin = viewModel::verifyLogin,
                    onComingSoon = viewModel::showComingSoon,
                )
            }
            composable(Routes.Tasks) {
                TasksScreen(
                    state = state,
                    snackbarHostState = snackbarHostState,
                    onOpenProfile = { navController.navigate(Routes.Profile) },
                    onOpenSettings = { navController.navigate(Routes.Settings) },
                    onOpenSummary = { navController.navigate(Routes.SummaryMain) },
                    onEditTask = { navController.navigate(Routes.taskEdit(it)) },
                    onRefresh = viewModel::refreshTasks,
                    onSelectTag = viewModel::selectTag,
                    onToggleCompleted = viewModel::toggleTaskCompleted,
                    onAddTask = viewModel::addQuickTask,
                )
            }
            composable(Routes.SummaryMain) {
                SummaryMainScreen(
                    state = state,
                    snackbarHostState = snackbarHostState,
                    onOpenTasks = { navController.navigate(Routes.Tasks) },
                    onOpenProfile = { navController.navigate(Routes.Profile) },
                    onGenerate = { navController.navigate(Routes.SummaryEntry) },
                    onHistory = {
                        viewModel.refreshHistory()
                        navController.navigate(Routes.SummaryHistory)
                    },
                    onAddTask = viewModel::addQuickTask,
                )
            }
            composable(
                route = Routes.TaskEdit,
                arguments = listOf(navArgument("taskId") { type = NavType.StringType }),
            ) { backStackEntry ->
                val taskId = backStackEntry.arguments?.getString("taskId")
                TaskEditScreen(
                    task = state.tasks.firstOrNull { it.id == taskId },
                    saving = state.isSavingTask,
                    deleting = state.isDeletingTask,
                    onBack = navController::popBackStack,
                    onSave = { task, body, tags, createdAt, completedAt ->
                        viewModel.saveTask(task, body, tags, createdAt, completedAt)
                        navController.popBackStack()
                    },
                    onDelete = { task ->
                        viewModel.deleteTask(task)
                        navController.popBackStack()
                    },
                )
            }
            composable(Routes.SummaryEntry) {
                SummaryEntryScreen(
                    state = state,
                    onBack = navController::popBackStack,
                    onHistory = {
                        viewModel.refreshHistory()
                        navController.navigate(Routes.SummaryHistory)
                    },
                    onSelectPeriod = viewModel::selectPeriod,
                    onToggleTag = viewModel::toggleSummaryTag,
                    onGenerate = {
                        viewModel.generateSummary()
                        navController.navigate(Routes.SummaryResult)
                    },
                )
            }
            composable(Routes.SummaryResult) {
                SummaryResultScreen(
                    state = state,
                    onBack = navController::popBackStack,
                    onConfirm = {
                        viewModel.refreshHistory()
                        navController.navigate(Routes.SummaryHistory) {
                            popUpTo(Routes.SummaryEntry)
                        }
                    },
                    onRefine = viewModel::generateSummary,
                )
            }
            composable(Routes.SummaryHistory) {
                SummaryHistoryScreen(
                    state = state,
                    onBack = navController::popBackStack,
                    onSelectPeriod = viewModel::selectHistoryPeriod,
                    onRefresh = viewModel::refreshHistory,
                )
            }
            composable(Routes.Profile) {
                ProfileScreen(
                    state = state,
                    onBack = navController::popBackStack,
                    onSettings = { navController.navigate(Routes.Settings) },
                    onHistory = {
                        viewModel.refreshHistory()
                        navController.navigate(Routes.SummaryHistory)
                    },
                    onLogout = viewModel::logout,
                    onComingSoon = viewModel::showComingSoon,
                )
            }
            composable(Routes.Settings) {
                SettingsScreen(
                    onBack = navController::popBackStack,
                    onComingSoon = viewModel::showComingSoon,
                )
            }
        }
        SnackbarHost(snackbarHostState, Modifier.align(Alignment.BottomCenter))
    }
}
