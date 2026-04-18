package com.kpopvote.collector.ui.tasks

import androidx.lifecycle.SavedStateHandle
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.CoverImageSource
import com.kpopvote.collector.data.model.ExternalAppMaster
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.model.MasterDataCache
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.MasterDataRepository
import com.kpopvote.collector.data.repository.TaskCoverImageRepository
import com.kpopvote.collector.data.repository.TaskInput
import com.kpopvote.collector.data.repository.TaskRepository
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AddEditTaskViewModelTest {

    private val dispatcher = StandardTestDispatcher()

    private lateinit var taskRepository: TaskRepository
    private lateinit var biasRepository: BiasRepository
    private lateinit var masterDataRepository: MasterDataRepository
    private lateinit var coverImageRepository: TaskCoverImageRepository

    private val externalApp = ExternalAppMaster(
        id = "app1",
        appName = "Mubeat",
        appUrl = "https://mubeat.tv",
        defaultCoverImageUrl = "https://img/app1.png",
    )
    private val idol = IdolMaster(id = "m1", name = "Member1", groupName = "Group1")
    private val group = GroupMaster(id = "g1", name = "Group1")

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        taskRepository = mockk(relaxed = true)
        biasRepository = mockk(relaxed = true)
        masterDataRepository = mockk(relaxed = true) {
            every { externalApps } returns
                MutableStateFlow(MasterDataCache.Success(listOf(externalApp), 0L)) as StateFlow<MasterDataCache<ExternalAppMaster>>
            every { idols } returns
                MutableStateFlow(MasterDataCache.Success(listOf(idol), 0L)) as StateFlow<MasterDataCache<IdolMaster>>
            every { groups } returns
                MutableStateFlow(MasterDataCache.Success(listOf(group), 0L)) as StateFlow<MasterDataCache<GroupMaster>>
        }
        coverImageRepository = mockk(relaxed = true)

        coEvery { masterDataRepository.refreshExternalApps(any()) } returns Result.success(listOf(externalApp))
        coEvery { masterDataRepository.refreshIdols(any(), any()) } returns Result.success(listOf(idol))
        coEvery { masterDataRepository.refreshGroups(any()) } returns Result.success(listOf(group))
        coEvery { biasRepository.getBias() } returns
            Result.success(listOf(BiasSettings("g1", "Group1", listOf("m1"), listOf("Member1"))))
    }

    @After
    fun teardown() {
        Dispatchers.resetMain()
    }

    private fun vm(taskId: String? = null): AddEditTaskViewModel = AddEditTaskViewModel(
        savedStateHandle = SavedStateHandle(
            if (taskId != null) mapOf("taskId" to taskId) else emptyMap(),
        ),
        taskRepository = taskRepository,
        biasRepository = biasRepository,
        masterDataRepository = masterDataRepository,
        coverImageRepository = coverImageRepository,
    )

    @Test
    fun `new mode seeds default members from bias`() = runTest {
        val model = vm()
        dispatcher.scheduler.advanceUntilIdle()
        assertEquals(listOf("m1"), model.state.value.selectedMemberIds)
        assertFalse(model.state.value.isEditMode)
    }

    @Test
    fun `edit mode presets fields from existing task`() = runTest {
        val existing = VoteTask(
            id = "t1",
            userId = "u1",
            title = "Existing",
            url = "https://a",
            deadlineIso = "2099-01-01T00:00:00Z",
            status = TaskStatus.PENDING,
            biasIds = listOf("m1"),
            externalAppId = "app1",
            coverImage = "https://img",
            coverImageSource = CoverImageSource.EXTERNAL_APP,
        )
        coEvery { taskRepository.getUserTasks(null) } returns Result.success(listOf(existing))

        val model = vm(taskId = "t1")
        dispatcher.scheduler.advanceUntilIdle()

        val state = model.state.value
        assertTrue(state.isEditMode)
        assertEquals("Existing", state.title)
        assertEquals("https://a", state.url)
        assertEquals(listOf("m1"), state.selectedMemberIds)
        assertEquals("app1", state.selectedAppId)
        assertEquals("https://img", state.coverImageUrl)
        assertEquals(CoverImageSource.EXTERNAL_APP, state.coverImageSource)
        assertNotNull(state.deadlineMillis)
    }

    @Test
    fun `selecting external app sets default cover`() = runTest {
        val model = vm()
        dispatcher.scheduler.advanceUntilIdle()

        model.onExternalAppSelected("app1")
        assertEquals("https://img/app1.png", model.state.value.coverImageUrl)
        assertEquals(CoverImageSource.EXTERNAL_APP, model.state.value.coverImageSource)
    }

    @Test
    fun `form is invalid when url or deadline is missing`() = runTest {
        val model = vm()
        dispatcher.scheduler.advanceUntilIdle()

        model.onTitleChange("t")
        model.onUrlChange("not-a-url")
        assertFalse(model.state.value.isFormValid)

        model.onUrlChange("https://ok")
        assertFalse("deadline still missing", model.state.value.isFormValid)

        model.onDeadlineChange(System.currentTimeMillis() + 3_600_000L)
        assertTrue(model.state.value.isFormValid)
    }

    @Test
    fun `submit calls registerTask in new mode`() = runTest {
        val inputSlot = slot<TaskInput>()
        coEvery { taskRepository.registerTask(capture(inputSlot)) } returns Result.success(
            VoteTask(
                id = "new",
                userId = "u1",
                title = "t",
                url = "https://ok",
                deadlineIso = "2099-01-01T00:00:00Z",
            ),
        )

        val model = vm()
        dispatcher.scheduler.advanceUntilIdle()
        model.onTitleChange("t")
        model.onUrlChange("https://ok")
        model.onDeadlineChange(System.currentTimeMillis() + 3_600_000L)
        model.submit()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("t", inputSlot.captured.title)
        assertEquals("https://ok", inputSlot.captured.url)
        assertTrue(model.state.value.submitted)
    }

    @Test
    fun `url validation accepts http and https only`() {
        assertTrue(AddEditTaskUiState.isUrlValid("http://a"))
        assertTrue(AddEditTaskUiState.isUrlValid("https://a"))
        assertFalse(AddEditTaskUiState.isUrlValid(""))
        assertFalse(AddEditTaskUiState.isUrlValid("ftp://a"))
        assertFalse(AddEditTaskUiState.isUrlValid("example.com"))
    }
}
