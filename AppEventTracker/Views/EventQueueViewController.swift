//
//  EventQueueViewController.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Screen 1 — the live processing queue.
final class EventQueueViewController: UIViewController {
    var viewModel: EventQueueViewModel!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var refreshButton: UIButton!
    @IBOutlet private weak var tabs: SegmentedTabsView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private let sessionLabel = UILabel()
    private var rows: [EventRowViewModel] = []
    /// Refreshes the "Retrying in Ns" labels once a second while a countdown is visible.
    private var ticker: Timer?

    init?(coder: NSCoder, viewModel: EventQueueViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(viewModel: EventQueueViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        ticker?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpViews()
        bind()
        viewModel?.start()
    }

    // MARK: - Setup

    /// Configures the navigation bar title, appearance, and right bar button items.
    private func setUpNavigationBar() {
        navigationItem.title = nil
        navigationItem.titleView = nil
        navigationItem.largeTitleDisplayMode = .never

        let titleLabel = UILabel()
        titleLabel.text = AppStrings.Navigation.title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.Color.textPrimary

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.Color.background
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        appearance.titleTextAttributes = [
            .foregroundColor: Theme.Color.textPrimary,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.Color.textPrimary

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: AppResources.ImageName.addPlus),
                style: .plain,
                target: self,
                action: #selector(presentInput)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: AppResources.ImageName.menuEllipsis),
                menu: makeMenu()
            )
        ]
    }

    /// Styles the main view, configures the table view, and wires the tab control.
    private func setUpViews() {
        view.backgroundColor = Theme.Color.background

        if titleLabel != nil {
            titleLabel.text = AppStrings.EventQueue.screenTitle
            titleLabel.font = Theme.Font.screenTitle
            titleLabel.textColor = Theme.Color.textPrimary

            refreshButton.setImage(UIImage(systemName: AppResources.ImageName.refreshClockwise), for: .normal)
            refreshButton.tintColor = Theme.Color.textPrimary

            tabs.onSelect = { [weak self] filter in
                self?.viewModel.select(filter: filter)
            }

            tableView.backgroundColor = .clear
            tableView.separatorStyle = .none
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 74
            tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
            tableView.register(
                UINib(nibName: AppResources.Nib.eventCardCell, bundle: nil),
                forCellReuseIdentifier: AppResources.ReuseIdentifier.eventCardCell
            )

            emptyLabel.text = AppStrings.EventQueue.emptyQueue
            emptyLabel.font = Theme.Font.caption
            emptyLabel.textColor = Theme.Color.textSecondary
            emptyLabel.textAlignment = .center
        }
    }

    /// Builds the overflow menu: quick-add submenu, new session, and clear all.
    ///
    /// - Returns: A `UIMenu` ready to be attached to a bar button item.
    private func makeMenu() -> UIMenu {
        let quickAdd = UIMenu(
            title: AppStrings.EventQueue.reportSingleEventMenu,
            children: EventType.allCases.map { type in
                UIAction(title: type.displayName) { [weak self] _ in
                    self?.viewModel.quickAdd(type)
                }
            }
        )

        return UIMenu(children: [
            quickAdd,
            UIAction(
                title: AppStrings.EventQueue.startNewSessionAction,
                image: UIImage(systemName: AppResources.ImageName.newSessionArrow)
            ) { [weak self] _ in
                self?.viewModel.startNewSession()
            },
            UIAction(
                title: AppStrings.EventQueue.clearAllDataAction,
                image: UIImage(systemName: AppResources.ImageName.trash),
                attributes: .destructive
            ) { [weak self] _ in
                self?.confirmClear()
            }
        ])
    }

    // MARK: - Binding

    /// Wires the view model's output closures to the corresponding UI updates.
    private func bind() {
        guard let viewModel else { return }
        viewModel.onRowsChanged = { [weak self] rows in
            guard let self else { return }
            self.rows = rows
            self.tableView?.reloadData()
            self.emptyLabel?.isHidden = !rows.isEmpty
        }

        viewModel.onInProgressCountChanged = { [weak self] count in
            self?.tabs?.setCount(count, for: .inProgress)
        }

        viewModel.onFailedCountChanged = { [weak self] count in
            self?.tabs?.setCount(count, for: .failed)
        }

        viewModel.onSessionTextChanged = { [weak self] text in
            self?.sessionLabel.text = text
        }

        viewModel.onNeedsTickerChanged = { [weak self] needed in
            self?.setTicker(enabled: needed)
        }

        viewModel.onMessage = { [weak self] message in
            self?.showToast(message)
        }
    }

    /// Starts or stops the one-second ticker timer that refreshes countdown labels.
    ///
    /// - Parameter enabled: `true` to start the ticker; `false` to stop it.
    private func setTicker(enabled: Bool) {
        guard enabled else {
            ticker?.invalidate()
            ticker = nil
            return
        }
        guard ticker == nil else { return }

        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.viewModel?.tick()
        }
    }

    // MARK: - Actions

    /// Triggers a manual data refresh and plays haptic feedback.
    @IBAction private func refreshTapped(_ sender: Any? = nil) {
        viewModel?.tick()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Presents the JSON input sheet for adding events to the queue.
    @IBAction private func presentInput(_ sender: Any? = nil) {
        let storyboard = UIStoryboard(name: AppResources.Storyboard.main, bundle: nil)
        let input: JSONInputViewController = storyboard.instantiateViewController(identifier: AppResources.ViewController.jsonInput, creator: { coder in
            JSONInputViewController(coder: coder, onSubmit: { [weak self] json in
                self?.viewModel?.submit(json: json)
            })
        })

        let navigation = UINavigationController(rootViewController: input)
        navigation.modalPresentationStyle = .pageSheet
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(navigation, animated: true)
    }

    /// Presents a destructive confirmation alert before clearing all data.
    private func confirmClear() {
        let alert = UIAlertController(
            title: AppStrings.EventQueue.clearAllAlertTitle,
            message: AppStrings.EventQueue.clearAllAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: AppStrings.Common.clear, style: .destructive) { [weak self] _ in
            self?.viewModel?.clearAll()
        })
        present(alert, animated: true)
    }
}

// MARK: - Table view

extension EventQueueViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: EventCardCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? EventCardCell)?.configure(with: rows[indexPath.row])
        return cell
    }
}
