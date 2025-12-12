import UIKit
import Supabase

/// Chat screen for group messaging (matching Flutter ChatScreen exactly)
class ChatViewController: UIViewController {

    // MARK: - Properties

    private let groupId: String
    private let groupName: String

    private var messages: [Message] = []
    private var userNames: [String: String] = [:]
    private var isLoading = true
    private var realtimeChannel: RealtimeChannelV2?

    private let tableView = UITableView()
    private let messageInputView = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var messageInputBottomConstraint: NSLayoutConstraint!

    // MARK: - Initialization

    init(groupId: String, groupName: String) {
        self.groupId = groupId
        self.groupName = groupName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        joinGroupAndLoadMessages()
        subscribeToMessages()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await realtimeChannel?.unsubscribe()
        }
        realtimeChannel = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = groupName

        // Setup table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1) // Reverse table view

        // Setup message input
        view.addSubview(messageInputView)
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        messageInputView.backgroundColor = .systemBackground
        messageInputView.layer.shadowColor = UIColor.black.cgColor
        messageInputView.layer.shadowOffset = CGSize(width: 0, height: -2)
        messageInputView.layer.shadowOpacity = 0.1
        messageInputView.layer.shadowRadius = 4

        messageInputView.addSubview(messageTextField)
        messageInputView.addSubview(sendButton)

        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageTextField.placeholder = "Type a message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.autocapitalizationType = .sentences
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .systemBlue
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        // Setup activity indicator
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        messageInputBottomConstraint = messageInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),

            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBottomConstraint,
            messageInputView.heightAnchor.constraint(equalToConstant: 80),

            messageTextField.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 16),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextField.topAnchor.constraint(equalTo: messageInputView.topAnchor, constant: 16),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),

            sendButton.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: messageTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Data Loading

    private func joinGroupAndLoadMessages() {
        guard let userId = AuthService.shared.currentUserId else { return }

        isLoading = true
        activityIndicator.startAnimating()

        Task {
            do {
                // Check if already member, if not join
                let isMember = try await SupabaseService.shared.checkIfUserInGroup(
                    groupId: groupId,
                    userId: userId
                )

                if !isMember {
                    try await SupabaseService.shared.joinGroup(groupId: groupId, userId: userId)
                }

                // Load messages
                try await loadMessages()

                await MainActor.run {
                    isLoading = false
                    activityIndicator.stopAnimating()
                    tableView.reloadData()
                    scrollToBottom()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    activityIndicator.stopAnimating()
                    showAlert(message: "Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadMessages() async throws {
        let loadedMessages = try await SupabaseService.shared.getMessages(groupId: groupId)

        // Extract user names
        var names: [String: String] = [:]
        for message in loadedMessages {
            if let senderName = message.senderName {
                names[message.userId] = senderName
            }
        }

        await MainActor.run {
            messages = loadedMessages.reversed() // Reverse for bottom-up display
            userNames = names
        }
    }

    private func subscribeToMessages() {
        realtimeChannel = SupabaseService.shared.subscribeToMessages(groupId: groupId) { [weak self] newMessage in
            guard let self = self else { return }

            Task {
                // Fetch sender name if not cached
                if self.userNames[newMessage.userId] == nil {
                    do {
                        let user = try await SupabaseService.shared.getUser(id: newMessage.userId)
                        await MainActor.run {
                            self.userNames[newMessage.userId] = user.name
                        }
                    } catch {
                        print("[Chat] Error fetching user: \(error)")
                    }
                }

                await MainActor.run {
                    var messageWithName = newMessage
                    messageWithName.senderName = self.userNames[newMessage.userId]

                    self.messages.insert(messageWithName, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.scrollToBottom()
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func sendMessage() {
        guard let content = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty,
              let userId = AuthService.shared.currentUserId else { return }

        messageTextField.text = ""

        Task {
            do {
                try await SupabaseService.shared.sendMessage(
                    content: content,
                    userId: userId,
                    groupId: groupId
                )
            } catch {
                await MainActor.run {
                    showAlert(message: "Error sending message: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        messageInputBottomConstraint.constant = -keyboardFrame.height + view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        messageInputBottomConstraint.constant = 0

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        let isMe = message.userId == AuthService.shared.currentUserId
        let senderName = userNames[message.userId] ?? "Unknown"

        cell.configure(with: message, senderName: senderName, isMe: isMe)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1) // Reverse cell
        return cell
    }
}

// MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - MessageCell

class MessageCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let senderLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(senderLabel)
        bubbleView.addSubview(messageLabel)

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        bubbleView.layer.cornerRadius = 18

        senderLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        senderLabel.textColor = .secondaryLabel

        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.numberOfLines = 0
    }

    func configure(with message: Message, senderName: String, isMe: Bool) {
        messageLabel.text = message.content
        senderLabel.text = isMe ? "" : senderName
        senderLabel.isHidden = isMe

        if isMe {
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            configureMeConstraints()
        } else {
            bubbleView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            configureOtherConstraints()
        }
    }

    private func configureMeConstraints() {
        NSLayoutConstraint.deactivate(bubbleView.constraints)
        NSLayoutConstraint.deactivate(senderLabel.constraints)
        NSLayoutConstraint.deactivate(messageLabel.constraints)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }

    private func configureOtherConstraints() {
        NSLayoutConstraint.deactivate(bubbleView.constraints)
        NSLayoutConstraint.deactivate(senderLabel.constraints)
        NSLayoutConstraint.deactivate(messageLabel.constraints)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),

            senderLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 6),
            senderLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            senderLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),

            messageLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 2),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }
}
