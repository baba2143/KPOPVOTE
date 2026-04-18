package com.kpopvote.collector.di

import com.google.firebase.Firebase
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.auth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.firestore
import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.functions.functions
import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.storage
import com.kpopvote.collector.core.auth.AuthStateHolder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineScope
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object FirebaseModule {

    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = Firebase.auth

    @Provides
    @Singleton
    fun provideFirebaseFirestore(): FirebaseFirestore = Firebase.firestore

    @Provides
    @Singleton
    fun provideFirebaseFunctions(): FirebaseFunctions =
        Firebase.functions("us-central1")

    @Provides
    @Singleton
    fun provideFirebaseStorage(): FirebaseStorage = Firebase.storage

    @Provides
    @Singleton
    fun provideFirebaseAppCheck(): FirebaseAppCheck = FirebaseAppCheck.getInstance()

    @Provides
    @Singleton
    fun provideAuthStateHolder(
        auth: FirebaseAuth,
        @ApplicationScope scope: CoroutineScope,
    ): AuthStateHolder = AuthStateHolder(auth, scope)
}
