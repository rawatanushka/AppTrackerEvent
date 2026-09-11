//
//  EventCountTileView.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Per event type tile: colored dot + label + big number, matching the 2×2 grid in the mock.
final class EventCountTileView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var dot: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!

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
        backgroundColor = .clear
        clipsToBounds = true

        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: AppResources.Nib.eventCountTileView, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.backgroundColor = Theme.Color.surface
        view.layer.cornerRadius = Theme.Metrics.cornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.Color.separator.cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        dot?.layer.cornerRadius = dot.bounds.height / 2
        dot?.clipsToBounds = true

        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// Configures the dot color, label, and font for the given event type.
    ///
    /// - Parameter type: The event type this tile represents.
    func setType(_ type: EventType) {
        let accent = Theme.Color.forEventType(type)
        dot?.backgroundColor = Theme.Color.dotBackgroundForEventType(type)
        nameLabel?.font = Theme.Font.robotoMono(size: 12, weight: .regular)
        nameLabel?.textColor = Theme.Color.textSecondary
        nameLabel?.text = type.displayName
        valueLabel?.font = Theme.Font.metricSmall
        valueLabel?.textColor = accent
    }

    /// Updates the numeric value label.
    ///
    /// - Parameter text: The formatted count string to display.
    func setValue(_ text: String) {
        valueLabel?.text = text
    }
}
