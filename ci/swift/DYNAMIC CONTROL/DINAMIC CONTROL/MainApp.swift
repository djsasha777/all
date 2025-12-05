import Foundation
import Combine
import SwiftUI

// MARK: - Model

struct ButtonConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    var type: String // "button", "led", "toggle"
    var secure: Bool
    var login: String?
    var password: String?
    var isOn: Bool
    var isError: Bool = false
    var isPressed: Bool = false // Для кнопок: отслеживаем нажатие/отпускание

    enum CodingKeys: String, CodingKey {
        case id, name, url, type, secure, login, password, isOn, isError, isPressed
    }

    init(id: UUID = UUID(), name: String, url: String, type: String,
         secure: Bool = false, login: String? = nil,
         password: String? = nil, isOn: Bool = false,
         isError: Bool = false, isPressed: Bool = false) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
        self.secure = secure
        self.login = login
        self.password = password
        self.isOn = isOn
        self.isError = isError
        self.isPressed = isPressed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        type = try container.decode(String.self, forKey: .type)
        secure = (try? container.decode(Bool.self, forKey: .secure)) ?? false
        login = try? container.decode(String.self, forKey: .login)
        password = try? container.decode(String.self, forKey: .password)
        isOn = (try? container.decode(Bool.self, forKey: .isOn)) ?? false
        isError = (try? container.decode(Bool.self, forKey: .isError)) ?? false
        isPressed = (try? container.decode(Bool.self, forKey: .isPressed)) ?? false
    }

    // Формируем URL, путём и суффиксом (например on/off/status или значение для led)
    func urlWithPrefixAndSuffix(_ suffix: String = "status", value: Int? = nil) -> URL? {
        guard let urlComponents = URLComponents(string: url) else { return nil }
        let path = urlComponents.path.hasPrefix("/") ? String(urlComponents.path.dropFirst()) : urlComponents.path
        var newPath = ""
        if type == "led", let v = value {
            newPath = "/\(path)/\(v)"
        } else if type == "toggle" {
            newPath = "/\(path)/\(suffix)"
        } else {
            newPath = "/\(path)/\(suffix)"
        }
        var newComponents = urlComponents
        newComponents.path = newPath
        let urlString = newComponents.string
        print("Generated URL for button \(name): \(urlString ?? "nil")")
        if let urlString = urlString {
            return URL(string: urlString)
        }
        return nil
    }
}

// MARK: - Unsafe URLSession Delegate to Ignore SSL errors

class UnsafeURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - ViewModel

class ConfigLoader: ObservableObject {
    @Published var buttons: [ButtonConfig] = [] { didSet { saveButtons() } }
    @Published var errorMessage: String?
    @Published var lightValues: [UUID: Int] = [:]

    private let buttonsKey = "SavedButtons"
    private let groupDefaults = UserDefaults(suiteName: "group.but")

    private var userDefaultsObserver: NSObjectProtocol?

    private var timer: Timer?

