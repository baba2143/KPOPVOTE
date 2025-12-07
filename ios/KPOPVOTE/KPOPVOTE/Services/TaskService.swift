//
//  TaskService.swift
//  OSHI Pick
//
//  OSHI Pick - Task Management Service
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import UIKit

class TaskService: ObservableObject {
    @Published var tasks: [VoteTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Get User Tasks
    func getUserTasks(isCompleted: Bool? = nil) async throws -> [VoteTask] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw TaskError.notAuthenticated
        }

        var urlString = Constants.API.getUserTasks
        if let isCompleted = isCompleted {
            urlString += "?isCompleted=\(isCompleted)"
        }

        guard let url = URL(string: urlString) else {
            throw TaskError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("📡 [TaskService] Fetching tasks from: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        debugLog("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // デバッグ: レスポンスの生データを確認
        if let responseString = String(data: data, encoding: .utf8) {
            debugLog("📥 [TaskService] Response JSON: \(responseString)")
        }

        // Cloud Functionのレスポンスを直接デコード
        let result = try JSONDecoder().decode(GetUserTasksResponse.self, from: data)
        debugLog("✅ [TaskService] Fetched \(result.data.tasks.count) tasks")
        debugLog("📊 [TaskService] Task count from API: \(result.data.count)")

        // 現在のユーザーIDを取得
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TaskError.notAuthenticated
        }

        // VoteTaskオブジェクトの配列を構築
        let voteTasks = result.data.tasks.map { task -> VoteTask in
            // ISO 8601文字列をDateに変換
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            guard let deadline = isoFormatter.date(from: task.deadline) else {
                debugLog("❌ [TaskService] Failed to parse deadline: '\(task.deadline)'")
                debugLog("❌ [TaskService] Using Date() fallback, task will expire immediately")
                return VoteTask(
                    id: task.taskId,
                    userId: Auth.auth().currentUser?.uid ?? "",
                    title: task.title,
                    url: task.url,
                    deadline: Date(),
                    status: .expired,
                    biasIds: task.targetMembers,
                    externalAppId: task.externalAppId,
                    externalAppName: task.externalAppName,
                    externalAppIconUrl: task.externalAppIconUrl,
                    coverImage: task.coverImage,
                    coverImageSource: task.coverImageSource.flatMap { CoverImageSource(rawValue: $0) }
                )
            }

            let _ = task.createdAt.flatMap { isoFormatter.date(from: $0) } ?? Date()
            let _ = task.updatedAt.flatMap { isoFormatter.date(from: $0) } ?? Date()

            // isCompletedからstatusを推測
            let status: VoteTask.TaskStatus = task.isCompleted ? .completed :
                                              (deadline < Date() ? .expired : .pending)

            debugLog("📋 [TaskService] Task: \(task.title), Deadline: \(task.deadline), Status: \(status)")

            // Convert coverImageSource string to enum
            let coverImageSource: CoverImageSource? = {
                guard let sourceString = task.coverImageSource else { return nil }
                return CoverImageSource(rawValue: sourceString)
            }()

            return VoteTask(
                id: task.taskId,
                userId: userId,
                title: task.title,
                url: task.url,
                deadline: deadline,
                status: status,
                biasIds: task.targetMembers,
                externalAppId: task.externalAppId,
                externalAppName: task.externalAppName,
                externalAppIconUrl: task.externalAppIconUrl,
                coverImage: task.coverImage,
                coverImageSource: coverImageSource
            )
        }

        debugLog("✅ [TaskService] Converted \(voteTasks.count) VoteTasks")
        return voteTasks
    }

    // MARK: - Get Active Tasks
    func getActiveTasks() async throws -> [VoteTask] {
        let allTasks = try await getUserTasks(isCompleted: false)
        debugLog("📊 [TaskService] Total tasks retrieved: \(allTasks.count)")

        // Filter active tasks (deadline in future and not archived)
        let now = Date()
        debugLog("🕐 [TaskService] Current time: \(now)")

        let activeTasks = allTasks.filter { task in
            let timeInterval = task.deadline.timeIntervalSince(now)
            let hours = timeInterval / 3600
            let isActive = timeInterval > 0 && !task.isArchived
            debugLog("📋 [TaskService] Task '\(task.title)': deadline in \(hours) hours, archived: \(task.isArchived), active: \(isActive)")
            return isActive
        }

        debugLog("✅ [TaskService] Found \(activeTasks.count) active tasks out of \(allTasks.count) total")
        return activeTasks.sorted { $0.deadline < $1.deadline }
    }

