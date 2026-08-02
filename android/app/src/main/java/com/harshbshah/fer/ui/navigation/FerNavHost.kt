package com.harshbshah.fer.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.ListAlt
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.harshbshah.fer.AppContainer
import com.harshbshah.fer.data.ExerciseLibrary
import com.harshbshah.fer.data.model.Exercise
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.ui.activeworkout.ActiveWorkoutScreen
import com.harshbshah.fer.ui.auth.AuthScreen
import com.harshbshah.fer.ui.dashboard.DashboardScreen
import com.harshbshah.fer.ui.exercises.ExerciseDetailScreen
import com.harshbshah.fer.ui.exercises.ExerciseLibraryScreen
import com.harshbshah.fer.ui.history.HistoryScreen
import com.harshbshah.fer.ui.history.WorkoutDetailScreen
import com.harshbshah.fer.ui.routines.ExercisePickerScreen
import com.harshbshah.fer.ui.routines.RoutineEditorScreen
import com.harshbshah.fer.ui.routines.RoutinesListScreen
import com.harshbshah.fer.ui.settings.SettingsScreen
import com.harshbshah.fer.ui.viewmodel.ActiveWorkoutViewModel
import com.harshbshah.fer.ui.viewmodel.AuthViewModel
import com.harshbshah.fer.ui.viewmodel.HistoryViewModel
import com.harshbshah.fer.ui.viewmodel.NowPlayingViewModel
import com.harshbshah.fer.ui.viewmodel.RoutinesViewModel
import com.harshbshah.fer.ui.viewmodel.SettingsViewModel
import com.harshbshah.fer.ui.viewmodel.ViewModelFactory

private object Routes {
    const val AUTH = "auth"
    const val DASHBOARD = "dashboard"
    const val ROUTINES = "routines"
    const val HISTORY = "history"
    const val EXERCISES = "exercises"
    const val SETTINGS = "settings"
    const val ACTIVE_WORKOUT = "activeWorkout"
    const val EXERCISE_PICKER = "exercisePicker"
    const val ROUTINE_EDITOR = "routineEditor/{routineId}"
    const val EXERCISE_DETAIL = "exerciseDetail/{exerciseId}"
    const val WORKOUT_DETAIL = "workoutDetail/{workoutId}"

    fun routineEditor(id: String) = "routineEditor/$id"
    fun exerciseDetail(id: String) = "exerciseDetail/$id"
    fun workoutDetail(id: String) = "workoutDetail/$id"
}

private val tabs = listOf(
    Triple(Routes.DASHBOARD, "Dashboard", Icons.Filled.Home),
    Triple(Routes.ROUTINES, "Routines", Icons.Filled.ListAlt),
    Triple(Routes.HISTORY, "History", Icons.Filled.History),
    Triple(Routes.EXERCISES, "Exercises", Icons.Filled.FitnessCenter),
    Triple(Routes.SETTINGS, "Settings", Icons.Filled.Settings)
)

@Composable
fun FerApp(container: AppContainer) {
    val factory = remember { ViewModelFactory(container) }
    val authViewModel: AuthViewModel = viewModel(factory = factory)
    val isLoading by authViewModel.isLoading.collectAsStateWithLifecycle()
    val currentUser by authViewModel.currentUser.collectAsStateWithLifecycle()

    if (isLoading) return

    if (currentUser == null) {
        AuthScreen(authViewModel)
    } else {
        MainNavHost(container, factory)
    }
}

