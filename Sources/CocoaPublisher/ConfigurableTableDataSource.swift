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
            needsUpdateItems = true
            NotificationQueue.default.enqueue(Notification(name: updateItemsNotification, object: self, userInfo: nil), postingStyle: .whenIdle, coalesceMask: [.onName, .onSender], forModes: nil)
        }
    }
    public var sections = [SectionIdentifierType]() {
        didSet {
            needsUpdateItems = true
            NotificationQueue.default.enqueue(Notification(name: updateItemsNotification, object: self, userInfo: nil), postingStyle: .whenIdle, coalesceMask: [.onName, .onSender], forModes: nil)
        }
    }
    private(set) public var needsUpdateItems = false
    
    private var updateItemsNotification = Notification.Name("updateItems")
    
    public override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        NotificationCenter.default.addObserver(self, selector: #selector(updateItemsIfNeeded), name: updateItemsNotification, object: self)
    }
    
    @objc public func updateItemsIfNeeded() {
        guard needsUpdateItems else { return }
        defer {
            needsUpdateItems = false
        }
        var snap = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        snap.appendSections(sections)
        for (section, items) in items {
            snap.appendItems(items, toSection: section)
        }
        apply(snap, animatingDifferences: true)
    }
    
    private var canEditRowBlock: ((IndexPath) -> Bool)?
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        canEditRowBlock?(indexPath) ?? false
    }
    public func canEditRow(_ b: @escaping (IndexPath) -> Bool) {
        canEditRowBlock = b
    }
    
    private var titleForHeader: ((_ section: SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader?(sections[section])
    }
    public func titleForHeaderInSection(_ b: @escaping (SectionIdentifierType) -> String?) {
        titleForHeader = b
    }
    
    private var titleForFooter: ((_ section: SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        titleForFooter?(sections[section])
    }
    public func titleForFooterInSection(_ b: @escaping (SectionIdentifierType) -> String?) {
        titleForFooter = b
    }
    
    private var commitEditing: ((UITableViewCell.EditingStyle, IndexPath) -> Void)?
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        commitEditing?(editingStyle, indexPath)
    }
    public func commitEdit(_ b: @escaping (UITableViewCell.EditingStyle, IndexPath) -> Void) {
        commitEditing = b
    }
    
    private var canMoveRowBlock: ((IndexPath) -> Bool)?
    public override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        canMoveRowBlock?(indexPath) ?? false
    }
    public func canMoveRow(_ b: @escaping (IndexPath) -> Bool) {
        canMoveRowBlock = b
    }
    
    private var moveRowBlock: ((IndexPath, IndexPath) -> Void)?
    public override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveRowBlock?(sourceIndexPath, destinationIndexPath)
    }
    public func moveRow(_ b: @escaping (_ sourceIndexPath: IndexPath, _ destinationIndexPath: IndexPath) -> Void) {
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
