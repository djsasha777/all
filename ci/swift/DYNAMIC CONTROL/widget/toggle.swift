import WidgetKit
import SwiftUI
import AppIntents

// Конфигурационный интент для Toggle
struct ToggleConfigIntent: ControlConfigurationIntent {
    static var title = LocalizedStringResource("Конфигурация переключателя")

    @Parameter(title: "Имя")
    var name: String?

    @Parameter(title: "Базовый URL")
    var baseURL: URL?

    @Parameter(title: "Безопасное подключение (Basic Auth)")
    var secure: Bool?

    @Parameter(title: "Логин")
    var login: String?

    @Parameter(title: "Пароль")
    var password: String?
}

// Интент для переключения состояния
struct ToggleStateIntent: AppIntent {
    static var title = LocalizedStringResource("Переключить состояние")

    @Parameter(title: "Базовый URL")
    var baseURL: URL

    @Parameter(title: "Безопасное подключение (Basic Auth)")
    var secure: Bool?

    @Parameter(title: "Логин")
    var login: String?

    @Parameter(title: "Пароль")
    var password: String?

    // Инициализатор по умолчанию, который устанавливает безопасный URL
    init() {
        self.baseURL = URL(string: "https://example.com")! // Убедитесь, что это валидный URL по умолчанию
        self.secure = nil
        self.login = nil
        self.password = nil
    }

    // Конструктор с параметрами
    init(baseURL: URL, secure: Bool?, login: String?, password: String?) {
        self.baseURL = baseURL
        self.secure = secure
        self.login = login
        self.password = password
    }

    func perform() async throws -> some IntentResult {
        do {
            // Получаем текущее состояние переключателя
            let currentState = try await getCurrentState()

            // Формируем URL для переключения на противоположное состояние
            let action = currentState ? "off" : "on"
            let targetURL = baseURL.appendingPathComponent(action)

            // Отправляем запрос для переключения
            try await sendRequest(to: targetURL)

            return .result()
        } catch {
            // Обработка ошибок, можно добавить логирование или возвращать ошибку
            return .result()
        }
    }

    // Метод получения текущего состояния (возвращает true если "on")
    private func getCurrentState() async throws -> Bool {
        let statusURL = baseURL.appendingPathComponent("status")
        let (data, _) = try await makeRequest(to: statusURL)
        let response = String(data: data, encoding: .utf8)?.lowercased() ?? ""
        return response.contains("on")
    }

    // Отправка запроса без обработки результата
    private func sendRequest(to url: URL) async throws {
        _ = try await makeRequest(to: url)
    }

    // Формирование запроса с возможной базовой аутентификацией
    private func makeRequest(to url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if secure == true,
           let login = login, !login.isEmpty,
           let password = password, !password.isEmpty {
            let authString = "\(login):\(password)"
            if let authData = authString.data(using: .utf8) {
                let authValue = "Basic \(authData.base64EncodedString())"
                request.setValue(authValue, forHTTPHeaderField: "Authorization")
            }
        }

        return try await URLSession.shared.data(for: request)
    }
}

// Виджет переключателя для iOS 18
@available(iOS 18.0, *)
struct ToggleControlWidget: ControlWidget {
    let kind = "widget.ToggleControlWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: kind, intent: ToggleConfigIntent.self) { configuration in

            // Используем безопасную инициализацию URL с дефолтом
            let baseURL = configuration.baseURL ?? URL(string: "https://example.com")!

            let intent = ToggleStateIntent(
                baseURL: baseURL,
                secure: configuration.secure,
                login: configuration.login,
                password: configuration.password
            )

            ControlWidgetButton(action: intent) {
                Label(configuration.name ?? "Переключатель", systemImage: "power.circle")
            }
        }
        .promptsForUserConfiguration()
    }
}
