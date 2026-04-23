import SwiftUI
import Combine

// MARK: - Common UI State
enum FormState: Equatable {
    case idle
    case loading
    case success(String)
    case error(String)
}

// MARK: - Theme is defined in Theme.swift

// MARK: - Utilities (Masks & Validation)
private func digitsOnly(_ string: String) -> String {
    string.filter { $0.isNumber }
}

private func applyPatternOnNumbers(_ pattern: String, replacementCharacter: Character = "#", to raw: String) -> String {
    let numbers = digitsOnly(raw)
    var result = ""
    var index = numbers.startIndex

    for ch in pattern where index < numbers.endIndex {
        if ch == replacementCharacter {
            result.append(numbers[index])
            index = numbers.index(after: index)
        } else {
            result.append(ch)
        }
    }
    return result
}

// MARK: - Reusable Components
struct CardContainer<Content: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(Theme.cardPadding)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct StatusBanner: View {
    let state: FormState

    var body: some View {
        switch state {
        case .idle, .loading:
            EmptyView()
        case .success(let message):
            banner(message: message, color: .green)
        case .error(let message):
            banner(message: message, color: .red)
        }
    }

    @ViewBuilder
    private func banner(message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: color == .green ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(color)
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var field: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            field
                .padding(12)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - Transfer Money
final class TransferViewModel: ObservableObject {
    struct TransferCard {
        let title: String
        let number: String
    }

    @Published var fromCardIndex: Int = 0
    @Published var toCardRaw: String = ""
    @Published var amount: Decimal = 0
    @Published var note: String = ""
    @Published var state: FormState = .idle

    private let api: PaymentsAPI
    private let rateLimiter = RateLimiter(maxAttempts: 3, timeWindow: 300) // 3 попытки в 5 минут

    let cards: [TransferCard] = [
        .init(title: "• • • • 1234 · Kaspi Gold", number: "1111222233331234"),
        .init(title: "• • • • 5678 · Revolut", number: "1111222233335678"),
        .init(title: "• • • • 9012 · Tinkoff", number: "1111222233339012")
    ]

    init(api: PaymentsAPI = DefaultPaymentsAPI.shared) {
        self.api = api
    }

    var toCardMasked: String {
        get { applyPatternOnNumbers("#### #### #### ####", to: toCardRaw) }
        set { toCardRaw = digitsOnly(newValue) }
    }

    var isValid: Bool {
        ValidationUtils.isValidCardNumber(toCardRaw) && ValidationUtils.isValidAmount(amount.description)
    }

    @MainActor
    func submit() async {
        guard isValid else {
            state = .error("Проверьте номер карты и сумму.")
            return
        }
        
        // Проверка rate limiting
        guard rateLimiter.canAttempt() else {
            state = .error("Слишком много попыток. Попробуйте позже.")
            return
        }
        
        state = .loading
        
        // Санитизация перед отправкой
        let sanitizedNote = InputSanitization.sanitizeForAPI(note, maxLength: 100)
        
        do {
            try await api.transfer(
                fromCard: cards[fromCardIndex].number,
                toCard: digitsOnly(toCardRaw),
                amount: amount,
                note: sanitizedNote
            )
            rateLimiter.recordAttempt()
            state = .success("Перевод успешно отправлен на карту •••• \(String(toCardMasked.suffix(4))).")
        } catch {
            state = .error("Не удалось выполнить перевод. Попробуйте позже.")
        }
    }

    func resetIfNeeded() {
        if case .success = state { amount = 0; toCardRaw = ""; note = "" }
    }
}

struct TransferScreen: View {
    @StateObject private var vm = TransferViewModel()
    @FocusState private var focusedField: Field?

    enum Field { case toCard, amount, note }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                StatusBanner(state: vm.state)

                CardContainer(title: "Перевод между картами") {
                    LabeledField(label: "С какой карты") {
                        Picker("Карта", selection: $vm.fromCardIndex) {
                            ForEach(vm.cards.indices, id: \.self) { idx in
                                Text(vm.cards[idx].title).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    LabeledField(label: "Номер карты получателя") {
                        TextField("0000 0000 0000 0000", text: Binding(
                            get: { vm.toCardMasked },
                            set: { vm.toCardMasked = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .textContentType(.creditCardNumber)
                        .focused($focusedField, equals: .toCard)
                        .privacySensitive(true)
                    }

                    LabeledField(label: "Сумма") {
                        TextField("", value: $vm.amount, format: .currency(code: "KZT"))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .privacySensitive(true)
                    }

                    LabeledField(label: "Комментарий (необязательно)") {
                        TextField("За обед…", text: $vm.note)
                            .focused($focusedField, equals: .note)
                    }

                    PrimaryButton(title: vm.state == .loading ? "Отправка…" : "Отправить", isLoading: vm.state == .loading) {
                        focusedField = nil
                        Task { await vm.submit() }
                    }
                    .disabled(!vm.isValid || vm.state == .loading)
                }
            }
            .padding()
        }
        .navigationTitle("Перевод")
        .onChange(of: vm.state) { newValue in
            switch newValue {
            case .success:
                Haptics.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    vm.resetIfNeeded()
                }
            case .error:
                Haptics.error()
            default:
                break
            }
        }
    }
}

// MARK: - Mobile Top-Up
final class TopUpViewModel: ObservableObject {
    enum Provider: String, CaseIterable, Identifiable { case Beeline, Kcell, Tele2; var id: String { rawValue } }

    @Published var provider: Provider = .Beeline
    @Published var phoneRaw: String = ""
    @Published var amount: Decimal = 0
    @Published var state: FormState = .idle

    private let api: PaymentsAPI
    private let rateLimiter = RateLimiter(maxAttempts: 5, timeWindow: 600) // 5 попыток в 10 минут

    init(api: PaymentsAPI = DefaultPaymentsAPI.shared) {
        self.api = api
    }

    var phoneMasked: String {
        get { applyPatternOnNumbers("+7 (###) ###-##-##", to: phoneRaw) }
        set { phoneRaw = digitsOnly(newValue) }
    }

    var isValid: Bool {
        ValidationUtils.isValidPhone(phoneMasked) && ValidationUtils.isValidAmount(amount.description)
    }

    @MainActor
    func submit() async {
        guard isValid else {
            state = .error("Проверьте номер телефона и сумму.")
            return
        }
        
        // Проверка rate limiting
        guard rateLimiter.canAttempt() else {
            state = .error("Слишком много попыток пополнения. Попробуйте позже.")
            return
        }
        
        state = .loading
        do {
            try await api.topUp(provider: provider.rawValue, phone: digitsOnly(phoneRaw), amount: amount)
            rateLimiter.recordAttempt()
            state = .success("Пополнение на номер \(phoneMasked) выполнено.")
        } catch {
            state = .error("Сервис временно недоступен.")
        }
    }
}

struct TopUpScreen: View {
    @StateObject private var vm = TopUpViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                StatusBanner(state: vm.state)

                CardContainer(title: "Пополнение мобильного") {
                    LabeledField(label: "Оператор") {
                        Picker("Оператор", selection: $vm.provider) {
                            ForEach(TopUpViewModel.Provider.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LabeledField(label: "Номер телефона") {
                        TextField("+7 (___) ___-__-__", text: Binding(
                            get: { vm.phoneMasked },
                            set: { vm.phoneMasked = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .privacySensitive(true)
                    }

                    LabeledField(label: "Сумма") {
                        TextField("", value: $vm.amount, format: .currency(code: "KZT"))
                            .keyboardType(.decimalPad)
                            .privacySensitive(true)
                    }

                    PrimaryButton(title: vm.state == .loading ? "Оплата…" : "Оплатить", isLoading: vm.state == .loading) {
                        focused = false
                        Task { await vm.submit() }
                    }
                    .disabled(!vm.isValid || vm.state == .loading)
                }
            }
            .padding()
        }
        .navigationTitle("Пополнение")
        .onChange(of: vm.state) { newValue in
            switch newValue {
            case .success:
                Haptics.success()
            case .error:
                Haptics.error()
            default:
                break
            }
        }
    }
}


// MARK: - Pay Bill
final class PayBillViewModel: ObservableObject {
    enum Category: String, CaseIterable, Identifiable { case utilities = "Коммунальные", internet = "Интернет", tv = "TV"; var id: String { rawValue } }

    @Published var category: Category = .utilities
    @Published var accountRaw: String = ""
    @Published var amount: Decimal = 0
    @Published var state: FormState = .idle

    private let api: PaymentsAPI
    private let rateLimiter = RateLimiter(maxAttempts: 3, timeWindow: 300) // 3 попытки в 5 минут

    init(api: PaymentsAPI = DefaultPaymentsAPI.shared) {
        self.api = api
    }

    var accountMasked: String {
        get { applyPatternOnNumbers("###-####-######", to: accountRaw) }
        set { accountRaw = digitsOnly(newValue) }
    }

    var isValid: Bool {
        accountMasked.count >= 6 && ValidationUtils.isValidAmount(amount.description)
    }

    @MainActor
    func submit() async {
        guard isValid else {
            state = .error("Проверьте данные лицевого счета и сумму.")
            return
        }
        
        // Проверка rate limiting
        guard rateLimiter.canAttempt() else {
            state = .error("Слишком много попыток оплаты. Попробуйте позже.")
            return
        }
        
        state = .loading
        
        // Санитизация лицевого счета
        let sanitizedAccount = InputSanitization.alphanumericNoSpaces(digitsOnly(accountRaw))
        
        do {
            try await api.payBill(category: category.rawValue, account: sanitizedAccount, amount: amount)
            rateLimiter.recordAttempt()
            state = .success("Платеж по лицевому счету \(accountMasked) принят.")
        } catch {
            state = .error("Ошибка платежа. Повторите попытку.")
        }
    }
}

struct PayBillScreen: View {
    @StateObject private var vm = PayBillViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                StatusBanner(state: vm.state)

                CardContainer(title: "Оплата услуг") {
                    LabeledField(label: "Категория") {
                        Picker("Категория", selection: $vm.category) {
                            ForEach(PayBillViewModel.Category.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    LabeledField(label: "Лицевой счет") {
                        TextField("000-0000-000000", text: Binding(
                            get: { vm.accountMasked },
                            set: { vm.accountMasked = $0 }
                        ))
                        .keyboardType(.numberPad)
                        .focused($focused)
                        .privacySensitive(true)
                    }

                    LabeledField(label: "Сумма") {
                        TextField("", value: $vm.amount, format: .currency(code: "KZT"))
                            .keyboardType(.decimalPad)
                            .privacySensitive(true)
                    }

                    PrimaryButton(title: vm.state == .loading ? "Оплата…" : "Оплатить", isLoading: vm.state == .loading) {
                        focused = false
                        Task { await vm.submit() }
                    }
                    .disabled(!vm.isValid || vm.state == .loading)
                }
            }
            .padding()
        }
        .navigationTitle("Оплата")
        .onChange(of: vm.state) { newValue in
            switch newValue {
            case .success:
                Haptics.success()
            case .error:
                Haptics.error()
            default:
                break
            }
        }
    }
}

// MARK: - Previews
#Preview("Transfer") {
    NavigationStack { TransferScreen() }
}

#Preview("TopUp") {
    NavigationStack { TopUpScreen() }
}

#Preview("Pay Bill") {
    NavigationStack { PayBillScreen() }
}