    init() {
        loadButtons()

        // Подписка на изменения UserDefaults в группе для синхронизации с виджетом
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: groupDefaults,
            queue: .main
        ) { [weak self] _ in
            self?.handleUserDefaultsChange()
        }
    }

    deinit {
        if let observer = userDefaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleUserDefaultsChange() {
        guard let lastPressedButtonName = groupDefaults?.string(forKey: "LastButtonPressed"),
              !lastPressedButtonName.isEmpty else { return }

        // Сбрасываем значение, чтобы не зациклить
        groupDefaults?.removeObject(forKey: "LastButtonPressed")
        groupDefaults?.synchronize()

        if let index = buttons.firstIndex(where: { $0.name == lastPressedButtonName }) {
            buttons[index].isPressed = true
            buttons[index].isError = false

            sendPostRequest(to: buttons[index], suffix: "on")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if index < self.buttons.count {
                    self.buttons[index].isPressed = false
                    self.sendPostRequest(to: self.buttons[index], suffix: "off")
                }
            }
        }
    }


    func addButtons(_ newButtons: [ButtonConfig]) {
        buttons.append(contentsOf: newButtons)
    }

    func loadFromRemoteIgnoreSSL(urlString: String) {
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Некорректный URL"
            return
        }
        let delegate = UnsafeURLSessionDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    self.errorMessage = "Данные не получены"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let importedButtons = try decoder.decode([ButtonConfig].self, from: data)
                    self.buttons = importedButtons
                } catch {
                    self.errorMessage = "Ошибка разбора JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func saveButtons() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let groupDefaults = self.groupDefaults else { return }
            do {
                let data = try JSONEncoder().encode(self.buttons)
                UserDefaults.standard.set(data, forKey: self.buttonsKey)
                groupDefaults.set(data, forKey: self.buttonsKey)
                groupDefaults.synchronize()
            } catch {
                print("JSON encoding error in saveButtons: \(error)")
            }
        }
    }


    func loadButtons() {
        if let data = groupDefaults?.data(forKey: buttonsKey),
           let savedButtons = try? JSONDecoder().decode([ButtonConfig].self, from: data) {
            buttons = savedButtons
            return
        }
        if let data = UserDefaults.standard.data(forKey: buttonsKey),
           let savedButtons = try? JSONDecoder().decode([ButtonConfig].self, from: data) {
            buttons = savedButtons
        }
    }

    func startStatusPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateToggleStatuses()
        }
    }

    func updateToggleStatuses() {
        for i in buttons.indices {
            let button = buttons[i]

            if button.type == "button" {
                DispatchQueue.main.async {
                    self.buttons[i].isError = false
                    self.buttons[i].isOn = false
                    self.buttons[i].isPressed = false
                }
                continue
            }

            guard let url = button.urlWithPrefixAndSuffix() else {
                print("Invalid status URL for button: \(button.name)")
                DispatchQueue.main.async {
                    self.buttons[i].isError = true
                    self.buttons[i].isOn = false
                    self.buttons[i].isPressed = false
                }
                continue
            }

            print("Polling status for button: \(button.name) at \(url)")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            if button.secure, let login = button.login, let password = button.password {
                let authString = "\(login):\(password)"
                if let authData = authString.data(using: .utf8) {
                    let authValue = "Basic \(authData.base64EncodedString())"
                    request.setValue(authValue, forHTTPHeaderField: "Authorization")
                }
            }

            URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error {
                        print("Status polling error for button \(button.name): \(error.localizedDescription)")
                        self.buttons[i].isError = true
                        self.buttons[i].isOn = false
                        self.buttons[i].isPressed = false
                        return
                    }
                    guard let data = data,
                          let statusString = String(data: data, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() else {
                        print("Invalid status data for button \(button.name)")
                        self.buttons[i].isError = true
                        self.buttons[i].isOn = false
                        self.buttons[i].isPressed = false
                        return
                    }
                    print("Status for button \(button.name): '\(statusString)'")
                    self.buttons[i].isError = false
                    self.buttons[i].isOn = (statusString == "on")
                    self.buttons[i].isPressed = false
                }
            }.resume()
        }
    }

    func sendPostRequest(to button: ButtonConfig, suffix: String) {
        var requestUrl: URL?
        if button.type == "button" {
            requestUrl = URL(string: button.url)
        } else if button.type == "led" {
            let value = lightValues[button.id] ?? 0
            requestUrl = button.urlWithPrefixAndSuffix("\(value)", value: value)
        } else {
            requestUrl = button.urlWithPrefixAndSuffix(suffix)
        }
        guard let url = requestUrl else {
            print("Invalid URL for button \(button.name)")
            return
        }
        print("Sending POST request for button '\(button.name)' to URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if button.secure, let login = button.login, let password = button.password {
            let authString = "\(login):\(password)"
            guard let authData = authString.data(using: .utf8) else {
                print("Failed to encode auth for button \(button.name)")
                return
            }
            request.setValue("Basic \(authData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }

        DispatchQueue.main.async {
            if let idx = self.buttons.firstIndex(where: { $0.id == button.id }) {
                self.buttons[idx].isPressed = (suffix == "on")
                self.buttons[idx].isError = false
            }
        }

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("POST request error for button \(button.name): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    if let idx = self.buttons.firstIndex(where: { $0.id == button.id }) {
                        self.buttons[idx].isError = true
                        self.buttons[idx].isPressed = false
                    }
                }
            } else {
                print("POST request successful for button \(button.name)")
            }
        }.resume()
    }

    func addButton(_ button: ButtonConfig) {
        buttons.append(button)
    }

    func updateButton(_ updatedButton: ButtonConfig) {
        if let index = buttons.firstIndex(where: { $0.id == updatedButton.id }) {
            buttons[index] = updatedButton
        }
    }

    func deleteButton(_ button: ButtonConfig) {
        buttons.removeAll { $0.id == button.id }
    }
}


