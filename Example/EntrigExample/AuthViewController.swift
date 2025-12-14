import UIKit
import Entrig

/// Auth screen for signing in (matching Flutter AuthScreen exactly)
class AuthViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "message.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Group Chat Demo"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter your name"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        field.autocorrectionType = .no
        field.returnKeyType = .go
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        field.leftViewMode = .always

        let iconView = UIImageView(frame: CGRect(x: 8, y: 8, width: 24, height: 24))
        iconView.image = UIImage(systemName: "person.fill")
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        field.leftView?.addSubview(iconView)

        return field
    }()

    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Add subviews
        [iconImageView, titleLabel, nameTextField, signInButton, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),

            signInButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            signInButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            signInButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            signInButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            activityIndicator.centerXAnchor.constraint(equalTo: signInButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: signInButton.centerYAnchor)
        ])
    }

    private func setupActions() {
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        nameTextField.delegate = self
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(message: "Please enter your name")
            return
        }

        nameTextField.resignFirstResponder()
        isLoading = true

        Task {
            do {
                // Sign in anonymously (matching Flutter logic exactly)
                let userId = try await AuthService.shared.signIn(name: name)
                print("[Auth] ✅ Signed in successfully: \(userId)")

                // Register with Entrig for push notifications
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    Entrig.register(userId: userId) { success, error in
                        if success {
                            print("[Auth] ✅ Registered with Entrig")
                        } else {
                            print("[Auth] ⚠️ Entrig registration failed: \(error ?? "Unknown error")")
                        }
                        continuation.resume()
                    }
                }

                await MainActor.run {
                    isLoading = false
                    navigateToHome()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showAlert(message: "Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func navigateToHome() {
        let groupsVC = GroupsViewController()
        let navController = UINavigationController(rootViewController: groupsVC)
        navController.modalPresentationStyle = .fullScreen

        if let window = view.window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = navController
            }
        }
    }

    private func updateLoadingState() {
        signInButton.isEnabled = !isLoading
        signInButton.alpha = isLoading ? 0.6 : 1.0
        signInButton.setTitle(isLoading ? "" : "Sign In", for: .normal)

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        signInTapped()
        return true
    }
}
