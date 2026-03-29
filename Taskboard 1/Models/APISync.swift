import Foundation
import CoreData

final class APISync {

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Fetch tasks for a day

    func fetchTasksForDay(
        date: Date,
        calendar: Calendar,
        context: NSManagedObjectContext,
        onApplyingRemote: @escaping (Bool) -> Void,
        onRemoteApplied: @escaping () -> Void
    ) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        var components = URLComponents(
            url: baseURL.appendingPathComponent("tasks"),
            resolvingAgainstBaseURL: false
        )!

        // IMPORTANT:
        // Send backend-compatible naive datetime strings, not Z/UTC strings.
        components.queryItems = [
            URLQueryItem(name: "start", value: Self.backendDateFormatter.string(from: start)),
            URLQueryItem(name: "end", value: Self.backendDateFormatter.string(from: end))
        ]

        guard let url = components.url else {
            print("Invalid fetch URL")
            return
        }

        print("FETCH URL:", url.absoluteString)

        DispatchQueue.main.async {
            onApplyingRemote(true)
        }

        let task = session.dataTask(with: url) { data, response, error in
            if let error {
                print("GET /tasks error:", error)
                DispatchQueue.main.async {
                    onApplyingRemote(false)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("GET /tasks invalid response")
                DispatchQueue.main.async {
                    onApplyingRemote(false)
                }
                return
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("GET /tasks failed:", httpResponse.statusCode, bodyString)
                DispatchQueue.main.async {
                    onApplyingRemote(false)
                }
                return
            }

            guard let data else {
                print("GET /tasks empty data")
                DispatchQueue.main.async {
                    onApplyingRemote(false)
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)

                    // 1) Backend naive datetime: "yyyy-MM-dd'T'HH:mm:ss"
                    if let date = APISync.backendDateFormatter.date(from: dateString) {
                        return date
                    }

                    // 2) Backend naive datetime with fractional seconds
                    if let date = APISync.backendDateFormatterWithFractional.date(from: dateString) {
                        return date
                    }

                    // 3) Fallbacks, if backend ever changes format
                    if let date = APISync.iso8601WithFractional.date(from: dateString) {
                        return date
                    }

                    if let date = APISync.iso8601Basic.date(from: dateString) {
                        return date
                    }

                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date format: \(dateString)"
                    )
                }

                let remoteTasks = try decoder.decode([TaskDTO].self, from: data)

                print("REMOTE TASK COUNT:", remoteTasks.count)
                for t in remoteTasks {
                    print("REMOTE:", t.id, t.name, t.dueDate)
                }

                context.perform {
                    self.mergeRemoteTasks(remoteTasks, into: context)

                    do {
                        try context.save()
                    } catch {
                        print("CoreData save after fetch failed:", error)
                    }

                    DispatchQueue.main.async {
                        onApplyingRemote(false)
                        onRemoteApplied()
                    }
                }
            } catch {
                print("Task decode failed:", error)
                DispatchQueue.main.async {
                    onApplyingRemote(false)
                }
            }
        }

        task.resume()
    }

    // MARK: - Create

//    func pushCreate(task: TaskItem) {
//        guard let requestBody = makeCreateRequest(from: task) else {
//            print("Create request body invalid")
//            return
//        }
//
//        let url = baseURL.appendingPathComponent("tasks")
//
//        do {
//            let encoder = JSONEncoder()
//            encoder.dateEncodingStrategy = .custom { date, encoder in
//                var container = encoder.singleValueContainer()
//                // IMPORTANT:
//                // Send naive local datetime string to match backend expectations.
//                try container.encode(APISync.backendDateFormatter.string(from: date))
//            }
//
//            let body = try encoder.encode(requestBody)
//
//            print("POST BODY:", String(data: body, encoding: .utf8) ?? "")
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = body
//
//            let dataTask = session.dataTask(with: request) { data, response, error in
//                if let error {
//                    print("POST /tasks error:", error)
//                    return
//                }
//
//                guard let httpResponse = response as? HTTPURLResponse else {
//                    print("POST /tasks invalid response")
//                    return
//                }
//
//                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
//
//                guard (200..<300).contains(httpResponse.statusCode) else {
//                    print("POST /tasks failed:", httpResponse.statusCode, bodyString)
//                    return
//                }
//
//                print("POST /tasks success:", httpResponse.statusCode, bodyString)
//            }
//
//            dataTask.resume()
//        } catch {
//            print("Create encode failed:", error)
//        }
//    }

    func pushCreate(task: TaskItem) {
        guard let requestBody = makeCreateRequest(from: task) else {
            print("Create request body invalid")
            return
        }

        let url = baseURL.appendingPathComponent("tasks")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                try container.encode(APISync.backendDateFormatter.string(from: date))
            }

            let body = try encoder.encode(requestBody)

            print("POST BODY:", String(data: body, encoding: .utf8) ?? "")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let dataTask = session.dataTask(with: request) { data, response, error in
                if let error {
                    print("POST /tasks error:", error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("POST /tasks invalid response")
                    return
                }

                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

                guard (200..<300).contains(httpResponse.statusCode) else {
                    print("POST /tasks failed:", httpResponse.statusCode, bodyString)
                    return
                }

                print("POST /tasks success:", httpResponse.statusCode, bodyString)

                guard let data else { return }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .custom { decoder in
                        let container = try decoder.singleValueContainer()
                        let dateString = try container.decode(String.self)

                        if let date = APISync.backendDateFormatter.date(from: dateString) {
                            return date
                        }

                        if let date = APISync.backendDateFormatterWithFractional.date(from: dateString) {
                            return date
                        }

                        if let date = APISync.iso8601WithFractional.date(from: dateString) {
                            return date
                        }

                        if let date = APISync.iso8601Basic.date(from: dateString) {
                            return date
                        }

                        throw DecodingError.dataCorruptedError(
                            in: container,
                            debugDescription: "Invalid date format: \(dateString)"
                        )
                    }

                    let createdTask = try decoder.decode(TaskDTO.self, from: data)

                    guard let context = task.managedObjectContext else { return }

                    context.perform {
                        task.id = UUID(uuidString: createdTask.id)
                        task.created = createdTask.created
                        task.name = createdTask.name
                        task.desc = createdTask.desc
                        task.dueDate = createdTask.dueDate
                        task.scheduleTime = createdTask.scheduleTime
                        task.completedDate = createdTask.completedDate

                        do {
                            try context.save()
                            print("Local CoreData updated with server ID:", createdTask.id)
                        } catch {
                            print("Failed to save CoreData after POST response:", error)
                        }
                    }

                } catch {
                    print("Failed to decode POST response:", error)
                }
            }

            dataTask.resume()
        } catch {
            print("Create encode failed:", error)
        }
    }
    // MARK: - Update

