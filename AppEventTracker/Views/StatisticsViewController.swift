//
//  StatisticsViewController.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Screen 2 — totals, per type counts, breakdown table and the processed event log.
final class StatisticsViewController: UIViewController {
    var viewModel: StatisticsViewModel!

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var contentStack: UIStackView!

    @IBOutlet private weak var processedCard: MetricCardView!
    @IBOutlet private weak var visitsCard: MetricCardView!

    @IBOutlet private weak var installTile: EventCountTileView!
    @IBOutlet private weak var visitTile: EventCountTileView!
    @IBOutlet private weak var addToCartTile: EventCountTileView!
    @IBOutlet private weak var purchaseTile: EventCountTileView!

    @IBOutlet private weak var breakdownContainer: UIView!
    @IBOutlet private weak var installRow: BreakdownRowView!
    @IBOutlet private weak var visitRow: BreakdownRowView!
    @IBOutlet private weak var addToCartRow: BreakdownRowView!
    @IBOutlet private weak var purchaseRow: BreakdownRowView!

    @IBOutlet private weak var processedLogContainer: UIView?
    @IBOutlet private weak var processedListStack: UIStackView?
    @IBOutlet private weak var processedEmptyLabel: UILabel?

    private var tiles: [EventType: EventCountTileView] = [:]
    private var breakdownRows: [EventType: BreakdownRowView] = [:]

    init?(coder: NSCoder, viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpViews()
        bind()
        viewModel?.start()
    }

    // MARK: - Setup

    /// Configures the navigation bar with a left-aligned title and transparent appearance.
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
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = Theme.Color.textPrimary
    }

    /// Applies theming to all static views: metric cards, tiles, and breakdown container.
    private func setUpViews() {
        view.backgroundColor = Theme.Color.background

        processedCard?.configure(
            caption: AppStrings.Statistics.totalEventsProcessed,
            accent: Theme.Color.forEventType(.visit),
            valueFont: Theme.Font.metric
        )
        visitsCard?.configure(
            caption: AppStrings.Statistics.totalVisits,
            subcaption: AppStrings.Statistics.uniqueSessionSubcaption,
            accent: Theme.Color.forEventType(.visit),
            valueFont: Theme.Font.robotoMono(size: 24, weight: .bold)
        )

        if let breakdownContainer {
            breakdownContainer.backgroundColor = Theme.Color.surface
            breakdownContainer.layer.cornerRadius = Theme.Metrics.cornerRadius
            breakdownContainer.layer.borderWidth = 1
            breakdownContainer.layer.borderColor = Theme.Color.separator.cgColor
        }

        if let processedLogContainer {
            processedLogContainer.backgroundColor = Theme.Color.surface
            processedLogContainer.layer.cornerRadius = Theme.Metrics.cornerRadius
            processedLogContainer.layer.borderWidth = 1
            processedLogContainer.layer.borderColor = Theme.Color.separator.cgColor
        }

        if installTile != nil {
            installTile.setType(.install)
            visitTile.setType(.visit)
            addToCartTile.setType(.addToCart)
            purchaseTile.setType(.purchase)

            tiles[.install] = installTile
            tiles[.visit] = visitTile
            tiles[.addToCart] = addToCartTile
            tiles[.purchase] = purchaseTile

            installRow.setType(.install)
            visitRow.setType(.visit)
            addToCartRow.setType(.addToCart)
            purchaseRow.setType(.purchase)

            breakdownRows[.install] = installRow
            breakdownRows[.visit] = visitRow
            breakdownRows[.addToCart] = addToCartRow
            breakdownRows[.purchase] = purchaseRow
        }
    }

    // MARK: - Binding

    /// Wires the view model's output closures to the corresponding UI updates.
    private func bind() {
        guard let viewModel else { return }
        viewModel.onTotalProcessedChanged = { [weak self] text in
            self?.processedCard?.setValue(text)
        }

        viewModel.onTotalVisitsChanged = { [weak self] text in
            self?.visitsCard?.setValue(text)
        }

        viewModel.onTypeCountsChanged = { [weak self] counts in
            counts.forEach { self?.tiles[$0.type]?.setValue($0.count) }
        }

        viewModel.onBreakdownChanged = { [weak self] rows in
            rows.forEach { self?.breakdownRows[$0.type]?.configure(with: $0) }
        }

        viewModel.onProcessedEventsChanged = { [weak self] events in
            self?.renderProcessedList(events)
        }

        viewModel.onEmptyChanged = { [weak self] isEmpty in
            self?.processedEmptyLabel?.isHidden = !isEmpty
        }
    }

    /// Shows the most recent deliveries; the full history lives in the queue tab.
    private func renderProcessedList(_ events: [EventRowViewModel]) {
        guard let processedListStack else { return }
        processedListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for event in events.prefix(20) {
            processedListStack.addArrangedSubview(makeProcessedRow(event))
        }
    }

    /// Builds a row view for a single processed event in the delivery log.
    ///
    /// - Parameter model: The event row view model to display.
    /// - Returns: A horizontal `UIStackView` containing a dot, name, and time.
    private func makeProcessedRow(_ model: EventRowViewModel) -> UIView {
        let dot = UIView()
        dot.backgroundColor = model.accentColor
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

        let name = UILabel()
        name.text = model.title
        name.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        name.textColor = Theme.Color.textPrimary

        let time = UILabel()
        time.text = model.timeText
        time.font = Theme.Font.monospacedCaption
        time.textColor = Theme.Color.textSecondary
        time.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [dot, name, time])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        return row
    }
}
