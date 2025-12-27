//
//  File.swift
//
//
//  Created by Guy on 11/11/2021.
//

import UIKit

@MainActor
public class ConfigurableCollectionViewDataSource<SectionIdentifierType, ItemIdentifierType>: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
    public var items = [SectionIdentifierType: [ItemIdentifierType]]() {
        didSet {
            needsTableViewUpdate = true
        }
    }
    public var sections = [SectionIdentifierType]() {
        didSet {
            needsTableViewUpdate = true
        }
    }
    private(set) public var needsTableViewUpdate = false {
        didSet {
            if needsTableViewUpdate {
                NotificationQueue.default.enqueue(Notification(name: updateItemsNotification, object: self, userInfo: nil), postingStyle: .whenIdle, coalesceMask: [.onName, .onSender], forModes: nil)
            }
        }
    }
    
    private var updateItemsNotification = Notification.Name("updateItems")
    
    public override init(collectionView: UICollectionView, cellProvider: @escaping UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider) {
        super.init(collectionView: collectionView, cellProvider: cellProvider)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCollectionViewIfNeeded), name: updateItemsNotification, object: self)
    }
    
    @objc public func updateCollectionViewIfNeeded() {
        guard needsTableViewUpdate else { return }
        defer {
            needsTableViewUpdate = false
        }
        var snap = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        snap.appendSections(sections.filter { items.keys.contains($0) })
        for section in sections {
            if let sectionItems = items[section] {
                snap.appendItems(sectionItems, toSection: section)
            }
        }
        
        apply(snap, animatingDifferences: true)
    }
    
    
    private func section(for index: Int) -> SectionIdentifierType? {
        if #available(iOS 15, *) {
            return sectionIdentifier(for: index)
        } else {
            let allSections = sections.filter { items.keys.contains($0) }
            guard index < allSections.count else {
                return nil
            }
            return allSections[index]
        }
    }
    
    public func itemIdentifier(for indexPath: (section: SectionIdentifierType, item: Int)) -> ItemIdentifierType? {
        let allSections = sections.filter { items.keys.contains($0) }
        if let idx = allSections.firstIndex(of: indexPath.section) {
            return itemIdentifier(for: IndexPath(item: indexPath.item, section: idx))
        }
        return nil
    }
    
    private var canMoveItemBlock: (((section: SectionIdentifierType, item: Int)) -> Bool)?
    public override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if let section = section(for: indexPath.section) {
            return canMoveItemBlock?((section: section, item: indexPath.item)) ?? false
        }
        return false
    }
    public func canMoveItem(_ b: @escaping (_ indexPath: (section: SectionIdentifierType, item: Int)) -> Bool) {
        canMoveItemBlock = b
    }
    
    private var moveItemBlock: (((section: SectionIdentifierType, item: Int), (section: SectionIdentifierType, item: Int)) -> Void)?
    public override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let sourceSection = section(for: sourceIndexPath.section), let destinationSection = section(for: destinationIndexPath.section) {
            moveItemBlock?((section: sourceSection, item: sourceIndexPath.item), (section: destinationSection, item: destinationIndexPath.item))
        }
    }
    public func moveItem(_ b: @escaping (_ sourceIndexPath: (section: SectionIdentifierType, item: Int), _ destinationIndexPath: (section: SectionIdentifierType, item: Int)) -> Void) {
        moveItemBlock = b
    }
    
    public var indexTitles: [String]?
    public override func indexTitles(for collectionView: UICollectionView) -> [String]? {
        indexTitles
    }
    
}
