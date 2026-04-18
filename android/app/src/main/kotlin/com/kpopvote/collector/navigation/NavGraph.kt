package com.kpopvote.collector.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.navigation
import androidx.navigation.compose.rememberNavController
import com.kpopvote.collector.core.auth.AuthState
import com.kpopvote.collector.ui.auth.AuthGateViewModel
import com.kpopvote.collector.ui.auth.login.LoginScreen
import com.kpopvote.collector.ui.auth.register.RegisterScreen
import com.kpopvote.collector.ui.home.HomePlaceholderScreen

@Composable
fun KpopvoteNavHost(
    authGateViewModel: AuthGateViewModel = hiltViewModel(),
) {
    val navController = rememberNavController()
    val authState by authGateViewModel.authState.collectAsStateWithLifecycle()

    LaunchedEffect(authState) {
        when (authState) {
            is AuthState.Authenticated -> navController.navigateToMain()
            AuthState.Unauthenticated -> navController.navigateToAuth()
            AuthState.Loading -> Unit
        }
    }

    NavHost(
        navController = navController,
        startDestination = Route.Splash,
    ) {
        composable<Route.Splash> {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
            }
        }

        navigation<Route.AuthGraph>(startDestination = Route.Login) {
            composable<Route.Login> {
                LoginScreen(
                    onNavigateToRegister = { navController.navigate(Route.Register) },
                    onLoginSuccess = { /* AuthState listener handles graph transition */ },
                )
            }
            composable<Route.Register> {
                RegisterScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onRegisterSuccess = { /* AuthState listener handles graph transition */ },
                )
            }
        }

        navigation<Route.MainGraph>(startDestination = Route.Home) {
            composable<Route.Home> {
                HomePlaceholderScreen(
                    onSignOut = authGateViewModel::signOut,
                )
            }
        }
    }
}

private fun androidx.navigation.NavController.navigateToAuth() {
    navigate(Route.AuthGraph) {
        popUpTo(graph.id) { inclusive = true }
        launchSingleTop = true
    }
}

private fun androidx.navigation.NavController.navigateToMain() {
    navigate(Route.MainGraph) {
        popUpTo(graph.id) { inclusive = true }
        launchSingleTop = true
    }
}