//    func pushUpdate(task: TaskItem) {
//        guard let id = task.id?.uuidString else {
//            print("Update failed: missing id")
//            return
//        }
//
//        guard let requestBody = makeUpdateRequest(from: task) else {
//            print("Update request body invalid")
//            return
//        }
//
//        let url = baseURL.appendingPathComponent("tasks/\(id)")
//
//        do {
//            let encoder = JSONEncoder()
//            encoder.dateEncodingStrategy = .custom { date, encoder in
//                var container = encoder.singleValueContainer()
//                // IMPORTANT:
//                // Send naive local datetime string to match backend expectations.
//                try container.encode(APISync.backendDateFormatter.string(from: date))
//            }
//
//            let body = try encoder.encode(requestBody)
//
//            print("PUT BODY:", String(data: body, encoding: .utf8) ?? "")
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "PUT"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = body
//
//            let dataTask = session.dataTask(with: request) { data, response, error in
//                if let error {
//                    print("PUT /tasks/{id} error:", error)
//                    return
//                }
//
//                guard let httpResponse = response as? HTTPURLResponse else {
//                    print("PUT /tasks/{id} invalid response")
//                    return
//                }
//
//                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
//
//                guard (200..<300).contains(httpResponse.statusCode) else {
//                    print("PUT /tasks/{id} failed:", httpResponse.statusCode, bodyString)
//                    return
//                }
//
//                print("PUT /tasks/{id} success:", httpResponse.statusCode, bodyString)
//            }
//
//            dataTask.resume()
//        } catch {
//            print("Update encode failed:", error)
//        }
//    }

//    func pushUpdate(task: TaskItem) {
//        guard let id = task.id?.uuidString else {
//            print("Update failed: missing id")
//            return
//        }
//
//        guard let requestBody = makeUpdateRequest(from: task) else {
//            print("Update request body invalid")
//            return
//        }
//
//        let url = baseURL.appendingPathComponent("tasks/\(id)")
//
//        do {
//            let encoder = JSONEncoder()
//            encoder.dateEncodingStrategy = .custom { date, encoder in
//                var container = encoder.singleValueContainer()
//                try container.encode(APISync.backendDateFormatter.string(from: date))
//            }
//
//            let body = try encoder.encode(requestBody)
//
//            print("PUT URL:", url.absoluteString)
//            print("PUT BODY:", String(data: body, encoding: .utf8) ?? "")
//
//            var request = URLRequest(url: url)
//            request.httpMethod = "PUT"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = body
//
//            let dataTask = session.dataTask(with: request) { data, response, error in
//                if let error {
//                    print("PUT /tasks/{id} error:", error)
//                    return
//                }
//
//                guard let httpResponse = response as? HTTPURLResponse else {
//                    print("PUT /tasks/{id} invalid response")
//                    return
//                }
//
//                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
//                print("PUT status:", httpResponse.statusCode)
//                print("PUT response:", bodyString)
//            }
//
//            dataTask.resume()
//        } catch {
//            print("Update encode failed:", error)
//        }
//    }
    func pushUpdate(task: TaskItem, onSuccess: (() -> Void)? = nil) {
        guard let id = task.id?.uuidString else {
            print("Update failed: missing id")
            return
        }

        guard let requestBody = makeUpdateRequest(from: task) else {
            print("Update request body invalid")
            return
        }

        let url = baseURL.appendingPathComponent("tasks/\(id)")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                try container.encode(APISync.backendDateFormatter.string(from: date))
            }

            let body = try encoder.encode(requestBody)

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            let dataTask = session.dataTask(with: request) { data, response, error in
                if let error {
                    print("PUT /tasks/{id} error:", error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("PUT /tasks/{id} invalid response")
                    return
                }

                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

                guard (200..<300).contains(httpResponse.statusCode) else {
                    print("PUT /tasks/{id} failed:", httpResponse.statusCode, bodyString)
                    return
                }

                print("PUT /tasks/{id} success:", httpResponse.statusCode, bodyString)

                DispatchQueue.main.async {
                    onSuccess?()
                }
            }

            dataTask.resume()
        } catch {
            print("Update encode failed:", error)
        }
    }
    // MARK: - Delete

