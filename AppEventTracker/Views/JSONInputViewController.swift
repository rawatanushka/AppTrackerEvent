//
//  JSONInputViewController.swift
//  AppEventTracker
//
//  Created by Anushka Rawat on 10/09/26.
//

import UIKit

/// Sheet used to feed the tracker a JSON batch of events.
final class JSONInputViewController: UIViewController {
    private var onSubmit: ((String) -> Void)?

    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var submitButton: UIButton!

    init?(coder: NSCoder, onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = AppStrings.Navigation.reportEventsTitle
        navigationController?.navigationBar.tintColor = Theme.Color.textPrimary

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSheet)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AppStrings.Common.sample,
            style: .plain,
            target: self,
            action: #selector(loadSample)
        )

        if hintLabel != nil {
            hintLabel.text = AppStrings.JSONInput.hintText
            hintLabel.font = Theme.Font.caption
            hintLabel.textColor = Theme.Color.textSecondary

            textView.text = SamplePayload.batch
            textView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            textView.textColor = Theme.Color.textPrimary
            textView.backgroundColor = Theme.Color.surface
            textView.layer.cornerRadius = Theme.Metrics.cornerRadius
            textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)

            var configuration = UIButton.Configuration.filled()
            configuration.title = AppStrings.JSONInput.submitButtonTitle
            configuration.baseBackgroundColor = Theme.Color.accent
            configuration.cornerStyle = .large
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
            submitButton.configuration = configuration
        }
    }

    /// Dismisses the input sheet without submitting.
    @IBAction @objc private func dismissSheet(_ sender: Any? = nil) {
        dismiss(animated: true)
    }

    /// Replaces the text view content with the built-in sample payload.
    @IBAction @objc private func loadSample(_ sender: Any? = nil) {
        textView?.text = SamplePayload.batch
    }

    /// Validates the JSON, hands it to the submission closure, and dismisses the sheet.
    ///
    /// If the JSON is invalid, a toast is shown and the sheet remains open.
    @IBAction @objc private func submit(_ sender: Any? = nil) {
        let json = textView?.text ?? ""

        // Validate here so a bad payload keeps the sheet open with the text intact.
        do {
            _ = try EventJSONParser.parse(json)
        } catch {
            showToast(error.localizedDescription, duration: 3)
            return
        }

        onSubmit?(json)
        dismiss(animated: true)
    }
}
