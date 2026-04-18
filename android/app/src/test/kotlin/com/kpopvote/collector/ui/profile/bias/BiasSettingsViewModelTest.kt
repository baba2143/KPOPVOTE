package com.kpopvote.collector.ui.profile.bias

import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.MasterDataRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class BiasSettingsViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var masterRepo: MasterDataRepository
    private lateinit var biasRepo: BiasRepository

    private val groupA = GroupMaster(id = "g1", name = "BTS")
    private val groupB = GroupMaster(id = "g2", name = "TWICE")
    private val idol1 = IdolMaster(id = "i1", name = "RM", groupName = "BTS")
    private val idol2 = IdolMaster(id = "i2", name = "Jin", groupName = "BTS")
    private val idol3 = IdolMaster(id = "i3", name = "Nayeon", groupName = "TWICE")

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        masterRepo = mockk()
        biasRepo = mockk()
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    private fun stubMasters() {
        coEvery { masterRepo.refreshGroups(any()) } returns Result.success(listOf(groupA, groupB))
        coEvery { masterRepo.refreshIdols(any(), any()) } returns
            Result.success(listOf(idol1, idol2, idol3))
    }

    @Test
    fun `load hydrates groups idols and selected state from getBias`() = runTest {
        stubMasters()
        coEvery { biasRepo.getBias() } returns Result.success(
            listOf(
                BiasSettings(
                    artistId = "g1",
                    artistName = "BTS",
                    isGroupLevel = true,
                ),
                BiasSettings(
                    artistId = "twice",
                    artistName = "TWICE",
                    memberIds = listOf("i3"),
                    memberNames = listOf("Nayeon"),
                    isGroupLevel = false,
                ),
            )
        )

        val vm = BiasSettingsViewModel(masterRepo, biasRepo)
        dispatcher.scheduler.advanceUntilIdle()

        val s = vm.state.value
        assertEquals(setOf("g1"), s.selectedGroupIds)
        assertEquals(setOf("i3"), s.selectedIdolIds)
        assertEquals(2, s.allGroups.size)
        assertEquals(3, s.allIdols.size)
    }

    @Test
    fun `toggleIdol adds and removes selection`() = runTest {
        stubMasters()
        coEvery { biasRepo.getBias() } returns Result.success(emptyList())

        val vm = BiasSettingsViewModel(masterRepo, biasRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleIdol("i1")
        assertTrue(vm.state.value.selectedIdolIds.contains("i1"))

        vm.toggleIdol("i1")
        assertTrue(vm.state.value.selectedIdolIds.isEmpty())
    }

    @Test
    fun `save builds group-level and member-level settings mixed`() = runTest {
        stubMasters()
        coEvery { biasRepo.getBias() } returns Result.success(emptyList())
        val captured = slot<List<BiasSettings>>()
        coEvery { biasRepo.setBias(capture(captured)) } returns Result.success(Unit)

        val vm = BiasSettingsViewModel(masterRepo, biasRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleGroup("g1")          // BTS group-level
        vm.toggleIdol("i3")           // TWICE > Nayeon member-level
        vm.save()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { biasRepo.setBias(any()) }
        val list = captured.captured
        assertEquals(2, list.size)

        val groupLevel = list.first { it.isGroupLevel }
        assertEquals("BTS", groupLevel.artistName)
        assertEquals("g1", groupLevel.artistId)

        val memberLevel = list.first { !it.isGroupLevel }
        assertEquals("TWICE", memberLevel.artistName)
        assertEquals(listOf("i3"), memberLevel.memberIds)
        assertEquals(listOf("Nayeon"), memberLevel.memberNames)

        assertTrue(vm.state.value.saved)
    }

    @Test
    fun `setMode and setSearchText update state`() = runTest {
        stubMasters()
        coEvery { biasRepo.getBias() } returns Result.success(emptyList())

        val vm = BiasSettingsViewModel(masterRepo, biasRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.setMode(BiasSelectionMode.MEMBER)
        vm.setSearchText("bts")
        assertEquals(BiasSelectionMode.MEMBER, vm.state.value.mode)
        assertEquals("bts", vm.state.value.searchText)
    }
}