    // MARK: - Mark Task as Completed
    func markTaskAsCompleted(taskId: String) async throws -> Int? {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw TaskError.notAuthenticated
        }

        let urlString = Constants.API.updateTaskStatus
        guard let url = URL(string: urlString) else {
            throw TaskError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "taskId": taskId,
            "isCompleted": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("📡 [TaskService] Marking task as completed: \(taskId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        debugLog("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // レスポンスからpointsGrantedを取得
        var pointsGranted: Int? = nil
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataDict = json["data"] as? [String: Any],
           let points = dataDict["pointsGranted"] as? Int {
            pointsGranted = points
            debugLog("✅ [TaskService] Task completed with \(points) points granted")
        }

        debugLog("✅ [TaskService] Task marked as completed: \(taskId)")
        return pointsGranted
    }

    // MARK: - Upload Cover Image
    func uploadCoverImage(_ image: UIImage) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TaskError.notAuthenticated
        }

        // Compress and convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw TaskError.imageCompressionFailed
        }

        // Check file size (max 10MB)
        let maxSize = 10 * 1024 * 1024 // 10MB
        guard imageData.count <= maxSize else {
            throw TaskError.imageTooLarge
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storagePath = "task-cover-images/\(userId)/\(filename)"

        // Get Firebase Storage reference
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(storagePath)

        debugLog("📤 [TaskService] Uploading cover image to: \(storagePath)")

        // Upload image data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await imageRef.downloadURL()
        let downloadURLString = downloadURL.absoluteString

        debugLog("✅ [TaskService] Cover image uploaded: \(downloadURLString)")

        return downloadURLString
    }

    // MARK: - Register New Task
    func registerTask(
        title: String,
        url: String,
        deadline: Date,
        biasIds: [String],
        externalAppId: String? = nil,
        coverImage: String? = nil,
        coverImageSource: CoverImageSource? = nil
    ) async throws -> VoteTask {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw TaskError.notAuthenticated
        }

        let urlString = Constants.API.registerTask
        guard let requestUrl = URL(string: urlString) else {
            throw TaskError.invalidURL
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Convert deadline to ISO 8601 format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let deadlineString = isoFormatter.string(from: deadline)

        var body: [String: Any] = [
            "title": title,
            "url": url,
            "deadline": deadlineString,
            "targetMembers": biasIds
        ]

        // Add externalAppId if provided
        if let externalAppId = externalAppId {
            body["externalAppId"] = externalAppId
        }

        // Add coverImage if provided
        if let coverImage = coverImage {
            body["coverImage"] = coverImage
        }

        // Add coverImageSource if provided
        if let coverImageSource = coverImageSource {
            body["coverImageSource"] = coverImageSource.rawValue
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("📡 [TaskService] Registering new task: \(title)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        debugLog("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // Cloud Functionのレスポンスを直接デコード
        let result = try JSONDecoder().decode(RegisterTaskSimpleResponse.self, from: data)
        debugLog("✅ [TaskService] Task registered: \(result.data.taskId)")

        // VoteTaskオブジェクトを構築して返す
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TaskError.notAuthenticated
        }

        return VoteTask(
            id: result.data.taskId,
            userId: userId,
            title: result.data.title,
            url: result.data.url,
            deadline: deadline,
            status: .pending,
            biasIds: result.data.targetMembers,
            externalAppId: result.data.externalAppId,
            externalAppName: nil,
            externalAppIconUrl: nil,
            coverImage: result.data.coverImage,
            coverImageSource: result.data.coverImageSource
        )
    }

    // MARK: - Delete Task
    func deleteTask(taskId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw TaskError.notAuthenticated
        }

        let urlString = Constants.API.deleteTask
        guard let url = URL(string: urlString) else {
            throw TaskError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "taskId": taskId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("📡 [TaskService] Deleting task: \(taskId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        debugLog("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        debugLog("✅ [TaskService] Task deleted successfully: \(taskId)")
    }

    // MARK: - Update Existing Task
    func updateTask(
        taskId: String,
        title: String,
        url: String,
        deadline: Date,
        biasIds: [String],
        externalAppId: String? = nil,
        coverImage: String? = nil,
        coverImageSource: CoverImageSource? = nil
    ) async throws -> VoteTask {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw TaskError.notAuthenticated
        }

        let urlString = Constants.API.updateTask
        guard let requestUrl = URL(string: urlString) else {
            throw TaskError.invalidURL
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Convert deadline to ISO 8601 format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let deadlineString = isoFormatter.string(from: deadline)

        var body: [String: Any] = [
            "taskId": taskId,
            "title": title,
            "url": url,
            "deadline": deadlineString,
            "targetMembers": biasIds
        ]

        // Add optional fields
        if let externalAppId = externalAppId {
            body["externalAppId"] = externalAppId
        }
        if let coverImage = coverImage {
            body["coverImage"] = coverImage
        }
        if let coverImageSource = coverImageSource {
            body["coverImageSource"] = coverImageSource.rawValue
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("📡 [TaskService] Updating task: \(taskId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        debugLog("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // Decode response
        let result = try JSONDecoder().decode(UpdateTaskResponse.self, from: data)
        debugLog("✅ [TaskService] Task updated: \(result.data.taskId)")

        // Return updated VoteTask
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TaskError.notAuthenticated
        }

        return VoteTask(
            id: result.data.taskId,
            userId: userId,
            title: result.data.title,
            url: result.data.url,
            deadline: deadline,
            status: .pending,
            biasIds: result.data.targetMembers,
            externalAppId: result.data.externalAppId,
            externalAppName: nil,
            externalAppIconUrl: nil,
            coverImage: result.data.coverImage,
            coverImageSource: result.data.coverImageSource
        )
    }
}

// MARK: - Task Errors
enum TaskError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case imageCompressionFailed
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let code):
            return "サーバーエラーが発生しました (コード: \(code))"
        case .decodingError:
            return "データの解析に失敗しました"
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .imageTooLarge:
            return "画像サイズが大きすぎます (最大10MB)"
        }
    }
}