@Composable
private fun MainNavHost(container: AppContainer, factory: ViewModelFactory) {
    val navController = rememberNavController()
    val routinesVM: RoutinesViewModel = viewModel(factory = factory)
    val historyVM: HistoryViewModel = viewModel(factory = factory)
    val settingsVM: SettingsViewModel = viewModel(factory = factory)
    val nowPlayingVM: NowPlayingViewModel = viewModel(factory = factory)
    val weightUnit by settingsVM.weightUnit.collectAsStateWithLifecycle()
    val defaultRestSeconds by settingsVM.defaultRestSeconds.collectAsStateWithLifecycle()

    var pendingWorkoutStart by remember { mutableStateOf<Pair<String, RoutineTemplate?>?>(null) }
    var pendingExercisePick by remember { mutableStateOf<((Exercise) -> Unit)?>(null) }

    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val showBottomBar = tabs.any { it.first == currentRoute }

    Scaffold(
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    tabs.forEach { (route, label, icon) ->
                        NavigationBarItem(
                            selected = currentRoute == route,
                            onClick = {
                                navController.navigate(route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(icon, contentDescription = label) },
                            label = { Text(label) }
                        )
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Routes.DASHBOARD,
            modifier = Modifier.padding(padding)
        ) {
            composable(Routes.DASHBOARD) {
                DashboardScreen(
                    routinesVM = routinesVM,
                    historyVM = historyVM,
                    weightUnit = weightUnit,
                    onStartBlank = {
                        pendingWorkoutStart = "Quick Workout" to null
                        navController.navigate(Routes.ACTIVE_WORKOUT)
                    },
                    onStartRoutine = { routine ->
                        pendingWorkoutStart = routine.name to routine
                        navController.navigate(Routes.ACTIVE_WORKOUT)
                    },
                    onOpenWorkout = { workout -> navController.navigate(Routes.workoutDetail(workout.id ?: "")) }
                )
            }

            composable(Routes.ROUTINES) {
                RoutinesListScreen(
                    viewModel = routinesVM,
                    onStart = { routine ->
                        pendingWorkoutStart = routine.name to routine
                        navController.navigate(Routes.ACTIVE_WORKOUT)
                    },
                    onEdit = { routine -> navController.navigate(Routes.routineEditor(routine.id ?: "new")) }
                )
            }

            composable(Routes.HISTORY) {
                HistoryScreen(
                    viewModel = historyVM,
                    weightUnit = weightUnit,
                    onOpenWorkout = { workout -> navController.navigate(Routes.workoutDetail(workout.id ?: "")) }
                )
            }

            composable(Routes.EXERCISES) {
                ExerciseLibraryScreen(
                    historyVM = historyVM,
                    onOpenExercise = { exercise -> navController.navigate(Routes.exerciseDetail(exercise.id)) }
                )
            }

            composable(Routes.SETTINGS) {
                SettingsScreen(settingsVM)
            }

            composable(Routes.ROUTINE_EDITOR) { entry ->
                val routineId = entry.arguments?.getString("routineId")
                val initialRoutine = if (routineId == "new") {
                    RoutineTemplate(name = "New Routine")
                } else {
                    routinesVM.routines.value.firstOrNull { it.id == routineId } ?: RoutineTemplate(name = "New Routine")
                }
                RoutineEditorScreen(
                    viewModel = routinesVM,
                    initialRoutine = initialRoutine,
                    defaultRestSeconds = defaultRestSeconds,
                    onPickExercise = { onPicked ->
                        pendingExercisePick = onPicked
                        navController.navigate(Routes.EXERCISE_PICKER)
                    },
                    onClose = { navController.popBackStack() }
                )
            }

            composable(Routes.EXERCISE_PICKER) {
                ExercisePickerScreen(
                    onPick = { exercise -> pendingExercisePick?.invoke(exercise) },
                    onClose = { navController.popBackStack() }
                )
            }

            composable(Routes.EXERCISE_DETAIL) { entry ->
                val exerciseId = entry.arguments?.getString("exerciseId") ?: ""
                val exercise = ExerciseLibrary.byId(exerciseId)
                if (exercise != null) {
                    ExerciseDetailScreen(exercise, historyVM, weightUnit)
                }
            }

            composable(Routes.WORKOUT_DETAIL) { entry ->
                val workoutId = entry.arguments?.getString("workoutId") ?: ""
                val workout by historyVM.workouts.collectAsStateWithLifecycle()
                val found = workout.firstOrNull { it.id == workoutId }
                if (found != null) {
                    WorkoutDetailScreen(found, weightUnit)
                }
            }

            composable(Routes.ACTIVE_WORKOUT) {
                val start = pendingWorkoutStart
                val (routineName, exercises) = remember(start) {
                    val routine = start?.second
                    if (routine != null) {
                        ActiveWorkoutViewModel.fromRoutine(routine)
                    } else {
                        (start?.first ?: "Quick Workout") to emptyList()
                    }
                }
                val activeWorkoutVM: ActiveWorkoutViewModel = viewModel(
                    factory = object : androidx.lifecycle.ViewModelProvider.Factory {
                        override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
                            @Suppress("UNCHECKED_CAST")
                            val vm = ActiveWorkoutViewModel(
                                container.firestoreRepository,
                                routineName,
                                exercises,
                                defaultRestSeconds
                            )
                            start?.second?.let { vm.setRestSecondsFor(it) }
                            return vm as T
                        }
                    }
                )
                ActiveWorkoutScreen(
                    viewModel = activeWorkoutVM,
                    nowPlayingViewModel = nowPlayingVM,
                    weightUnit = weightUnit,
                    onAddExercise = {
                        pendingExercisePick = { exercise -> activeWorkoutVM.addExercise(exercise) }
                        navController.navigate(Routes.EXERCISE_PICKER)
                    },
                    onFinished = {
                        pendingWorkoutStart = null
                        navController.popBackStack(Routes.DASHBOARD, inclusive = false)
                    },
                    onDiscarded = {
                        pendingWorkoutStart = null
                        navController.popBackStack(Routes.DASHBOARD, inclusive = false)
                    }
                )
            }
        }
    }
}
