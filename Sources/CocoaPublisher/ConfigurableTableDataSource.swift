//
//  File.swift
//
//
//  Created by Guy on 11/11/2021.
//

import UIKit

public class ConfigurableTableViewDataSource<SectionIdentifierType, ItemIdentifierType>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
    public var items = [SectionIdentifierType: [ItemIdentifierType]]() {
        didSet {
            NotificationQueue.default.enqueue(Notification(name: updateItemsNotification, object: self, userInfo: nil), postingStyle: .asap, coalesceMask: [.onName, .onSender], forModes: nil)
        }
    }
    public var sections = [SectionIdentifierType]() {
        didSet {
            NotificationQueue.default.enqueue(Notification(name: updateItemsNotification, object: self, userInfo: nil), postingStyle: .asap, coalesceMask: [.onName, .onSender], forModes: nil)
        }
    }
    
    private var updateItemsNotification = Notification.Name("updateItems")
    
    public override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        NotificationCenter.default.addObserver(self, selector: #selector(updateItems), name: updateItemsNotification, object: self)
    }
    
    @objc private func updateItems() {
        var snap = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
//        for section in sections {
//            if let sectionItems = items[section] {
//                snap.appendSections([section])
//                snap.appendItems(sectionItems, toSection: section)
//            }
//        }
        snap.appendSections(sections)
        for (section, items) in items {
            snap.appendItems(items, toSection: section)
        }
        apply(snap, animatingDifferences: true)
    }
    
    private var canEditRowBlock: ((UITableView, IndexPath) -> Bool)?
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        canEditRowBlock?(tableView, indexPath) ?? false
    }
    public func canEditRow(_ b: @escaping (UITableView, IndexPath) -> Bool) {
        canEditRowBlock = b
    }
    
    private var titleForHeader: ((UITableView, SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader?(tableView, sections[section])
    }
    public func titleForHeaderInSection(_ b: @escaping (UITableView, SectionIdentifierType) -> String?) {
        titleForHeader = b
    }
    
    private var titleForFooter: ((UITableView, SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        titleForFooter?(tableView, sections[section])
    }
    public func titleForFooterInSection(_ b: @escaping (UITableView, SectionIdentifierType) -> String?) {
        titleForFooter = b
    }
    
    private var commitEditing: ((UITableView, UITableViewCell.EditingStyle, IndexPath) -> Void)?
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        commitEditing?(tableView, editingStyle, indexPath)
    }
    public func commitEdit(_ b: @escaping (UITableView, UITableViewCell.EditingStyle, IndexPath) -> Void) {
        commitEditing = b
    }
    
    private var canMoveRowBlock: ((UITableView, IndexPath) -> Bool)?
    public override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        canMoveRowBlock?(tableView, indexPath) ?? false
    }
    public func canMoveRow(_ b: @escaping (UITableView, IndexPath) -> Bool) {
        canMoveRowBlock = b
    }
    
    private var moveRowBlock: ((UITableView, IndexPath, IndexPath) -> Void)?
    public override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveRowBlock?(tableView, sourceIndexPath, destinationIndexPath)
    }
    public func moveRow(_ b: @escaping (_ tableView: UITableView, _ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Void) {
        moveRowBlock = b
    }
    
    public var sectionIndexTitles: [String]?
    public override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sectionIndexTitles
    }
    
    private var sectionForSectionIndexTitle: ((UITableView, String, Int) -> SectionIdentifierType)?
    public override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let sectionForSectionIndexTitle = sectionForSectionIndexTitle {
            let sectionIdentifier = sectionForSectionIndexTitle(tableView, title, index)
            for (index, section) in sections.enumerated() {
                if sectionIdentifier == section {
                    return index
                }
            }
        }
        return 0
    }
    public func sectionForSectionIndexTitle(_ b: @escaping (_ tableView: UITableView, _ title: String, _ index: Int) -> SectionIdentifierType) {
        sectionForSectionIndexTitle = b
    }
}