// MARK: - Response Models
struct TasksResponse: Codable {
    let success: Bool
    let data: TasksData

    struct TasksData: Codable {
        let tasks: [VoteTask]
    }
}

// Cloud Functionのシンプルなレスポンス構造
struct RegisterTaskSimpleResponse: Codable {
    let success: Bool
    let data: RegisterTaskSimpleData

    struct RegisterTaskSimpleData: Codable {
        let taskId: String
        let title: String
        let url: String
        let deadline: String
        let targetMembers: [String]
        let externalAppId: String?
        let isCompleted: Bool
        let completedAt: String?
        let coverImage: String?
        let coverImageSource: CoverImageSource?
    }
}

// getUserTasks Cloud Functionのレスポンス構造
struct GetUserTasksResponse: Codable {
    let success: Bool
    let data: GetUserTasksData

    struct GetUserTasksData: Codable {
        let tasks: [TaskItem]
        let count: Int

        struct TaskItem: Codable {
            let taskId: String
            let title: String
            let url: String
            let deadline: String           // ISO 8601文字列
            let targetMembers: [String]
            let externalAppId: String?
            let externalAppName: String?
            let externalAppIconUrl: String?
            let isCompleted: Bool
            let completedAt: String?       // ISO 8601文字列
            let coverImage: String?
            let coverImageSource: String?
            let createdAt: String?         // ISO 8601文字列
            let updatedAt: String?         // ISO 8601文字列
        }
    }
}

// updateTask Cloud Functionのレスポンス構造
struct UpdateTaskResponse: Codable {
    let success: Bool
    let data: UpdateTaskData

    struct UpdateTaskData: Codable {
        let taskId: String
        let title: String
        let url: String
        let deadline: String
        let targetMembers: [String]
        let externalAppId: String?
        let coverImage: String?
        let coverImageSource: CoverImageSource?
    }
}