// MARK: - Views

@main
struct DynamicControlCenterApp: App {
    @StateObject var configLoader = ConfigLoader()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configLoader)
                .onAppear {
                    configLoader.startStatusPolling()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var configLoader: ConfigLoader
    @State private var showingAddButton = false
    @State private var showingImport = false
    @State private var editingButton: ButtonConfig?
    @State private var showAlert = false
    @State private var isEditing = false // режим редактирования
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    editingButton = nil
                    showingAddButton = true
                } label: {
                    Label("", systemImage: "plus")
                        .font(.title2)
                }
                .padding()
                
                Spacer()
                
                Button {
                    isEditing.toggle() // переключаем режим редактирования
                } label: {
                    Label(isEditing ? "Done" : "", systemImage: isEditing ? "checkmark" : "pencil")
                        .font(.title2)
                }
                .padding()
                
                Button {
                    showingImport = true
                } label: {
                    Label("", systemImage: "square.and.arrow.down")
                        .font(.title2)
                }
                .padding()
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 30) {
                    ForEach($configLoader.buttons) { $button in
                        VStack(alignment: .leading) {
                            // Отображение кнопок согласно типу, без contextMenu
                            if button.type == "toggle" {
                                HStack {
                                    Toggle(button.name, isOn: Binding(
                                        get: { button.isOn },
                                        set: { newValue in
                                            configLoader.sendPostRequest(to: button, suffix: newValue ? "on" : "off")
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                configLoader.updateToggleStatuses()
                                            }
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .green))
                                    .foregroundColor(button.isError ? Color.red : Color.primary)
                                    Spacer()
                                    
                                    if isEditing {
                                        editDeleteButtons(for: button)
                                    }
                                }
                            } else if button.type == "push" {
                                HStack {
                                    Button(action: {
                                        // обычное действие
                                    }) {
                                        Text(button.name)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(button.isError ? Color.red : (button.isPressed ? Color.green : Color.gray))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                if !button.isPressed {
                                                    configLoader.sendPostRequest(to: button, suffix: "on")
                                                    if let idx = configLoader.buttons.firstIndex(where: { $0.id == button.id }) {
                                                        configLoader.buttons[idx].isPressed = true
                                                        configLoader.buttons[idx].isError = false
                                                    }
                                                }
                                            }
                                            .onEnded { _ in
                                                configLoader.sendPostRequest(to: button, suffix: "off")
                                                if let idx = configLoader.buttons.firstIndex(where: { $0.id == button.id }) {
                                                    configLoader.buttons[idx].isPressed = false
                                                }
                                            }
                                    )
                                    if isEditing {
                                        editDeleteButtons(for: button)
                                    }
                                }
                            } else if button.type == "led" {
                                VStack(alignment: .leading) {
                                    Text("Значение: \(configLoader.lightValues[button.id] ?? 0)")
                                        .padding(.horizontal)
                                    Slider(
                                        value: Binding(
                                            get: {
                                                Double(configLoader.lightValues[button.id] ?? 0)
                                            },
                                            set: { newValue in
                                                configLoader.lightValues[button.id] = Int(newValue)
                                            }
                                        ),
                                        in: 0...100,
                                        step: 1,
                                        onEditingChanged: { editing in
                                            if !editing {
                                                if let btn = configLoader.buttons.first(where: { $0.id == button.id }) {
                                                    configLoader.sendPostRequest(to: btn, suffix: "\(configLoader.lightValues[button.id] ?? 0)")
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                                if isEditing {
                                    editDeleteButtons(for: button)
                                }
                            } else {
                                HStack {
                                    Button {
                                        configLoader.sendPostRequest(to: button, suffix: "on")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                            if let idx = configLoader.buttons.firstIndex(where: { $0.id == button.id }) {
                                                configLoader.buttons[idx].isPressed = false
                                            }
                                        }
                                    } label: {
                                        Text(button.name)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(button.isError ? Color.red : (button.isPressed ? Color.green : Color.gray))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .scaleEffect(button.isPressed ? 1.05 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: button.isPressed)
                                    }
                                    if isEditing {
                                        editDeleteButtons(for: button)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddButton) {
            AddButtonView(configLoader: configLoader, buttonToEdit: $editingButton)
        }
        .sheet(isPresented: $showingImport) {
            ImportView(configLoader: configLoader)
        }
        .alert("Ошибка", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(configLoader.errorMessage ?? "Неизвестная ошибка")
        }
        .onReceive(configLoader.$errorMessage) { errorMsg in
            showAlert = errorMsg != nil
        }
    }
    
    @ViewBuilder
    private func editDeleteButtons(for button: ButtonConfig) -> some View {
        HStack {
            Button("Изменить") {
                editingButton = button
                showingAddButton = true
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.horizontal, 4)
            
            Button("Удалить") {
                configLoader.deleteButton(button)
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.red)
            .padding(.horizontal, 4)
        }
    }
}


struct AddButtonView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var configLoader: ConfigLoader
    @Binding var buttonToEdit: ButtonConfig?
    
    @State private var name = ""
    @State private var url = ""
    @State private var type = "button"
    @State private var secure = false
    @State private var login = ""
    @State private var password = ""
    
    let types = ["button", "led", "toggle", "push"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Имя", text: $name)
                TextField("URL", text: $url)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Picker("Тип", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                Toggle("Secure", isOn: $secure)
                if secure {
                    TextField("Логин", text: $login)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("Пароль", text: $password)
                }
            }
            .navigationTitle(buttonToEdit == nil ? "Добавить кнопку" : "Редактировать кнопку")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        let newButton = ButtonConfig(
                            id: buttonToEdit?.id ?? UUID(),
                            name: name,
                            url: url,
                            type: type,
                            secure: secure,
                            login: secure ? login : nil,
                            password: secure ? password : nil,
                            isOn: buttonToEdit?.isOn ?? false,
                            isError: buttonToEdit?.isError ?? false,
                            isPressed: buttonToEdit?.isPressed ?? false
                        )
                        if buttonToEdit != nil {
                            configLoader.updateButton(newButton)
                        } else {
                            configLoader.addButton(newButton)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || url.isEmpty || (secure && (login.isEmpty || password.isEmpty)))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let btn = buttonToEdit {
                    name = btn.name
                    url = btn.url
                    type = btn.type
                    secure = btn.secure
                    login = btn.login ?? ""
                    password = btn.password ?? ""
                }
                configLoader.startStatusPolling()
            }
        }
    }
}

struct ImportView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var configLoader: ConfigLoader
    @State private var importUrl = "https://spongo.ru/config.json"
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("URL JSON конфигурации", text: $importUrl)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if let error = errorMessage {
                        Text(error).foregroundColor(.red)
                    }
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Импорт кнопок")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Импорт") {
                        importButtons()
                    }
                    .disabled(importUrl.isEmpty || isLoading)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func importButtons() {
        guard let url = URL(string: importUrl) else {
            errorMessage = "Некорректный URL"
            return
        }
        let delegate = UnsafeURLSessionDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        isLoading = true
        session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Ошибка загрузки: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    errorMessage = "Данные не получены"
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let importedButtons = try decoder.decode([ButtonConfig].self, from: data)
                    configLoader.addButtons(importedButtons)
                    dismiss()
                } catch {
                    errorMessage = "Ошибка разбора JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