//    func pushDelete(taskID: UUID) {
//        let url = baseURL.appendingPathComponent("tasks/\(taskID.uuidString)")
//        var request = URLRequest(url: url)
//        request.httpMethod = "DELETE"
//
//        let dataTask = session.dataTask(with: request) { data, response, error in
//            if let error {
//                print("DELETE /tasks/{id} error:", error)
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("DELETE /tasks/{id} invalid response")
//                return
//            }
//
//            let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
//
//            guard (200..<300).contains(httpResponse.statusCode) else {
//                print("DELETE /tasks/{id} failed:", httpResponse.statusCode, bodyString)
//                return
//            }
//
//            print("DELETE /tasks/{id} success:", httpResponse.statusCode, bodyString)
//        }
//
//        dataTask.resume()
//    }
    
    func pushDelete(taskID: UUID, onSuccess: (() -> Void)? = nil) {
        let url = baseURL.appendingPathComponent("tasks/\(taskID.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error {
                print("DELETE /tasks/{id} error:", error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("DELETE /tasks/{id} invalid response")
                return
            }

            let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

            guard (200..<300).contains(httpResponse.statusCode) else {
                print("DELETE /tasks/{id} failed:", httpResponse.statusCode, bodyString)
                return
            }

            print("DELETE /tasks/{id} success:", httpResponse.statusCode, bodyString)

            DispatchQueue.main.async {
                onSuccess?()
            }
        }

        dataTask.resume()
    }

    // MARK: - Merge Remote -> CoreData

    private func mergeRemoteTasks(
        _ remoteTasks: [TaskDTO],
        into context: NSManagedObjectContext
    ) {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let localTasks = (try? context.fetch(request)) ?? []

        var groupedByID: [String: [TaskItem]] = [:]

        for item in localTasks {
            guard let id = item.id?.uuidString else { continue }
            groupedByID[id, default: []].append(item)
        }

        var localByID: [String: TaskItem] = [:]

        for (id, items) in groupedByID {
            guard let keeper = items.first else { continue }
            localByID[id] = keeper

            if items.count > 1 {
                print("Removing duplicate local CoreData items for id:", id)
                for duplicate in items.dropFirst() {
                    context.delete(duplicate)
                }
            }
        }

        for dto in remoteTasks {
            let item = localByID[dto.id] ?? TaskItem(context: context)

            item.id = UUID(uuidString: dto.id)
            item.name = dto.name
            item.desc = dto.desc
            item.dueDate = dto.dueDate
            item.created = dto.created
            item.scheduleTime = dto.scheduleTime
            item.completedDate = dto.completedDate
        }

        // Do not auto-delete local rows here.
        // With naive backend datetimes, day-window mismatches can wipe valid local data.
    }

    // MARK: - Request Builders

    private func makeCreateRequest(from task: TaskItem) -> CreateTaskRequest? {
        guard
            let name = task.name,
            let desc = task.desc,
            let dueDate = task.dueDate
        else {
            return nil
        }

        return CreateTaskRequest(
            name: name,
            desc: desc,
            dueDate: dueDate,
            scheduleTime: task.scheduleTime,
            completedDate: task.completedDate
        )
    }

    private func makeUpdateRequest(from task: TaskItem) -> UpdateTaskRequest? {
        guard
            let name = task.name,
            let desc = task.desc,
            let dueDate = task.dueDate
        else {
            return nil
        }

        return UpdateTaskRequest(
            name: name,
            desc: desc,
            dueDate: dueDate,
            scheduleTime: task.scheduleTime,
            completedDate: task.completedDate
        )
    }

    // MARK: - Date Formatters

    // Backend actual format: "2026-03-12T18:00:00"
    // Treat it as LOCAL wall-clock time.
    private static let backendDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // Handles "2026-03-12T18:00:00.1234567"
    private static let backendDateFormatterWithFractional: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
