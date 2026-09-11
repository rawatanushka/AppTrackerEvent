//
//  MetricCardView.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Big headline number with a thin-bordered card, e.g. "Total Events Processed / 128".
final class MetricCardView: UIView {
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var subcaptionLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!

    init(caption: String, subcaption: String? = nil, accent: UIColor = Theme.Color.textPrimary) {
        super.init(frame: .zero)
        loadNib()
        configure(caption: caption, subcaption: subcaption, accent: accent)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNib()
    }

    /// Loads the companion XIB and applies the standard card styling.
    private func loadNib() {
        guard contentView == nil else { return }
        backgroundColor = .clear
        clipsToBounds = true

        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: AppResources.Nib.metricCardView, bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.backgroundColor = Theme.Color.surface
        view.layer.cornerRadius = Theme.Metrics.cornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.Color.separator.cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// Configures the card's caption, subcaption, accent color, and value font.
    ///
    /// - Parameters:
    ///   - caption: Primary label text (e.g. "Total Events Processed").
    ///   - subcaption: Optional secondary label (e.g. "(Unique Session)").
    ///   - accent: The color applied to the value label.
    ///   - valueFont: The font used for the big numeric value.
    func configure(
        caption: String = AppStrings.Components.MetricCard.defaultCaption,
        subcaption: String? = nil,
        accent: UIColor = Theme.Color.textPrimary,
        valueFont: UIFont = Theme.Font.metric
    ) {
        captionLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        captionLabel?.textColor = Theme.Color.textSecondary
        captionLabel?.text = caption

        subcaptionLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subcaptionLabel?.textColor = Theme.Color.muted
        subcaptionLabel?.text = subcaption
        subcaptionLabel?.isHidden = subcaption == nil

        valueLabel?.font = valueFont
        valueLabel?.textColor = accent
    }

    /// Updates the numeric value label.
    ///
    /// - Parameter text: The formatted value string to display.
    func setValue(_ text: String) {
        valueLabel?.text = text
    }
}
