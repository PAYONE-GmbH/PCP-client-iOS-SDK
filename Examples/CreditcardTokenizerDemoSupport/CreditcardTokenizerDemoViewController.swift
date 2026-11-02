// Shared educational UIKit screen used by both example apps, not part of the SDK product.
import PCPClient
import UIKit

@objc public final class CreditcardTokenizerDemoViewController: UIViewController {
    private let configuration: CreditcardTokenizerDemoConfiguration
    private let initialToken: String?
    private let tokenEditor = UIStackView()
    private let changeTokenButton = UIButton(type: .system)
    private let tokenInput = UITextView()
    private let statusLabel = UILabel()
    private let eventsView = UITextView()
    private let formContainer = UIView()
    private var tokenizer: CreditcardTokenizerViewController?
    private var events: [String] = []

    /// A nonblank plist token loads immediately; replacement input is revealed on demand.
    @objc public init(configuration: CreditcardTokenizerDemoConfiguration) {
        self.configuration = configuration
        let configured = configuration.token?.trimmingCharacters(in: .whitespacesAndNewlines)
        initialToken = configured?.isEmpty == false ? configured : nil
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Creditcard Tokenizer"
        view.backgroundColor = .systemBackground
        let scroll = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(scroll)
        scroll.addSubview(stack)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
        let instructions = UILabel()
        instructions.text = "Aktuellen PCP-Token einfügen, dann Formular laden. Ein neuer Token benötigt ein neu geladenes Formular."
        instructions.numberOfLines = 0
        changeTokenButton.setTitle("Neuen Token benutzen", for: .normal)
        changeTokenButton.accessibilityIdentifier = "tokenizer.changeToken"
        changeTokenButton.addTarget(self, action: #selector(showTokenEditor), for: .touchUpInside)
        changeTokenButton.isHidden = initialToken == nil
        stack.addArrangedSubview(changeTokenButton)
        tokenEditor.axis = .vertical
        tokenEditor.spacing = 8
        tokenEditor.accessibilityIdentifier = "tokenizer.tokenEditor"
        tokenEditor.isHidden = initialToken != nil
        stack.addArrangedSubview(tokenEditor)
        tokenEditor.addArrangedSubview(instructions)
        tokenInput.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tokenInput.autocapitalizationType = .none
        tokenInput.autocorrectionType = .no
        tokenInput.layer.borderWidth = 1
        tokenInput.layer.borderColor = UIColor.separator.cgColor
        tokenInput.accessibilityLabel = "PCP token"
        tokenInput.accessibilityIdentifier = "tokenizer.tokenInput"
        tokenInput.text = initialToken ?? ""
        tokenInput.heightAnchor.constraint(equalToConstant: 90).isActive = true
        tokenEditor.addArrangedSubview(tokenInput)
        let load = UIButton(type: .system)
        load.setTitle("Formular mit diesem Token laden", for: .normal)
        load.accessibilityIdentifier = "tokenizer.loadToken"
        load.addTarget(self, action: #selector(loadTokenizer), for: .touchUpInside)
        tokenEditor.addArrangedSubview(load)
        statusLabel.numberOfLines = 0
        statusLabel.accessibilityIdentifier = "tokenizer.status"
        statusLabel.text = "Noch kein Formular geladen."
        stack.addArrangedSubview(statusLabel)
        formContainer.heightAnchor.constraint(equalToConstant: CGFloat(configuration.iframeHeight + 160)).isActive = true
        stack.addArrangedSubview(formContainer)
        let heading = UILabel()
        heading.text = "Requests & Responses"
        heading.font = .preferredFont(forTextStyle: .headline)
        stack.addArrangedSubview(heading)
        let note = UILabel()
        note.numberOfLines = 0
        note.font = .preferredFont(forTextStyle: .caption1)
        note.text = configuration.includeSensitiveDiagnosticData
            ? "Example-Modus: Token und gesendete Kartendaten werden in diesem Ablaufprotokoll angezeigt."
            : "Metadaten der Hosted-SDK-Aufrufe; Token und Kartendaten werden nicht angezeigt."
        stack.addArrangedSubview(note)
        eventsView.isEditable = false
        eventsView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventsView.backgroundColor = .secondarySystemBackground
        eventsView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        stack.addArrangedSubview(eventsView)
        let clear = UIButton(type: .system)
        clear.setTitle("Protokoll leeren", for: .normal)
        clear.addTarget(self, action: #selector(clearEvents), for: .touchUpInside)
        stack.addArrangedSubview(clear)
        if initialToken != nil { loadTokenizer() }
    }

    @objc private func showTokenEditor() {
        tokenInput.text = ""
        tokenEditor.isHidden = false
        changeTokenButton.isHidden = true
        tokenInput.becomeFirstResponder()
    }

    @objc private func loadTokenizer() {
        let token = tokenInput.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { setStatus("Bitte einen gültigen PCP-Token einfügen."); return }
        tokenizer?.willMove(toParent: nil)
        tokenizer?.view.removeFromSuperview()
        tokenizer?.removeFromParent()
        let config = configuration.makeSDKConfiguration(token: token, success: { [weak self] status, _, _, _ in
            self?.setStatus("Tokenisierung erfolgreich (Status \(status)).")
        }, failure: { [weak self] status, response in
            self?.setStatus("Tokenisierung fehlgeschlagen: \(response["error"] ?? "Backend-Fehler") (Status \(status)).")
        })
        let controller = CreditcardTokenizerViewController(tokenizerUrl: configuration.tokenizerURL, config: config)
        controller.localHTMLBaseURL = configuration.localHTMLBaseURL
        controller.includeSensitiveDiagnosticData = configuration.includeSensitiveDiagnosticData
        controller.onDiagnosticEvent = { [weak self, weak controller] name, details in
            guard let self, self.tokenizer === controller else { return }
            if name == "Response · getPaymentPage", details["statusCode"] as? Int == 200,
               self.statusLabel.text == "Formular wird geladen …" {
                self.statusLabel.isHidden = true
            }
            self.record(name, details: details)
        }
        tokenizer = controller
        addChild(controller)
        formContainer.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: formContainer.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor)
        ])
        controller.didMove(toParent: self)
        setStatus("Formular wird geladen …")
        tokenInput.resignFirstResponder()
        if initialToken != nil {
            tokenEditor.isHidden = true
            changeTokenButton.isHidden = false
        }
    }

    private func setStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.isHidden = false
    }

    private func record(_ name: String, details: [String: Any]) {
        let json = (try? JSONSerialization.data(withJSONObject: details, options: [.prettyPrinted, .sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "{}"
        events.append("\(Date().formatted(date: .omitted, time: .standard)) · \(name)\n\(json)")
        if events.count > 100 { events.removeFirst(events.count - 100) }
        eventsView.text = events.joined(separator: "\n\n")
        eventsView.scrollRangeToVisible(NSRange(location: (eventsView.text as NSString).length, length: 0))
    }

    @objc private func clearEvents() {
        events.removeAll()
        eventsView.text = ""
    }
}
