//
//  BrowserViewController+Grid.swift
//  Tunetag
//

import AppKit

extension BrowserViewController: NSCollectionViewDataSource, NSCollectionViewDelegate {

    func configureGrid() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 112, height: 116)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        collectionView.collectionViewLayout = layout
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.allowsEmptySelection = true
        collectionView.backgroundColors = [.clear]
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BrowserGridItem.self, forItemWithIdentifier: BrowserGridItem.identifier)
        collectionView.menu = makeContextMenu()
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        files.count
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: BrowserGridItem.identifier, for: indexPath)
        if let gridItem = item as? BrowserGridItem {
            gridItem.configure(with: files[indexPath.item])
        }
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        gridSelectionDidChange()
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        gridSelectionDidChange()
    }

    private func gridSelectionDidChange() {
        updateSelection(IndexSet(collectionView.selectionIndexPaths.map(\.item)))
    }
}
