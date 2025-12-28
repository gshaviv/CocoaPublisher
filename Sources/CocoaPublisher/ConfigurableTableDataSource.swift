//
//  File.swift
//
//
//  Created by Guy on 11/11/2021.
//

import UIKit

@MainActor
public class ConfigurableTableViewDataSource<SectionIdentifierType, ItemIdentifierType>: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
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
    
    public override init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableViewIfNeeded), name: updateItemsNotification, object: self)
        defaultRowAnimation = .fade // make this the efault as the auto default doesn't work well
    }
    
    @objc public func updateTableViewIfNeeded() {
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
    
    public func itemIdentifier(for indexPath: (section: SectionIdentifierType, row: Int)) -> ItemIdentifierType? {
        let allSections = sections.filter { items.keys.contains($0) }
        if let idx = allSections.firstIndex(of: indexPath.section) {
            return itemIdentifier(for: IndexPath(row: indexPath.row, section: idx))
        }
        return nil
    }
    
    private var canEditRowBlock: (((section: SectionIdentifierType, row: Int)) -> Bool)?
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let section = section(for: indexPath.section) {
            return canEditRowBlock?((section: section, row: indexPath.row)) ?? false
        }
        return false
    }
    public func canEditRow(_ b: @escaping (_ indexPath: (section: SectionIdentifierType, row: Int)) -> Bool) {
        canEditRowBlock = b
    }
    
    private var titleForHeader: ((SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader?(sections[section])
    }
    public func titleForHeaderInSection(_ b: @escaping (_ section: SectionIdentifierType) -> String?) {
        titleForHeader = b
    }
    
    private var titleForFooter: ((SectionIdentifierType) -> String?)?
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        titleForFooter?(sections[section])
    }
    public func titleForFooterInSection(_ b: @escaping (_ section: SectionIdentifierType) -> String?) {
        titleForFooter = b
    }
    
    private var commitEditing: ((UITableViewCell.EditingStyle, (section: SectionIdentifierType, row: Int)) -> Void)?
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if let section = section(for: indexPath.section) {
            commitEditing?(editingStyle, (section: section, row: indexPath.row))
        }
    }
    public func commitEdit(_ b: @escaping (_ editingStyle: UITableViewCell.EditingStyle, _ indexPath: (section: SectionIdentifierType, row: Int)) -> Void) {
        commitEditing = b
    }
    
    private var canMoveRowBlock: (((section: SectionIdentifierType, row: Int)) -> Bool)?
    public override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let section = section(for: indexPath.section) {
            return canMoveRowBlock?((section: section, row: indexPath.row)) ?? false
        }
        return false
    }
    public func canMoveRow(_ b: @escaping (_ indexPath: (section: SectionIdentifierType, row: Int)) -> Bool) {
        canMoveRowBlock = b
    }
    
    private var moveRowBlock: (((section: SectionIdentifierType, row: Int), (section: SectionIdentifierType, row: Int)) -> Void)?
    public override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let sourceSection = section(for: sourceIndexPath.section), let destinationSection = section(for: destinationIndexPath.section) {
            moveRowBlock?((section: sourceSection, row: sourceIndexPath.row), (section: destinationSection, row: destinationIndexPath.row))
        }
    }
    public func moveRow(_ b: @escaping (_ sourceIndexPath: (section: SectionIdentifierType, row: Int), _ destinationIndexPath: (section: SectionIdentifierType, row: Int)) -> Void) {
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
