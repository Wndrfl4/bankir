import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var city: String = ""
    @State private var address: String = ""
    @State private var ibanSuffix: String = ""
    @State private var quickLoginEnabled = false
    @State private var marketingEnabled = false
    @State private var preferredLanguage: ProfileExtras.PreferredLanguage = .ru
    @State private var appearanceMode: ProfileExtras.AppearanceMode = .system
    @State private var avatarImageData: Data?
    @State private var avatarImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPasswordSheet = false
    @State private var statusMessage: String?
    @State private var isErrorMessage = false
    @State private var isLoadingProfile = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        profileHeader
                        
                        VStack(spacing: 12) {
                            if authManager.hasAccess(to: .profileEditing) {
                                if let statusMessage {
                                    statusBanner(statusMessage, isError: isErrorMessage)
                                }
                                accountCard
                                securityCard
                                preferencesCard
                                bankingToolsCard
                                supportCard
                            } else {
                                guestCard
                            }
                            actionsCard
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Профиль")
            .task(id: authManager.currentProfileID) {
                await loadProfile()
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                loadAvatar(from: newItem)
            }
            .sheet(isPresented: $showPasswordSheet) {
                PasswordChangeSheet { currentPassword, newPassword in
                    changePassword(currentPassword: currentPassword, newPassword: newPassword)
                }
            }
            .toolbar {
                if authManager.hasAccess(to: .profileEditing) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isSaving ? "Saving..." : "Save") { saveProfile() }
                            .disabled(isSaving || isLoadingProfile)
                    }
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                avatarView
                
                if authManager.hasAccess(to: .profileEditing) {
                    Menu {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Выбрать фото", systemImage: "photo")
                        }
                        if avatarImageData != nil {
                            Button(role: .destructive) {
                                avatarImageData = nil
                                avatarImage = nil
                            } label: {
                                Label("Удалить аватар", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accentStrong)
                            .frame(width: 34, height: 34)
                            .background(Color.white, in: Circle())
                    }
                }
            }
            .padding(.top, 24)
            
            Text(fullName.isEmpty ? username : fullName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            
            Text(authManager.currentRole.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.16), in: Capsule())
            
            if authManager.hasAccess(to: .profileEditing) {
                if isLoadingProfile {
                    ProgressView()
                        .tint(.white)
                }
                HStack(spacing: 12) {
                    compactInfoChip(icon: "phone.fill", text: phoneNumber.isEmpty ? "Телефон не указан" : phoneNumber)
                    compactInfoChip(icon: "mappin.and.ellipse", text: city.isEmpty ? "Город не указан" : city)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private var avatarView: some View {
        Group {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(12)
            }
        }
        .frame(width: 116, height: 116)
        .background(Color.white.opacity(0.18), in: Circle())
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 3))
    }
    
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Личные данные")
            editableField("Полное имя", text: $fullName, icon: "person.text.rectangle")
            editableField("Username", text: $username, icon: "at")
            editableField("Email", text: $email, icon: "envelope.fill", keyboard: .emailAddress)
            editableField("Телефон", text: $phoneNumber, icon: "phone.fill", keyboard: .phonePad)
            editableField("Город", text: $city, icon: "building.2.fill")
            editableField("Адрес", text: $address, icon: "house.fill")
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Безопасность")
            
            HStack {
                infoTile(title: "IBAN", value: ibanSuffix.isEmpty ? "Не добавлен" : "•••• \(ibanSuffix)")
                infoTile(title: "Статус", value: authManager.currentRole == .admin ? "Premium Admin" : "Active")
            }
            
            editableField("Последние 4 цифры IBAN", text: $ibanSuffix, icon: "lock.doc.fill", keyboard: .numberPad)
            Toggle("Быстрый вход", isOn: $quickLoginEnabled)
                .tint(Theme.accent)
            Toggle("Push-уведомления", isOn: $notificationsEnabled)
                .tint(Theme.accent)
            Button {
                showPasswordSheet = true
            } label: {
                Label("Сменить пароль", systemImage: "key.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentStrong)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Настройки")
            
            Toggle("Спецпредложения банка", isOn: $marketingEnabled)
                .tint(Theme.accent)
            Picker("Язык", selection: $preferredLanguage) {
                ForEach(ProfileExtras.PreferredLanguage.allCases) { language in
                    Text(language.rawValue).tag(language)
                }
            }
            .pickerStyle(.segmented)
            Picker("Тема", selection: $appearanceMode) {
                ForEach(ProfileExtras.AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                profileShortcut(icon: "creditcard.fill", title: "Мои карты", subtitle: "Управление картами")
                profileShortcut(icon: "clock.arrow.circlepath", title: "История", subtitle: "Последние операции")
            }
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var bankingToolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Банковские сервисы")
            supportRow(icon: "doc.text.fill", title: "Мои документы", subtitle: "Паспорт, ИИН и данные клиента")
            supportRow(icon: "gauge.with.dots.needle.50percent", title: "Лимиты по операциям", subtitle: "Переводы, снятие и платежи")
            supportRow(icon: "bell.badge.fill", title: "Уведомления и события", subtitle: "Контроль входов и операций по счёту")
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Поддержка")
            supportRow(icon: "headphones.circle.fill", title: "Связаться с банком", subtitle: "Чат и горячая линия 24/7")
            supportRow(icon: "shield.lefthalf.filled", title: "Лимиты и безопасность", subtitle: "Проверь лимиты и активность входов")
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Действия")

            if authManager.currentRole == .guest {
                NavigationLink {
                    LoginView()
                } label: {
                    Label("Войти", systemImage: "person.badge.key.fill")
                        .foregroundStyle(Theme.accentStrong)
                }
            } else {
                Button(role: .destructive) {
                    authManager.logout()
                } label: {
                    Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var guestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Гостевой доступ")
            
            Text("Гость может просматривать главную страницу и профиль, но не может редактировать личные данные, пользоваться продуктами банка и управлять безопасностью.")
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
        }
        .padding()
        .background(Theme.secondaryCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func editableField(_ title: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.accentStrong)
                TextField(title, text: text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private func compactInfoChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.14), in: Capsule())
    }
    
    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func profileShortcut(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accentStrong)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    private func supportRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.accentStrong)
                .frame(width: 38)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedText)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func statusBanner(_ text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? Theme.danger : Theme.success)
            Text(text)
                .font(.footnote)
                .foregroundStyle(isError ? Theme.danger : Theme.success)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isError ? Theme.danger : Theme.success).opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func loadProfile() async {
        guard authManager.hasAccess(to: .profileEditing) else {
            username = "Guest"
            email = ""
            fullName = "Гость"
            phoneNumber = ""
            city = ""
            address = ""
            ibanSuffix = ""
            notificationsEnabled = false
            marketingEnabled = false
            quickLoginEnabled = false
            preferredLanguage = .ru
            appearanceMode = .system
            avatarImageData = nil
            avatarImage = nil
            return
        }
        
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        
        do {
            let profile = try await NetworkManager.shared.fetchCurrentUser()
            username = profile.username
            email = profile.email
            notificationsEnabled = true
            ibanSuffix = profile.accounts.first(where: { $0.isPrimary })?.iban.suffix(4).description ?? ""
            
            if let profileID = authManager.currentProfileID {
                let extras = ProfileLocalStore.load(for: profileID)
                fullName = extras.fullName.isEmpty ? profile.username : extras.fullName
                phoneNumber = extras.phoneNumber
                city = extras.city
                address = extras.address
                quickLoginEnabled = extras.quickLoginEnabled
                marketingEnabled = extras.marketingEnabled
                preferredLanguage = extras.preferredLanguage
                appearanceMode = extras.appearanceMode
                avatarImageData = extras.avatarImageData
                avatarImage = extras.avatarImageData.flatMap(UIImage.init(data:))
                AppPreferencesManager.shared.apply(language: preferredLanguage, appearance: appearanceMode)
            } else {
                fullName = profile.username
                phoneNumber = ""
                city = ""
                address = ""
                quickLoginEnabled = false
                marketingEnabled = false
                preferredLanguage = .ru
                appearanceMode = .system
                avatarImageData = nil
                avatarImage = nil
                AppPreferencesManager.shared.apply(language: preferredLanguage, appearance: appearanceMode)
            }
            
            statusMessage = nil
            isErrorMessage = false
        } catch {
            statusMessage = "Не удалось загрузить профиль: \(error.localizedDescription)"
            isErrorMessage = true
        }
    }

    private func saveProfile() {
        guard authManager.hasAccess(to: .profileEditing) else { return }
        
        guard ValidationUtils.isValidUsername(username) else {
            statusMessage = "Имя пользователя заполнено некорректно"
            isErrorMessage = true
            return
        }
        guard ValidationUtils.isValidEmail(email) else {
            statusMessage = "Email заполнен некорректно"
            isErrorMessage = true
            return
        }
        
        isSaving = true
        Task {
            do {
                let profile = try await NetworkManager.shared.updateCurrentUser(username: username, email: email)
                
                if let profileID = authManager.currentProfileID {
                    let extras = ProfileExtras(
                        fullName: fullName,
                        phoneNumber: phoneNumber,
                        city: city,
                        address: address,
                        ibanSuffix: String(ibanSuffix.suffix(4)),
                        avatarImageData: avatarImageData,
                        quickLoginEnabled: quickLoginEnabled,
                        marketingEnabled: marketingEnabled,
                        preferredLanguage: preferredLanguage,
                        appearanceMode: appearanceMode
                    )
                    ProfileLocalStore.save(extras, for: profileID)
                }
                
                avatarImage = avatarImageData.flatMap(UIImage.init(data:))
                username = profile.username
                email = profile.email
                statusMessage = "Профиль сохранён"
                isErrorMessage = false
                AppPreferencesManager.shared.apply(language: preferredLanguage, appearance: appearanceMode)
            } catch {
                statusMessage = "Не удалось сохранить профиль: \(error.localizedDescription)"
                isErrorMessage = true
            }
            
            isSaving = false
        }
    }
    
    private func loadAvatar(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    avatarImageData = data
                    avatarImage = UIImage(data: data)
                }
            }
        }
    }
    
    private func changePassword(currentPassword: String, newPassword: String) {
        guard ValidationUtils.isValidPassword(newPassword) else {
            statusMessage = "Новый пароль должен быть не короче 6 символов и содержать буквы и цифры"
            isErrorMessage = true
            return
        }
        
        Task {
            do {
                try await NetworkManager.shared.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                statusMessage = "Пароль успешно обновлён"
                isErrorMessage = false
            } catch {
                statusMessage = "Не удалось обновить пароль: \(error.localizedDescription)"
                isErrorMessage = true
            }
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}

private struct PasswordChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    let onSave: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        passwordField("Текущий пароль", text: $currentPassword)
                        passwordField("Новый пароль", text: $newPassword)
                        passwordField("Повторите новый пароль", text: $confirmPassword)
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Theme.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Theme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Button("Сохранить пароль") {
                            guard newPassword == confirmPassword else {
                                errorMessage = "Новый пароль и подтверждение не совпадают"
                                return
                            }
                            onSave(currentPassword, newPassword)
                            dismiss()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Смена пароля")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
    
    private func passwordField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mutedText)
            SecureField(title, text: text)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
