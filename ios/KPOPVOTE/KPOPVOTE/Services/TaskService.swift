//
//  TaskService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Task Management Service
//

import Foundation
import FirebaseAuth

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

        print("📡 [TaskService] Fetching tasks from: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        print("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // デバッグ: レスポンスの生データを確認
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 [TaskService] Response JSON: \(responseString)")
        }

        // Cloud Functionのレスポンスを直接デコード
        let result = try JSONDecoder().decode(GetUserTasksResponse.self, from: data)
        print("✅ [TaskService] Fetched \(result.data.tasks.count) tasks")
        print("📊 [TaskService] Task count from API: \(result.data.count)")

        // 現在のユーザーIDを取得
        guard let userId = Auth.auth().currentUser?.uid else {
            throw TaskError.notAuthenticated
        }

        // VoteTaskオブジェクトの配列を構築
        let voteTasks = result.data.tasks.map { task -> VoteTask in
            // ISO 8601文字列をDateに変換
            let isoFormatter = ISO8601DateFormatter()
            let deadline = isoFormatter.date(from: task.deadline) ?? Date()
            let createdAt = task.createdAt.flatMap { isoFormatter.date(from: $0) } ?? Date()
            let updatedAt = task.updatedAt.flatMap { isoFormatter.date(from: $0) } ?? Date()

            // isCompletedからstatusを推測
            let status: VoteTask.TaskStatus = task.isCompleted ? .completed :
                                              (deadline < Date() ? .expired : .pending)

            print("📋 [TaskService] Task: \(task.title), Deadline: \(task.deadline), Status: \(status)")

            return VoteTask(
                id: task.taskId,
                userId: userId,
                title: task.title,
                url: task.url,
                deadline: deadline,
                status: status,
                biasIds: task.targetMembers,
                ogpImage: task.ogpImage,
                ogpTitle: task.ogpTitle,
                ogpDescription: nil
            )
        }

        print("✅ [TaskService] Converted \(voteTasks.count) VoteTasks")
        return voteTasks
    }

    // MARK: - Get Active Tasks
    func getActiveTasks() async throws -> [VoteTask] {
        let allTasks = try await getUserTasks(isCompleted: false)
        print("📊 [TaskService] Total tasks retrieved: \(allTasks.count)")

        // Filter active tasks (deadline in future and not archived)
        let now = Date()
        print("🕐 [TaskService] Current time: \(now)")

        let activeTasks = allTasks.filter { task in
            let timeInterval = task.deadline.timeIntervalSince(now)
            let hours = timeInterval / 3600
            let isActive = timeInterval > 0 && !task.isArchived
            print("📋 [TaskService] Task '\(task.title)': deadline in \(hours) hours, archived: \(task.isArchived), active: \(isActive)")
            return isActive
        }

        print("✅ [TaskService] Found \(activeTasks.count) active tasks out of \(allTasks.count) total")
        return activeTasks.sorted { $0.deadline < $1.deadline }
    }

    // MARK: - Mark Task as Completed
    func markTaskAsCompleted(taskId: String) async throws {
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
            "status": "completed"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📡 [TaskService] Marking task as completed: \(taskId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        print("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        print("✅ [TaskService] Task marked as completed: \(taskId)")
    }

    // MARK: - Register New Task
    func registerTask(title: String, url: String, deadline: Date, biasIds: [String]) async throws -> VoteTask {
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
        isoFormatter.formatOptions = [.withInternetDateTime]
        let deadlineString = isoFormatter.string(from: deadline)

        let body: [String: Any] = [
            "title": title,
            "url": url,
            "deadline": deadlineString,
            "targetMembers": biasIds
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📡 [TaskService] Registering new task: \(title)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse
        }

        print("📥 [TaskService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [TaskService] Error response: \(errorString)")
            }
            throw TaskError.serverError(httpResponse.statusCode)
        }

        // Cloud Functionのレスポンスを直接デコード
        let result = try JSONDecoder().decode(RegisterTaskSimpleResponse.self, from: data)
        print("✅ [TaskService] Task registered: \(result.data.taskId)")

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
            ogpImage: result.data.ogpImage,
            ogpTitle: result.data.ogpTitle,
            ogpDescription: nil
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
        let isCompleted: Bool
        let completedAt: String?
        let ogpTitle: String?
        let ogpImage: String?
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
            let isCompleted: Bool
            let completedAt: String?       // ISO 8601文字列
            let ogpTitle: String?
            let ogpImage: String?
            let createdAt: String?         // ISO 8601文字列
            let updatedAt: String?         // ISO 8601文字列
        }
    }
}
