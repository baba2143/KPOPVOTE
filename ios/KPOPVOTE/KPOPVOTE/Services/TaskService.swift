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

        let result = try JSONDecoder().decode(TasksResponse.self, from: data)
        print("✅ [TaskService] Fetched \(result.data.tasks.count) tasks")

        return result.data.tasks
    }

    // MARK: - Get Urgent Tasks
    func getUrgentTasks() async throws -> [VoteTask] {
        let allTasks = try await getUserTasks(isCompleted: false)

        // Filter urgent tasks (deadline within 24 hours)
        let now = Date()
        let urgentTasks = allTasks.filter { task in
            let timeInterval = task.deadline.timeIntervalSince(now)
            return timeInterval > 0 && timeInterval <= 86400 // 24 hours in seconds
        }

        print("⚠️ [TaskService] Found \(urgentTasks.count) urgent tasks")
        return urgentTasks.sorted { $0.deadline < $1.deadline }
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

        let body: [String: Any] = [
            "title": title,
            "url": url,
            "deadline": deadline.timeIntervalSince1970,
            "biasIds": biasIds
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

        let result = try JSONDecoder().decode(RegisterTaskResponse.self, from: data)
        print("✅ [TaskService] Task registered: \(result.data.task.id)")

        return result.data.task
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

struct RegisterTaskResponse: Codable {
    let success: Bool
    let data: RegisterTaskData

    struct RegisterTaskData: Codable {
        let task: VoteTask
    }
}
