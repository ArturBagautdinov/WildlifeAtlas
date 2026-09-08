//
//  ObservationDetailViewController.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationDetailViewController: UIViewController {
    private let viewModel: ObservationDetailViewModel
    private let imageLoader: ImageLoader

    private let scrollView = UIScrollView()
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 22
        return stackView
    }()

    private let photoGalleryView = ObservationPhotoGalleryView()

    private let commonNameLabel = ObservationDetailTextLabel(
        font: .preferredFont(forTextStyle: .largeTitle),
        color: .label,
        lines: 0
    )

    private let scientificNameLabel = ObservationDetailTextLabel(
        font: .italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize),
        color: .secondaryLabel,
        lines: 0
    )

    private let qualityBadgeView = ObservationDetailQualityBadgeView()
    private let taxonInfoView = ObservationDetailTaxonInfoView()
    private let stateView = ObservationDetailStateView()
    private var currentContent: ObservationDetailContent?
    private var heroImageHeightConstraint: NSLayoutConstraint?
    private var qualityBadgeWidthConstraint: NSLayoutConstraint?

    init(viewModel: ObservationDetailViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:imageLoader:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureHierarchy()
        bindViewModel()
        render(state: viewModel.state)
        viewModel.loadObservation()
    }

    private func configureView() {
        title = "Observation"
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        navigationController?.navigationBar.tintColor = .wildlifePrimaryText
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .wildlifePrimaryText
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Share observation"
        navigationItem.rightBarButtonItem?.isHidden = true
    }

    private func configureHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(stateView)
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 28),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -28),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),

            stateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        stateView.onRetry = { [weak self] in
            self?.viewModel.retry()
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
    }

    private func render(state: ObservationDetailViewModel.State) {
        switch state {
        case .loading:
            currentContent = nil
            navigationItem.rightBarButtonItem?.isHidden = true
            scrollView.isHidden = true
            stateView.configureLoading()
        case .content(let content):
            currentContent = content
            navigationItem.rightBarButtonItem?.isHidden = content.canShare == false
            stateView.isHidden = true
            scrollView.isHidden = false
            render(content: content)
        case .notFound:
            currentContent = nil
            navigationItem.rightBarButtonItem?.isHidden = true
            scrollView.isHidden = true
            stateView.configureMessage(
                title: "Observation not found",
                message: "This observation is unavailable.",
                showsRetry: false
            )
        case .error(let error):
            currentContent = nil
            navigationItem.rightBarButtonItem?.isHidden = true
            scrollView.isHidden = true
            stateView.configureMessage(title: error.title, message: error.message, showsRetry: true)
        }
    }

    private func render(content: ObservationDetailContent) {
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if content.photos.isEmpty == false {
            contentStackView.addArrangedSubview(photoGalleryView)
            photoGalleryView.configure(photos: content.photos, imageLoader: imageLoader)
            if heroImageHeightConstraint == nil {
                heroImageHeightConstraint = photoGalleryView.heightAnchor.constraint(equalTo: photoGalleryView.widthAnchor, multiplier: 0.76)
                heroImageHeightConstraint?.isActive = true
            }
        } else {
            photoGalleryView.configure(photos: [], imageLoader: imageLoader)
        }

        if let identityView = makeIdentityView(content: content) {
            contentStackView.addArrangedSubview(identityView)
        }

        taxonInfoView.configure(rows: content.taxonRows)
        if content.taxonRows.isEmpty == false {
            contentStackView.addArrangedSubview(taxonInfoView)
        }

        addInfoRow(systemImageName: "calendar", title: "Observed on", value: content.observedDate)
        addInfoRow(systemImageName: "mappin.and.ellipse", title: "Location", value: content.locationName)
        addInfoRow(systemImageName: "person.crop.circle", title: "Photographed by", value: content.authorName)
        addInfoRow(systemImageName: "text.quote", title: "Photo attribution", value: content.photoAttribution)
        addInfoRow(systemImageName: "doc.text", title: "Photo license", value: content.photoLicense)

        view.accessibilityLabel = content.accessibilityLabel
    }

    private func makeIdentityView(content: ObservationDetailContent) -> UIStackView? {
        commonNameLabel.setDetailText(content.commonName)
        scientificNameLabel.setDetailText(content.scientificName)
        qualityBadgeView.configure(symbol: content.qualitySymbol, text: content.qualityText)

        let visibleNameLabels = [commonNameLabel, scientificNameLabel].filter { $0.isHidden == false }
        let namesStackView = UIStackView(arrangedSubviews: visibleNameLabels)
        namesStackView.axis = .vertical
        namesStackView.spacing = 6

        var arrangedSubviews: [UIView] = []
        if visibleNameLabels.isEmpty == false {
            arrangedSubviews.append(namesStackView)
        }
        if qualityBadgeView.isHidden == false {
            arrangedSubviews.append(qualityBadgeView)
        }

        guard arrangedSubviews.isEmpty == false else {
            return nil
        }

        let rowStackView = UIStackView(arrangedSubviews: arrangedSubviews)
        rowStackView.axis = .vertical
        rowStackView.alignment = .leading
        rowStackView.spacing = 12

        if qualityBadgeView.isHidden == false {
            if qualityBadgeWidthConstraint == nil {
                qualityBadgeWidthConstraint = qualityBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 128)
                qualityBadgeWidthConstraint?.isActive = true
            }
        }

        rowStackView.isAccessibilityElement = true
        rowStackView.accessibilityLabel = [
            content.commonName,
            content.scientificName,
            content.qualityText
        ].compactMap { $0 }.joined(separator: ", ")
        return rowStackView
    }

    private func addInfoRow(systemImageName: String, title: String, value: String?) {
        guard let value else { return }
        contentStackView.addArrangedSubview(
            ObservationDetailInfoRowView(systemImageName: systemImageName, title: title, value: value)
        )
    }

    @objc private func shareTapped() {
        guard let content = currentContent else { return }

        var items: [Any] = []
        if let shareText = content.shareText {
            items.append(shareText)
        }
        if let shareURL = content.shareURL {
            items.append(shareURL)
        }

        guard items.isEmpty == false else { return }

        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true)
    }
}
