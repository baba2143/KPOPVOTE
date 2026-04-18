package com.kpopvote.collector.di

import com.kpopvote.collector.data.repository.AuthRepository
import com.kpopvote.collector.data.repository.AuthRepositoryImpl
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.BiasRepositoryImpl
import com.kpopvote.collector.data.repository.CollectionCoverImageRepository
import com.kpopvote.collector.data.repository.CollectionCoverImageRepositoryImpl
import com.kpopvote.collector.data.repository.CollectionRepository
import com.kpopvote.collector.data.repository.CollectionRepositoryImpl
import com.kpopvote.collector.data.repository.FcmTokenRepository
import com.kpopvote.collector.data.repository.FcmTokenRepositoryImpl
import com.kpopvote.collector.data.repository.InviteRepository
import com.kpopvote.collector.data.repository.InviteRepositoryImpl
import com.kpopvote.collector.data.repository.MasterDataRepository
import com.kpopvote.collector.data.repository.MasterDataRepositoryImpl
import com.kpopvote.collector.data.repository.OgpRepository
import com.kpopvote.collector.data.repository.OgpRepositoryImpl
import com.kpopvote.collector.data.repository.ProfileImageRepository
import com.kpopvote.collector.data.repository.ProfileImageRepositoryImpl
import com.kpopvote.collector.data.repository.StorageRepository
import com.kpopvote.collector.data.repository.StorageRepositoryImpl
import com.kpopvote.collector.data.repository.TaskCoverImageRepository
import com.kpopvote.collector.data.repository.TaskCoverImageRepositoryImpl
import com.kpopvote.collector.data.repository.TaskRepository
import com.kpopvote.collector.data.repository.TaskRepositoryImpl
import com.kpopvote.collector.data.repository.UserRepository
import com.kpopvote.collector.data.repository.UserRepositoryImpl
import com.kpopvote.collector.data.repository.VoteRepository
import com.kpopvote.collector.data.repository.VoteRepositoryImpl
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

    @Binds
    @Singleton
    abstract fun bindVoteRepository(impl: VoteRepositoryImpl): VoteRepository

    @Binds
    @Singleton
    abstract fun bindCollectionRepository(impl: CollectionRepositoryImpl): CollectionRepository

    @Binds
    @Singleton
    abstract fun bindCollectionCoverImageRepository(
        impl: CollectionCoverImageRepositoryImpl
    ): CollectionCoverImageRepository

    @Binds
    @Singleton
    abstract fun bindInviteRepository(impl: InviteRepositoryImpl): InviteRepository

    @Binds
    @Singleton
    abstract fun bindProfileImageRepository(
        impl: ProfileImageRepositoryImpl
    ): ProfileImageRepository

    @Binds
    @Singleton
    abstract fun bindFcmTokenRepository(impl: FcmTokenRepositoryImpl): FcmTokenRepository
}
