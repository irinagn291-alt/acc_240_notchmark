import SwiftUI
import UIKit

/// Role: Rail. Sheet to open a new Article on the rail.
struct AddArticleSheet: View {
    @ObservedObject var session: RailSession
    var onClose: () -> Void

    @State private var name = ""
    @State private var priceText = ""
    @State private var shareMethod: ShareMethod = .dividedByTargetUses
    @State private var manualShareText = ""
    @State private var targetUsesText = "10"
    @State private var disposalText = "0"
    @State private var validationMessage: String?
    @State private var isSaving = false
    @State private var showScanner = false
    @State private var scannedPrice: Double?
    @State private var showDiscard = false
    @FocusState private var focused: Field?

    private enum Field: Hashable {
        case name, price, share, uses, disposal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
            LedgerSheetBar(title: "Add Article", onClose: requestClose)
            ScrollView {
                VStack(alignment: .leading, spacing: LedgerPalette.space(2)) {
                    field("Name", text: $name, field: .name)
                    field("Purchase price", text: $priceText, keyboard: .decimalPad, field: .price)
                    Picker("Share method", selection: $shareMethod) {
                        Text("Price ÷ target uses").tag(ShareMethod.dividedByTargetUses)
                        Text("Manual share").tag(ShareMethod.manualShare)
                    }
                    .pickerStyle(.segmented)
                    .frame(minHeight: LedgerPalette.tap)
                    if shareMethod == .manualShare {
                        field("Per-notch share", text: $manualShareText, keyboard: .decimalPad, field: .share)
                    } else {
                        field("Target uses", text: $targetUsesText, keyboard: .numberPad, field: .uses)
                    }
                    field("Disposal value", text: $disposalText, keyboard: .decimalPad, field: .disposal)
                    Button {
                        focused = nil
                        showScanner = true
                    } label: {
                        Text("Scan a price tag")
                            .font(.ledger(.body))
                            .foregroundStyle(LedgerPalette.accent)
                            .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                            .background(LedgerPalette.surface)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.ledger(.footnote))
                            .foregroundStyle(LedgerPalette.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Button(action: save) {
                Text(isSaving ? "Opening…" : "Open Article")
                    .font(.ledger(.body))
                    .foregroundStyle(LedgerPalette.background)
                    .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                    .background(canSave ? LedgerPalette.accent : LedgerPalette.ink.opacity(0.35))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canSave || isSaving)
        }
        .padding(LedgerPalette.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LedgerPalette.background
                .ignoresSafeArea()
                .onTapGesture { focused = nil }
        )
        .onAppear {
            shareMethod = session.settings.defaultShareMethod
        }
        .onChange(of: scannedPrice, initial: false) { _, price in
            guard let price else { return }
            priceText = CurrencyFormatting.decimalString(price)
            validatePrice()
        }
        .onChange(of: priceText, initial: false) { _, _ in validatePrice() }
        .onChange(of: manualShareText, initial: false) { _, _ in validateShare() }
        .onChange(of: disposalText, initial: false) { _, _ in validateDisposal() }
        .fullScreenCover(isPresented: $showScanner) {
            PriceScannerSheet(scannedPrice: $scannedPrice)
        }
        .confirmationDialog(
            "Discard this Article?",
            isPresented: $showDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep editing", role: .cancel) {}
        }
    }

    private var isDirty: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !priceText.isEmpty
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && CurrencyFormatting.parseDecimal(priceText) != nil
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: LedgerPalette.space(1)) {
            Text(title)
                .font(.ledger(.body))
                .foregroundStyle(LedgerPalette.ink)
            TextField(title, text: text)
                .font(.ledger(.stampNumeral))
                .foregroundStyle(LedgerPalette.ink)
                .keyboardType(keyboard)
                .focused($focused, equals: field)
                .padding(LedgerPalette.space(1))
                .frame(maxWidth: .infinity, minHeight: LedgerPalette.tap)
                .background(LedgerPalette.surface)
        }
    }

    private func requestClose() {
        focused = nil
        if isDirty {
            showDiscard = true
        } else {
            onClose()
        }
    }

    private func validatePrice() {
        if priceText.isEmpty {
            validationMessage = nil
            return
        }
        if CurrencyFormatting.parseDecimal(priceText) == nil {
            validationMessage = "Enter a price that is zero or greater."
        } else {
            validationMessage = nil
        }
    }

    private func validateShare() {
        guard shareMethod == .manualShare, !manualShareText.isEmpty else { return }
        if CurrencyFormatting.parseDecimal(manualShareText) == nil {
            validationMessage = "Enter a share that is zero or greater."
        }
    }

    private func validateDisposal() {
        guard !disposalText.isEmpty else { return }
        if CurrencyFormatting.parseDecimal(disposalText) == nil {
            validationMessage = "Enter a disposal value that is zero or greater."
        }
    }

    private func save() {
        focused = nil
        validationMessage = nil
        isSaving = true
        guard let price = CurrencyFormatting.parseDecimal(priceText) else {
            isSaving = false
            validationMessage = "Enter a price that is zero or greater."
            return
        }
        let manual = CurrencyFormatting.parseDecimal(manualShareText) ?? 0
        let target = CurrencyFormatting.parseInteger(targetUsesText)
        let disposal = CurrencyFormatting.parseDecimal(disposalText) ?? 0
        do {
            let article = try openingArticle(
                name: name,
                purchasePrice: price,
                shareMethod: shareMethod,
                manualShare: manual,
                targetUses: target,
                disposalValue: disposal
            )
            Task {
                await session.addArticle(article)
                isSaving = false
                onClose()
            }
        } catch {
            isSaving = false
            validationMessage = String(describing: error)
        }
    }
}
