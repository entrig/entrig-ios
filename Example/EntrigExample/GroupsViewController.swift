import UIKit
import Entrig

/// Groups list screen (matching Flutter HomeScreen exactly)
class GroupsViewController: UIViewController {

    // MARK: - Properties

    private var groups: [Group] = []
    private var joinedGroupIds: Set<String> = []
    private var userName: String?
    private var isLoading = true

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotificationListeners()
        loadUserAndGroups()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Groups"

        // Setup table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GroupCell.self, forCellReuseIdentifier: "GroupCell")
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshGroups), for: .valueChanged)

        // Setup activity indicator
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Add create group button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createGroupTapped)
        )

        // Add sign out button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .systemRed
    }

    private func setupNotificationListeners() {
        Entrig.setOnForegroundNotificationListener(self)
        Entrig.setOnNotificationOpenedListener(self)

        // Check for initial notification
        if let notification = Entrig.getInitialNotification() {
            handleNotification(notification)
        }
    }

    // MARK: - Data Loading

    private func loadUserAndGroups() {
        isLoading = true
        activityIndicator.startAnimating()

        Task {
            do {
                // Load current user
                if let userId = AuthService.shared.currentUserId {
                    let user = try await SupabaseService.shared.getUser(id: userId)
                    await MainActor.run {
                        userName = user.name
                        title = "Hi, \(user.name)!"
                    }
                }

                // Load groups
                try await loadGroups()

                await MainActor.run {
                    isLoading = false
                    activityIndicator.stopAnimating()
                    tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    activityIndicator.stopAnimating()
                    showAlert(message: "Error loading data: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadGroups() async throws {
        guard let userId = AuthService.shared.currentUserId else { return }

        // Load all groups
        let allGroups = try await SupabaseService.shared.getAllGroups()

        // Load joined group IDs
        let joinedIds = try await SupabaseService.shared.getJoinedGroupIds(userId: userId)

        await MainActor.run {
            groups = allGroups
            joinedGroupIds = joinedIds
        }
    }

    @objc private func refreshGroups() {
        Task {
            do {
                try await loadGroups()
                await MainActor.run {
                    refreshControl.endRefreshing()
                    tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    refreshControl.endRefreshing()
                    showAlert(message: "Error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func signOutTapped() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.performSignOut()
        })

        present(alert, animated: true)
    }

    private func performSignOut() {
        Task {
            do {
                // Unregister from Entrig before signing out
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    Entrig.unregister { success, error in
                        if success {
                            print("[GroupsVC] ✅ Unregistered from Entrig")
                        } else {
                            print("[GroupsVC] ⚠️ Entrig unregistration failed: \(error ?? "Unknown error")")
                        }
                        continuation.resume()
                    }
                }

                try await AuthService.shared.signOut()

                await MainActor.run {
                    // Navigate back to auth screen
                    if let window = view.window {
                        let authVC = AuthViewController()
                        let navController = UINavigationController(rootViewController: authVC)
                        window.rootViewController = navController
                        window.makeKeyAndVisible()
                    }
                }
            } catch {
                await MainActor.run {
                    showAlert(message: "Sign out failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func createGroupTapped() {
        let alert = UIAlertController(title: "Create Group", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Group Name"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            self?.createGroup(name: name)
        })

        present(alert, animated: true)
    }

    private func createGroup(name: String) {
        guard let userId = AuthService.shared.currentUserId else { return }

        Task {
            do {
                // Create group
                let group = try await SupabaseService.shared.createGroup(name: name, createdBy: userId)

                // Add creator as member
                try await SupabaseService.shared.joinGroup(groupId: group.id, userId: userId)

                // Reload groups
                try await loadGroups()

                await MainActor.run {
                    tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    showAlert(message: "Error creating group: \(error.localizedDescription)")
                }
            }
        }
    }

    private func joinGroup(_ group: Group) {
        guard let userId = AuthService.shared.currentUserId else { return }

        let isJoined = joinedGroupIds.contains(group.id)

        if !isJoined {
            // Show join confirmation
            let alert = UIAlertController(
                title: "Join Group",
                message: "Do you want to join \"\(group.name)\"?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Join", style: .default) { [weak self] _ in
                self?.performJoinGroup(group, userId: userId)
            })

            present(alert, animated: true)
        } else {
            // Already joined, navigate to chat
            navigateToChat(group: group)
        }
    }

    private func performJoinGroup(_ group: Group, userId: String) {
        Task {
            do {
                try await SupabaseService.shared.joinGroup(groupId: group.id, userId: userId)

                await MainActor.run {
                    joinedGroupIds.insert(group.id)
                    tableView.reloadData()
                    navigateToChat(group: group)
                }
            } catch {
                await MainActor.run {
                    showAlert(message: "Error joining group: \(error.localizedDescription)")
                }
            }
        }
    }

    private func navigateToChat(group: Group) {
        let chatVC = ChatViewController(groupId: group.id, groupName: group.name)
        navigationController?.pushViewController(chatVC, animated: true)
    }

    // MARK: - Notification Handling

    private func handleNotification(_ notification: NotificationEvent) {
        print("[Groups] Notification: \(notification.title)")

        guard let type = notification.type else { return }

        switch type {
        case "new_member":
            handleNewMemberNotification(notification)
        case "new_message":
            handleNewMessageNotification(notification)
        case "new_group":
            handleNewGroupNotification(notification)
        default:
            break
        }
    }

    private func handleNewMemberNotification(_ notification: NotificationEvent) {
        guard let groupData = notification.data["groups"] as? [String: Any],
              let groupId = groupData["id"] as? String,
              let groupName = groupData["name"] as? String,
              let userData = notification.data["users"] as? [String: Any],
              let userName = userData["name"] as? String else { return }

        let alert = UIAlertController(
            title: "New Member Joined",
            message: "\(userName) joined \"\(groupName)\"!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        alert.addAction(UIAlertAction(title: "View Group", style: .default) { [weak self] _ in
            let group = Group(id: groupId, createdAt: nil, name: groupName, createdBy: "")
            self?.navigateToChat(group: group)
        })

        present(alert, animated: true)
    }

    private func handleNewMessageNotification(_ notification: NotificationEvent) {
        guard let groupData = notification.data["groups"] as? [String: Any],
              let groupId = groupData["id"] as? String,
              let groupName = groupData["name"] as? String else { return }

        let group = Group(id: groupId, createdAt: nil, name: groupName, createdBy: "")
        navigateToChat(group: group)
    }

    private func handleNewGroupNotification(_ notification: NotificationEvent) {
        guard let groupId = notification.data["id"] as? String,
              let groupName = notification.data["name"] as? String else { return }

        let alert = UIAlertController(
            title: "New Group Created",
            message: "A new group \"\(groupName)\" has been created!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        alert.addAction(UIAlertAction(title: "View", style: .default) { [weak self] _ in
            let group = Group(id: groupId, createdAt: nil, name: groupName, createdBy: "")
            self?.navigateToChat(group: group)
        })

        present(alert, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension GroupsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 0
        } else if groups.isEmpty {
            return 0 // Will show empty state
        } else {
            return groups.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath) as! GroupCell
        let group = groups[indexPath.row]
        let isJoined = joinedGroupIds.contains(group.id)
        let isOwner = group.createdBy == AuthService.shared.currentUserId

        cell.configure(with: group, isJoined: isJoined, isOwner: isOwner)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = groups[indexPath.row]
        joinGroup(group)
    }
}

// MARK: - OnNotificationReceivedListener

extension GroupsViewController: OnNotificationReceivedListener {
    func onNotificationReceived(_ notification: NotificationEvent) {
        print("[Groups] Foreground notification: \(notification.title)")
        // Refresh groups list
        refreshGroups()
    }
}

// MARK: - OnNotificationClickListener

extension GroupsViewController: OnNotificationClickListener {
    func onNotificationClick(_ notification: NotificationEvent) {
        print("[Groups] Notification clicked: \(notification.title)")
        handleNotification(notification)
    }
}

// MARK: - GroupCell

class GroupCell: UITableViewCell {
    private let iconLabel = UILabel()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        iconLabel.font = .systemFont(ofSize: 20, weight: .bold)
        iconLabel.textAlignment = .center
        iconLabel.textColor = .white
        iconLabel.layer.cornerRadius = 20
        iconLabel.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .systemGreen

        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = .systemGray3
        arrowImageView.contentMode = .scaleAspectFit

        [iconLabel, nameLabel, statusLabel, arrowImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 40),
            iconLabel.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(with group: Group, isJoined: Bool, isOwner: Bool) {
        let firstLetter = String(group.name.prefix(1).uppercased())
        iconLabel.text = firstLetter
        iconLabel.backgroundColor = isJoined ? .systemBlue : .systemGray

        nameLabel.text = group.name

        if isJoined {
            statusLabel.text = isOwner ? "Owner" : "Joined"
            statusLabel.isHidden = false
            arrowImageView.image = UIImage(systemName: "chevron.right")
        } else {
            statusLabel.isHidden = true
            arrowImageView.image = UIImage(systemName: "arrow.right.circle")
        }
    }
}
