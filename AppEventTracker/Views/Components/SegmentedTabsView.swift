//
//  SegmentedTabsView.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Underline-style filter control matching the mock: IN PROGRESS | FAILED / RETRYING.
final class SegmentedTabsView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var stack: UIStackView!
    @IBOutlet private weak var button1: UIButton!
    @IBOutlet private weak var button2: UIButton!
    @IBOutlet private weak var trackLine: UIView!
    @IBOutlet private weak var indicator: UIView!

    /// Closure fired when the user taps a different filter tab.
    var onSelect: ((EventQueueViewModel.Filter) -> Void)?

    private var indicatorLeading: NSLayoutConstraint?
    private var indicatorWidth: NSLayoutConstraint?
    private var selected: EventQueueViewModel.Filter = .inProgress

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNib()
    }

    /// Loads the companion XIB and sets up the UI.
    private func loadNib() {
        guard contentView == nil else { return }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: AppResources.Nib.segmentedTabsView, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        setupUI()
    }

    /// Configures button titles, fonts, and wires tap actions.
    private func setupUI() {
        trackLine?.backgroundColor = Theme.Color.separator
        indicator?.backgroundColor = Theme.Color.accent
        indicator?.layer.cornerRadius = 1.5

        if let b1 = button1 {
            b1.tag = EventQueueViewModel.Filter.inProgress.rawValue
            b1.setTitle(EventQueueViewModel.Filter.inProgress.title, for: .normal)
            b1.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            b1.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        }

        if let b2 = button2 {
            b2.tag = EventQueueViewModel.Filter.failed.rawValue
            b2.setTitle(EventQueueViewModel.Filter.failed.title, for: .normal)
            b2.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            b2.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
        }

        refresh()
    }

    /// Programmatically selects the given filter and refreshes the visual state.
    ///
    /// - Parameter filter: The filter to activate.
    func select(_ filter: EventQueueViewModel.Filter) {
        selected = filter
        refresh()
    }

    /// Handles a tap on one of the filter buttons.
    @objc private func handleTap(_ sender: UIButton) {
        guard let filter = EventQueueViewModel.Filter(rawValue: sender.tag) else { return }
        select(filter)
        onSelect?(filter)
    }

    /// Refreshes button colors and animates the underline indicator to the selected tab.
    private func refresh() {
        let buttons = [button1, button2].compactMap { $0 }
        for button in buttons {
            guard let filter = EventQueueViewModel.Filter(rawValue: button.tag) else { continue }
            let isActive = filter == selected
            button.setTitleColor(isActive ? Theme.Color.accent : Theme.Color.textSecondary, for: .normal)
        }

        guard !buttons.isEmpty, let indicator = indicator else { return }
        let selectedButton = buttons[selected.rawValue < buttons.count ? selected.rawValue : 0]

        indicatorLeading?.isActive = false
        indicatorWidth?.isActive = false
        indicatorLeading = indicator.leadingAnchor.constraint(equalTo: selectedButton.leadingAnchor)
        indicatorWidth = indicator.widthAnchor.constraint(equalTo: selectedButton.widthAnchor)
        indicatorLeading?.isActive = true
        indicatorWidth?.isActive = true

        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }
}

