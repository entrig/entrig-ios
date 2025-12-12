//import UIKit
//import EntrigSDK
//
//class HomeViewController: UIViewController {
//
//    // MARK: - UI Components
//
//    private let scrollView = UIScrollView()
//    private let stackView: UIStackView = {
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.spacing = 20
//        stack.alignment = .fill
//        stack.distribution = .fill
//        return stack
//    }()
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Entrig SDK Example"
//        label.font = .systemFont(ofSize: 28, weight: .bold)
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let statusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Status: Not Registered"
//        label.font = .systemFont(ofSize: 16)
//        label.textAlignment = .center
//        label.textColor = .secondaryLabel
//        return label
//    }()
//
//    private let userIdTextField: UITextField = {
//        let field = UITextField()
//        field.placeholder = "Enter User ID"
//        field.borderStyle = .roundedRect
//        field.autocapitalizationType = .none
//        field.autocorrectionType = .no
//        field.text = "user-\(UUID().uuidString.prefix(8))"
//        return field
//    }()
//
//    private let registerButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Register User", for: .normal)
//        button.backgroundColor = .systemBlue
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 10
//        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
//        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
//        return button
//    }()
//
//    private let unregisterButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Unregister User", for: .normal)
//        button.backgroundColor = .systemRed
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 10
//        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
//        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
//        button.isEnabled = false
//        button.alpha = 0.5
//        return button
//    }()
//
//    private let requestPermissionButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Request Permission", for: .normal)
//        button.backgroundColor = .systemOrange
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 10
//        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
//        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
//        return button
//    }()
//
//    private let notificationLogLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Notification Log"
//        label.font = .systemFont(ofSize: 20, weight: .semibold)
//        return label
//    }()
//
//    private let logTextView: UITextView = {
//        let textView = UITextView()
//        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
//        textView.layer.borderColor = UIColor.separator.cgColor
//        textView.layer.borderWidth = 1
//        textView.layer.cornerRadius = 8
//        textView.isEditable = false
//        textView.text = "Waiting for notifications...\n"
//        return textView
//    }()
//
//    private let clearLogButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Clear Log", for: .normal)
//        return button
//    }()
//
//    private var isRegistered = false
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupNotificationListeners()
//        checkInitialNotification()
//    }
//
//    // MARK: - Setup
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "Entrig Example"
//
//        // Setup scroll view
//        view.addSubview(scrollView)
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//
//        // Setup stack view
//        scrollView.addSubview(stackView)
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
//            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
//            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
//            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
//            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
//        ])
//
//        // Add components to stack
//        stackView.addArrangedSubview(titleLabel)
//        stackView.addArrangedSubview(statusLabel)
//        stackView.addArrangedSubview(createSpacer(height: 10))
//        stackView.addArrangedSubview(userIdTextField)
//        stackView.addArrangedSubview(registerButton)
//        stackView.addArrangedSubview(unregisterButton)
//        stackView.addArrangedSubview(requestPermissionButton)
//        stackView.addArrangedSubview(createSpacer(height: 20))
//        stackView.addArrangedSubview(notificationLogLabel)
//        stackView.addArrangedSubview(logTextView)
//        stackView.addArrangedSubview(clearLogButton)
//
//        // Set log text view height
//        logTextView.heightAnchor.constraint(equalToConstant: 200).isActive = true
//
//        // Add button actions
//        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
//        unregisterButton.addTarget(self, action: #selector(unregisterTapped), for: .touchUpInside)
//        requestPermissionButton.addTarget(self, action: #selector(requestPermissionTapped), for: .touchUpInside)
//        clearLogButton.addTarget(self, action: #selector(clearLogTapped), for: .touchUpInside)
//    }
//
//    private func createSpacer(height: CGFloat) -> UIView {
//        let spacer = UIView()
//        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
//        return spacer
//    }
//
//    private func setupNotificationListeners() {
//        Entrig.setOnNotificationReceivedListener(self)
//        Entrig.setOnNotificationClickListener(self)
//    }
//
//    private func checkInitialNotification() {
//        if let notification = Entrig.getInitialNotification() {
//            log("🚀 Initial Notification (Cold Start):")
//            log("  Title: \(notification.title)")
//            log("  Body: \(notification.body)")
//            log("  Type: \(notification.type ?? "none")")
//            log("  Data: \(notification.data)")
//            log("---")
//        }
//    }
//
//    // MARK: - Actions
//
//    @objc private func registerTapped() {
//        guard let userId = userIdTextField.text, !userId.isEmpty else {
//            showAlert(title: "Error", message: "Please enter a user ID")
//            return
//        }
//
//        userIdTextField.resignFirstResponder()
//        registerButton.isEnabled = false
//        log("📝 Registering user: \(userId)...")
//
//        Entrig.register(userId: userId) { [weak self] success, error in
//            DispatchQueue.main.async {
//                self?.registerButton.isEnabled = true
//
//                if success {
//                    self?.isRegistered = true
//                    self?.updateUI()
//                    self?.log("✅ Registration successful!")
//                    self?.showAlert(title: "Success", message: "User registered successfully")
//                } else {
//                    self?.log("❌ Registration failed: \(error ?? "Unknown error")")
//                    self?.showAlert(title: "Error", message: error ?? "Registration failed")
//                }
//            }
//        }
//    }
//
//    @objc private func unregisterTapped() {
//        unregisterButton.isEnabled = false
//        log("📝 Unregistering user...")
//
//        Entrig.unregister { [weak self] success, error in
//            DispatchQueue.main.async {
//                self?.unregisterButton.isEnabled = true
//
//                if success {
//                    self?.isRegistered = false
//                    self?.updateUI()
//                    self?.log("✅ Unregistration successful!")
//                    self?.showAlert(title: "Success", message: "User unregistered successfully")
//                } else {
//                    self?.log("❌ Unregistration failed: \(error ?? "Unknown error")")
//                    self?.showAlert(title: "Error", message: error ?? "Unregistration failed")
//                }
//            }
//        }
//    }
//
//    @objc private func requestPermissionTapped() {
//        log("📝 Requesting notification permission...")
//
//        Entrig.requestPermission { [weak self] granted, error in
//            if let error = error {
//                self?.log("❌ Permission error: \(error.localizedDescription)")
//                return
//            }
//
//            if granted {
//                self?.log("✅ Notification permission granted")
//            } else {
//                self?.log("⚠️ Notification permission denied")
//            }
//        }
//    }
//
//    @objc private func clearLogTapped() {
//        logTextView.text = ""
//    }
//
//    // MARK: - Helper Methods
//
//    private func updateUI() {
//        statusLabel.text = isRegistered ? "Status: Registered ✓" : "Status: Not Registered"
//        statusLabel.textColor = isRegistered ? .systemGreen : .secondaryLabel
//        unregisterButton.isEnabled = isRegistered
//        unregisterButton.alpha = isRegistered ? 1.0 : 0.5
//        registerButton.isEnabled = !isRegistered
//        registerButton.alpha = !isRegistered ? 1.0 : 0.5
//        userIdTextField.isEnabled = !isRegistered
//    }
//
//    private func log(_ message: String) {
//        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//        logTextView.text += "[\(timestamp)] \(message)\n"
//
//        // Scroll to bottom
//        let range = NSRange(location: logTextView.text.count - 1, length: 1)
//        logTextView.scrollRangeToVisible(range)
//    }
//
//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//}
//
//// MARK: - OnNotificationReceivedListener
//
//extension HomeViewController: OnNotificationReceivedListener {
//    func onNotificationReceived(_ notification: NotificationEvent) {
//        log("🔔 Foreground Notification:")
//        log("  Title: \(notification.title)")
//        log("  Body: \(notification.body)")
//        log("  Type: \(notification.type ?? "none")")
//        log("  Data: \(notification.data)")
//        log("---")
//    }
//}
//
//// MARK: - OnNotificationClickListener
//
//extension HomeViewController: OnNotificationClickListener {
//    func onNotificationClick(_ notification: NotificationEvent) {
//        log("👆 Notification Clicked:")
//        log("  Title: \(notification.title)")
//        log("  Body: \(notification.body)")
//        log("  Type: \(notification.type ?? "none")")
//        log("  Data: \(notification.data)")
//        log("---")
//
//        // Show alert with notification details
//        showAlert(
//            title: notification.title,
//            message: notification.body
//        )
//    }
//}
