package com.kpopvote.collector.ui.main

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.kpopvote.collector.navigation.Route
import com.kpopvote.collector.ui.home.HomeScreen
import com.kpopvote.collector.ui.tasks.TaskListScreen

/**
 * iOS `MainTabView` equivalent: 5 bottom tabs (Home / Ranking / Votes / Community / Profile)
 * plus a central "+" FAB that launches the create-task flow. Only Home is fully implemented
 * in Sprint 3; the other 4 tabs display placeholders until their respective sprints land.
 *
 * The [TaskListScreen] is NOT a tab — iOS reaches it via Home's "一覧を見る" link, and so do we.
 */
@Composable
fun MainTabScreen(
    rootNavController: NavHostController,
    onSignOut: () -> Unit,
) {
    val tabNavController = rememberNavController()
    val backStackEntry by tabNavController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route.orEmpty()

    Scaffold(
        bottomBar = {
            NavigationBar {
                TAB_ITEMS.forEach { item ->
                    val selected = currentRoute.startsWith(item.routeClassName)
                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            tabNavController.navigate(item.route) {
                                popUpTo(Route.Home) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(item.icon, contentDescription = item.label) },
                        label = { Text(item.label) },
                    )
                }
            }
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { rootNavController.navigate(Route.AddTask()) },
                containerColor = MaterialTheme.colorScheme.primary,
            ) {
                Icon(Icons.Filled.Add, contentDescription = "タスクを追加")
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = tabNavController,
            startDestination = Route.Home,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable<Route.Home> {
                HomeScreen(
                    onOpenTaskList = {
                        tabNavController.navigate(Route.TaskList)
                    },
                    onEditTask = { taskId -> rootNavController.navigate(Route.AddTask(taskId)) },
                )
            }
            composable<Route.TaskList> {
                TaskListScreen(
                    onBack = { tabNavController.popBackStack() },
                    onEditTask = { taskId -> rootNavController.navigate(Route.AddTask(taskId)) },
                )
            }
            composable<Route.Ranking> { PlaceholderTab("Ranking", "Sprint 6 で実装予定") }
            composable<Route.Votes> { PlaceholderTab("Votes", "Sprint 4 で実装予定") }
            composable<Route.Community> { PlaceholderTab("Community", "Sprint 5 で実装予定") }
            composable<Route.Profile> { ProfilePlaceholderTab(onSignOut = onSignOut) }
        }
    }
}

@Composable
private fun PlaceholderTab(title: String, subtitle: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text(title, style = MaterialTheme.typography.headlineMedium)
            Text(subtitle, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
private fun ProfilePlaceholderTab(onSignOut: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text("Profile", style = MaterialTheme.typography.headlineMedium)
            Text("Sprint 7 で実装予定", style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.height(16.dp))
            TextButton(onClick = onSignOut) { Text("サインアウト") }
        }
    }
}

private data class TabItem(
    val route: Route,
    val routeClassName: String,
    val icon: ImageVector,
    val label: String,
)

private val TAB_ITEMS = listOf(
    TabItem(Route.Home, Route.Home::class.qualifiedName.orEmpty(), Icons.Filled.Home, "Home"),
    TabItem(Route.Ranking, Route.Ranking::class.qualifiedName.orEmpty(), Icons.Filled.EmojiEvents, "Ranking"),
    TabItem(Route.Votes, Route.Votes::class.qualifiedName.orEmpty(), Icons.Filled.BarChart, "Votes"),
    TabItem(Route.Community, Route.Community::class.qualifiedName.orEmpty(), Icons.Filled.Forum, "Community"),
    TabItem(Route.Profile, Route.Profile::class.qualifiedName.orEmpty(), Icons.Filled.Person, "Profile"),
)
