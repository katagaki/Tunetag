//
//  BrowserGridItem.swift
//  Tunetag
//

import AppKit

/// A file's icon with its name beneath, highlighted the way Finder's icon view does.
final class BrowserGridItem: NSCollectionViewItem {

    static let identifier = NSUserInterfaceItemIdentifier("BrowserGridItem")

    private let iconBackground = NSView()
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(wrappingLabelWithString: "")

    override var isSelected: Bool {
        didSet { updateHighlight() }
    }

    override func loadView() {
        let container = NSView()
        iconBackground.wantsLayer = true
        iconBackground.layer?.cornerRadius = 8
        iconView.imageScaling = .scaleProportionallyUpOrDown
        nameLabel.alignment = .center
        nameLabel.maximumNumberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        nameLabel.wantsLayer = true
        nameLabel.layer?.cornerRadius = 4
        for subview in [iconBackground, iconView, nameLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            iconBackground.topAnchor.constraint(equalTo: container.topAnchor),
            iconBackground.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 72),
            iconBackground.heightAnchor.constraint(equalToConstant: 72),
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
            nameLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 4),
            nameLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLabel.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        view = container
        imageView = iconView
        textField = nameLabel
    }

    func configure(with file: FSFile) {
        iconView.image = NSWorkspace.shared.icon(forFile: file.path)
        nameLabel.stringValue = file.name
        nameLabel.toolTip = nameLabel.stringValue
        updateHighlight()
    }

    private func updateHighlight() {
        iconBackground.layer?.backgroundColor = isSelected
            ? NSColor.quaternaryLabelColor.cgColor
            : NSColor.clear.cgColor
        nameLabel.layer?.backgroundColor = isSelected
            ? NSColor.selectedContentBackgroundColor.cgColor
            : NSColor.clear.cgColor
        nameLabel.textColor = isSelected ? .alternateSelectedControlTextColor : .labelColor
    }
}
