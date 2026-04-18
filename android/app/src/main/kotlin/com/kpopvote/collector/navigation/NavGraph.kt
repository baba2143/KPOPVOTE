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
import com.kpopvote.collector.ui.main.MainTabScreen
import com.kpopvote.collector.ui.tasks.AddEditTaskScreen
import com.kpopvote.collector.ui.vote.VoteDetailScreen
import com.kpopvote.collector.ui.vote.VoteListScreen
import com.kpopvote.collector.ui.vote.VoteRankingScreen
import com.kpopvote.collector.ui.votestab.detail.CollectionDetailScreen
import com.kpopvote.collector.ui.votestab.edit.CreateCollectionScreen

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
                MainTabScreen(
                    rootNavController = navController,
                    onSignOut = authGateViewModel::signOut,
                )
            }
        }

        composable<Route.AddTask> {
            // taskId is passed through Route.AddTask and surfaced via SavedStateHandle
            // for AddEditTaskViewModel (see `savedStateHandle.get<String>("taskId")`).
            AddEditTaskScreen(
                onBack = { navController.popBackStack() },
            )
        }

        composable<Route.VoteList> {
            VoteListScreen(
                onBack = { navController.popBackStack() },
                onOpenVote = { voteId -> navController.navigate(Route.VoteDetail(voteId)) },
            )
        }

        composable<Route.VoteDetail> {
            VoteDetailScreen(
                onBack = { navController.popBackStack() },
                onOpenRanking = { voteId -> navController.navigate(Route.VoteRanking(voteId)) },
            )
        }

        composable<Route.VoteRanking> {
            VoteRankingScreen(
                onBack = { navController.popBackStack() },
            )
        }

        composable<Route.CollectionDetail> {
            CollectionDetailScreen(
                onBack = { navController.popBackStack() },
                onEditCollection = { id -> navController.navigate(Route.CollectionEdit(id)) },
            )
        }

        composable<Route.CollectionCreate> {
            CreateCollectionScreen(
                onBack = { navController.popBackStack() },
            )
        }

        composable<Route.CollectionEdit> {
            CreateCollectionScreen(
                onBack = { navController.popBackStack() },
            )
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
