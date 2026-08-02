@file:OptIn(dev.chrisbanes.haze.materials.ExperimentalHazeMaterialsApi::class)

package com.harshbshah.fer.ui.navigation

import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.ListAlt
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.harshbshah.fer.AppContainer
import dev.chrisbanes.haze.HazeState
import dev.chrisbanes.haze.hazeEffect
import dev.chrisbanes.haze.hazeSource
import dev.chrisbanes.haze.materials.HazeMaterials
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

private val routesWithOwnTopBar = setOf(Routes.ACTIVE_WORKOUT, Routes.ROUTINE_EDITOR, Routes.EXERCISE_PICKER)

/** Bottom nav bar is a floating glass surface over edge-to-edge content, not a
 *  layout-reserving one — tab screens add this as bottom content padding so
 *  their last item scrolls clear of it instead of hiding underneath. Generous
 *  on purpose: the pill's own margin + shadow + system nav-bar inset add up
 *  to more than the pill's own visual height. */
val BottomNavHeight = 130.dp

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
    val hasOwnScaffold = currentRoute in routesWithOwnTopBar
    val navHazeState = remember { HazeState() }

    // Routes with their own Scaffold+TopAppBar (Active Workout, Routine Editor,
    // Exercise Picker) manage all their own insets — applying any here would
    // double up with theirs (that double-inset was the "blank gap" bug on
    // Active Workout). Tab routes get top-only inset + a haze source so the
    // floating glass nav bar below has something to blur; everything else
    // (Exercise/Workout detail, which have no TopAppBar and aren't behind the
    // nav bar) gets full inset clearance like a normal screen.
    val navHostModifier = when {
        hasOwnScaffold -> Modifier.fillMaxSize()
        showBottomBar -> Modifier.fillMaxSize().statusBarsPadding().hazeSource(navHazeState)
        else -> Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        NavHost(
            navController = navController,
            startDestination = Routes.DASHBOARD,
            modifier = navHostModifier,
            // Navigation-Compose's own default transition reads as sluggish
            // and washed-out at this app's snappy, haptic-forward pace — a
            // short, sharp cross-fade instead.
            enterTransition = { fadeIn(tween(120)) },
            exitTransition = { fadeOut(tween(120)) },
            popEnterTransition = { fadeIn(tween(120)) },
            popExitTransition = { fadeOut(tween(120)) }
        ) {
            composable(Routes.DASHBOARD) {
                DashboardScreen(
                    routinesVM = routinesVM,
                    historyVM = historyVM,
                    weightUnit = weightUnit,
                    bottomContentPadding = BottomNavHeight,
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
                    bottomContentPadding = BottomNavHeight,
                    onAddRoutine = { navController.navigate(Routes.routineEditor("new")) },
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
                    bottomContentPadding = BottomNavHeight,
                    onOpenWorkout = { workout -> navController.navigate(Routes.workoutDetail(workout.id ?: "")) }
                )
            }

            composable(Routes.EXERCISES) {
                ExerciseLibraryScreen(
                    historyVM = historyVM,
                    bottomContentPadding = BottomNavHeight,
                    onOpenExercise = { exercise -> navController.navigate(Routes.exerciseDetail(exercise.id)) }
                )
            }

            composable(Routes.SETTINGS) {
                SettingsScreen(settingsVM, bottomContentPadding = BottomNavHeight)
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
                                defaultRestSeconds,
                                pastWorkouts = historyVM.workouts.value
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

        if (showBottomBar) {
            // A floating glass pill rather than an edge-to-edge NavigationBar
            // — Material3's NavigationBar/NavigationBarItem assume full-width
            // edge placement (their own internal insets/sizing fight a
            // wrap-content pill), so this is a plain Row of custom tab
            // buttons inside a pill-shaped Surface instead.
            Surface(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .navigationBarsPadding()
                    .padding(bottom = 8.dp)
                    .shadow(elevation = 8.dp, shape = RoundedCornerShape(50))
                    .hazeEffect(state = navHazeState, style = HazeMaterials.regular()),
                shape = RoundedCornerShape(50),
                color = Color.Transparent
            ) {
                // fillMaxWidth + weight(1f) per tab (not wrap-content sizing)
                // — a wrap-content pill overflowed past the screen edge with
                // all 5 labels showing, silently pushing Settings off-screen.
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    tabs.forEach { (route, label, icon) ->
                        val selected = currentRoute == route
                        Column(
                            modifier = Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(50))
                                .background(
                                    if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.14f) else Color.Transparent
                                )
                                .clickable {
                                    navController.navigate(route) {
                                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                                .padding(horizontal = 4.dp, vertical = 8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                icon,
                                contentDescription = label,
                                tint = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                label,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}
