//
//  BreakdownRowView.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// A single "● Event | Count | Percentage" row matching the mock breakdown table.
final class BreakdownRowView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var dot: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!
    @IBOutlet private weak var percentageLabel: UILabel!
    @IBOutlet private weak var separator: UIView!

    init(type: EventType) {
        super.init(frame: .zero)
        loadNib()
        setType(type)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNib()
        setType(.install)
    }

    /// Loads the companion XIB and pins it edge-to-edge as a subview.
    private func loadNib() {
        guard contentView == nil else { return }
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: AppResources.Nib.breakdownRowView, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false

        dot?.layer.cornerRadius = 4
        separator?.backgroundColor = Theme.Color.separator

        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// Configures the dot color and name label for the given event type.
    ///
    /// - Parameter type: The event type this row represents.
    func setType(_ type: EventType) {
        let accent = Theme.Color.forEventType(type)
        dot?.backgroundColor = accent
        nameLabel?.text = type.displayName
        nameLabel?.font = Theme.Font.robotoMono(size: 13, weight: .regular)
        nameLabel?.textColor = Theme.Color.textPrimary
    }

    /// Updates the count and percentage labels from a `StatisticsViewModel.BreakdownRow`.
    ///
    /// - Parameter row: The breakdown data to display.
    func configure(with row: StatisticsViewModel.BreakdownRow) {
        countLabel?.text = row.countText
        countLabel?.font = Theme.Font.robotoMono(size: 13, weight: .regular)
        countLabel?.textColor = Theme.Color.textPrimary

        percentageLabel?.text = row.percentageText
        percentageLabel?.font = Theme.Font.robotoMono(size: 13, weight: .regular)
        percentageLabel?.textColor = Theme.Color.textSecondary
    }
}
