import WidgetKit
import SwiftUI
import AppIntents

// Конфигурационный интент
struct ButtonConfigIntent: ControlConfigurationIntent {
    static var title = LocalizedStringResource("Button configuration")

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "URL")
    var url: URL?
    
    @Parameter(title: "Secure")
    var secure: Bool?

    @Parameter(title: "Login")
    var login: String?

    @Parameter(title: "Password")  // Остается String?, система защитит автоматически
    var password: String?
}

// Интент действия
struct SendRequestIntent: AppIntent {
    static var title = LocalizedStringResource("Send Request")

    @Parameter(title: "URL")
    var url: URL

    @Parameter(title: "Secure")
    var secure: Bool?

    @Parameter(title: "Login")
    var login: String?

    @Parameter(title: "Password")  // Остается String?, система защитит автоматически
    var password: String?
    
    init() {
        self.url = URL(string: "http://default.url")! // Значение по умолчанию
        self.secure = nil
        self.login = nil
        self.password = nil
    }

    // Конструктор с параметрами для внутреннего создания интента
    init(url: URL, secure: Bool?, login: String?, password: String?) {
        self.url = url
        self.secure = secure
        self.login = login
        self.password = password
    }

    func perform() async throws -> some IntentResult {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if secure == true, let login = login, !login.isEmpty, let password = password, !password.isEmpty {
            let authString = "\(login):\(password)"
            if let authData = authString.data(using: .utf8) {
                let authValue = "Basic \(authData.base64EncodedString())"
                request.setValue(authValue, forHTTPHeaderField: "Authorization")
            }
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            // Можно дополнительно проверить response, например статус код
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return .result()
            } else {
                // Обработка ошибок, например логирование
                return .result() // или с ошибкой
            }
        } catch {
            // Обработка ошибок
            return .result()
        }
    }


}

// Виджет с конфигурацией и выполнением действия
struct ButtonControlWidget: ControlWidget {
    let kind = "widget.ButtonControlWidget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: kind, intent: ButtonConfigIntent.self) { configuration in
            let intent = SendRequestIntent(
                url: configuration.url ?? URL(string: "http://example.com")!,
                secure: configuration.secure,
                login: configuration.login,
                password: configuration.password
            )
            ControlWidgetButton(action: intent) {
                Label(configuration.name ?? "Кнопка", systemImage: "hand.tap")
            }
        }
        .promptsForUserConfiguration()
    }
}

