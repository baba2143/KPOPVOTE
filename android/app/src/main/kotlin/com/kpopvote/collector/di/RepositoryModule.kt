package com.kpopvote.collector.di

import com.kpopvote.collector.data.repository.AuthRepository
import com.kpopvote.collector.data.repository.AuthRepositoryImpl
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.BiasRepositoryImpl
import com.kpopvote.collector.data.repository.MasterDataRepository
import com.kpopvote.collector.data.repository.MasterDataRepositoryImpl
import com.kpopvote.collector.data.repository.OgpRepository
import com.kpopvote.collector.data.repository.OgpRepositoryImpl
import com.kpopvote.collector.data.repository.StorageRepository
import com.kpopvote.collector.data.repository.StorageRepositoryImpl
import com.kpopvote.collector.data.repository.TaskCoverImageRepository
import com.kpopvote.collector.data.repository.TaskCoverImageRepositoryImpl
import com.kpopvote.collector.data.repository.TaskRepository
import com.kpopvote.collector.data.repository.TaskRepositoryImpl
import com.kpopvote.collector.data.repository.UserRepository
import com.kpopvote.collector.data.repository.UserRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds
    @Singleton
    abstract fun bindMasterDataRepository(impl: MasterDataRepositoryImpl): MasterDataRepository

    @Binds
    @Singleton
    abstract fun bindBiasRepository(impl: BiasRepositoryImpl): BiasRepository

    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository

    @Binds
    @Singleton
    abstract fun bindStorageRepository(impl: StorageRepositoryImpl): StorageRepository

    @Binds
    @Singleton
    abstract fun bindTaskRepository(impl: TaskRepositoryImpl): TaskRepository

    @Binds
    @Singleton
    abstract fun bindTaskCoverImageRepository(
        impl: TaskCoverImageRepositoryImpl
    ): TaskCoverImageRepository

    @Binds
    @Singleton
    abstract fun bindOgpRepository(impl: OgpRepositoryImpl): OgpRepository
}
