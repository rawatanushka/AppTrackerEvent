//
//  EventCardCell.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// One event card matching the mock: colored dot, event name, timestamp, plain status text.
final class EventCardCell: UITableViewCell {
    static let reuseIdentifier = AppResources.ReuseIdentifier.eventCardCell

    @IBOutlet private weak var card: UIView!
    @IBOutlet private weak var dot: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheme()
    }

    /// Applies the app's visual theme to all subviews after the nib has loaded.
    private func setupTheme() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        if let card = card {
            card.backgroundColor = Theme.Color.surface
            card.layer.cornerRadius = Theme.Metrics.cornerRadius
            card.layer.borderWidth = 1
            card.layer.borderColor = Theme.Color.separator.cgColor
        }

        if let dot = dot {
            dot.layer.cornerRadius = dot.bounds.height / 2
            dot.clipsToBounds = true
        }

        titleLabel?.font = Theme.Font.cardTitle
        titleLabel?.textColor = Theme.Color.textPrimary

        timeLabel?.textColor = Theme.Color.textSecondary

    }

    /// Populates the cell with data from an `EventRowViewModel`.
    ///
    /// - Parameter model: The view model for the event row.
    func configure(with model: EventRowViewModel) {
        titleLabel?.text = model.title
        timeLabel?.text = model.timeText
        dot?.backgroundColor = model.dotBackgroundColor
        statusLabel?.text = model.statusText
        statusLabel?.textColor = model.statusColor
    }
}

