//
//  UICollectionView.swift
//  Boomerang
//
//  Created by Stefano Mondino on 02/11/16.
//
//

import UIKit
import RxCocoa
import RxSwift

#if swift(>=4.2)
public typealias TableViewCellEditingStyle = UITableViewCell.EditingStyle
#else
public typealias TableViewCellEditingStyle = UITableViewCellEditingStyle
#endif

public enum TableViewHeaderType: String {
    case header = "boomerang_tableview_header"
    case footer = "boomerang_tableview_footer"
    public var identifier: String {
        return self.rawValue
    }
}

//public extension UITableViewCell {
//
//    public var isPlaceholder:Bool {
//        get { return objc_getAssociatedObject(self, &AssociatedKeys.isPlaceholder) as? Bool ?? false}
//        set { objc_setAssociatedObject(self, &AssociatedKeys.isPlaceholder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
//    }
//}
public protocol EditableViewModel: ListViewModelType {
    func canEditItem(atIndexPath indexPath: IndexPath) -> Bool
    func canDeleteItem(atIndexPath indexPath: IndexPath) -> Bool
    func deleteItem(atIndexPath indexPath: IndexPath)
    func canInsertItem(atIndexPath indexPath: IndexPath) -> Bool
    func insertItem(atIndexPath indexPath: IndexPath)
    func canMoveItem(atIndexPath indexPath: IndexPath) -> Bool
    func moveItem(fromIndexPath from: IndexPath, to: IndexPath)
}
public extension EditableViewModel {
    func canEditItem(atIndexPath indexPath: IndexPath) -> Bool {return true}
    func canDeleteItem(atIndexPath indexPath: IndexPath) -> Bool {return true}
    func deleteItem(atIndexPath indexPath: IndexPath) {self.dataHolder.deleteItem(atIndex: indexPath)}
    func canInsertItem(atIndexPath indexPath: IndexPath) -> Bool {return false}
    func insertItem(atIndexPath indexPath: IndexPath) {}
    func canMoveItem(atIndexPath indexPath: IndexPath) -> Bool {return false}
    func moveItem(fromIndexPath from: IndexPath, to: IndexPath) {}
}
private class ViewModelTableViewDataSource: NSObject, UITableViewDataSource {
    weak var viewModel: ListViewModelType?
    init (viewModel: ListViewModelType) {
        super.init()
        self.viewModel = viewModel
        
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel: ItemViewModelType? = self.viewModel?.viewModel(atIndex: indexPath)
        var reuseIdentifier = defaultListIdentifier
        if let value = viewModel?.itemIdentifier {
            reuseIdentifier = self.viewModel?.reuseIdentifier(for: value, at: indexPath) ?? value.name
            if value.isEmbeddable {
                tableView.register(ContentTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
            } else {
                tableView.register(UINib(nibName: value.name, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        (cell as? ViewModelBindableType)?.bind(to: viewModel)
        return cell
    }
    public func numberOfSections(in tableView: UITableView) -> Int {
        let count =  self.viewModel?.dataHolder.modelStructure.value.children?.count ?? 1
        return count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count =  self.viewModel?.dataHolder.modelStructure.value.children?[section].models?.count
        count =  count ?? self.viewModel?.dataHolder.modelStructure.value.models?.count
        return count ?? 0
    }
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    struct StaticCellParameters {
        var constraint: NSLayoutConstraint!
        var cell: UIView!
    }
    
    var staticCells = [String: StaticCellParameters]()
    
    func staticCellForSizeAtIndexPath (_ indexPath: IndexPath, width: Float) -> UIView? {
        
        guard let nib = self.viewModel?.identifier(atIndex: indexPath) else {
            return nil
        }
        
        var parameters = self.staticCells[nib.name]
        
        if (parameters == nil) {
            guard let cell = Bundle.main.loadNibNamed(nib.name, owner: self, options: [:])!.first as? UIView else { return nil}
            guard let embeddable = cell as? EmbeddableView else { return nil }
            embeddable.customContentView.translatesAutoresizingMaskIntoConstraints = false
            let constraint = NSLayoutConstraint(
                item: embeddable.customContentView,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: CGFloat(width))
            embeddable.customContentView.addConstraint(constraint)
            embeddable.isPlaceholder = true
            parameters = StaticCellParameters(constraint: constraint, cell: cell)
            
        }
        
        parameters!.constraint?.constant = CGFloat(width)
        (parameters!.cell as? ViewModelBindableType)?.bind(to: self.viewModel?.viewModel(atIndex: indexPath))
        //        self.bindViewModelToCellAtIndexPath(parameters!.cell, indexPath: indexPath, forResize: true)
        var newCells = staticCells
        newCells[nib.name] = parameters
        
        self.staticCells = newCells
        return parameters?.cell
        
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (tableView.viewModel as? EditableViewModel)?.canEditItem(atIndexPath: indexPath) ?? false
    }
    public func tableView(_ tableView: UITableView, commit editingStyle: TableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let viewModel = tableView.viewModel as? EditableViewModel else {
            return
        }
        switch editingStyle {
        case .delete:
            if (viewModel.canDeleteItem(atIndexPath: indexPath)) {
                viewModel.deleteItem(atIndexPath: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .insert:
            if (viewModel.canInsertItem(atIndexPath: indexPath)) {
                viewModel.insertItem(atIndexPath: indexPath)
                tableView.insertRows(at: [indexPath], with: .automatic)
            }
        default : break
        }
        //tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (tableView.viewModel as? EditableViewModel)?.canMoveItem(atIndexPath: indexPath) ?? false
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        (tableView.viewModel as? EditableViewModel)?.moveItem(fromIndexPath: sourceIndexPath, to: destinationIndexPath)
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
    
    func autoSizeForItemAtIndexPath(_ indexPath: IndexPath, width: Float) -> CGSize {
        let cell = self.staticCellForSizeAtIndexPath(indexPath, width: width) as? EmbeddableView
        cell?.customContentView.setNeedsLayout()
        cell?.customContentView.layoutIfNeeded()
        #if swift(>=4.2)
        let size = cell?.customContentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) ?? CGSize.zero
        #else
        let size = cell?.customContentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize.zero
        #endif
        
        return size
    }
    
}
private struct AssociatedKeys {
    static var viewModel = "viewModel"
    static var disposeBag = "disposeBag"
    static var isPlaceholder = "isPlaceholder"
    static var tableViewDataSource = "tableViewDataSource"
}

public extension ListViewModelType {
    
    var tableViewDataSource: UITableViewDataSource? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.tableViewDataSource) as? UITableViewDataSource}
        set { objc_setAssociatedObject(self, &AssociatedKeys.tableViewDataSource, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
}

private class EmptyReusableView: UICollectionViewCell {
    fileprivate static let emptyReuseIdentifier = "_emptyReusableView"
}

open class ContentTableViewCell: UITableViewCell, ViewModelBindable {
    public var viewModel: ViewModelType?
    public var disposeBag: DisposeBag = DisposeBag()
    weak var internalView: UIView?
    public var insetConstraints: [NSLayoutConstraint] = []
    
    public func bind(to viewModel: ViewModelType?) {
        guard let viewModel = viewModel as? ItemViewModelType else {
            return
        }
        
        self.disposeBag = DisposeBag()
        self.viewModel = viewModel
        self.backgroundColor = .clear
        if (self.internalView == nil) {
            guard let view = Bundle.main.loadNibNamed(viewModel.itemIdentifier.name, owner: self, options: nil)?.first as? UIView else {
                return
            }
            
            self.insetConstraints = self.contentView.addAndFitSubview(view)
            self.internalView = view
        }
        (self.internalView as? ViewModelBindableType)?.bind(to: viewModel)
    }
}
open class ContentTableHeaderFooterView: UITableViewHeaderFooterView, ViewModelBindable {
    public var viewModel: ViewModelType?
    public var disposeBag: DisposeBag = DisposeBag()
    weak var internalView: UIView?
    public var insetConstraints: [NSLayoutConstraint] = []
    
    public func bind(to viewModel: ViewModelType?) {
        guard let viewModel = viewModel as? ItemViewModelType else {
            return
        }
        self.backgroundColor = .clear
        self.disposeBag = DisposeBag()
        self.viewModel = viewModel
        if (self.internalView == nil) {
            guard let view = Bundle.main.loadNibNamed(viewModel.itemIdentifier.name, owner: self, options: nil)?.first as? UIView else {
                return
            }
            
            self.insetConstraints = self.contentView.addAndFitSubview(view)
            self.internalView = view
        }
        (self.internalView as? ViewModelBindableType)?.bind(to: viewModel)
    }
}
extension UITableView: ViewModelBindable {
    
    public var viewModel: ViewModelType? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.viewModel) as? ViewModelType}
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    public func viewForHeader(inSection section: Int) -> UIView? {
        guard let sectionable = self.viewModel as? ListViewModelTypeSectionable else {
            return nil
        }
        let indexPath = IndexPath(row: 0, section: section)
        guard let model = sectionable.dataHolder.modelStructure.value.sectionModelAtIndexPath(indexPath, forType: TableViewHeaderType.header.identifier.name) else {
            return nil
        }
        guard let viewModel = sectionable.sectionItemViewModel(fromModel: model, withType: TableViewHeaderType.header.identifier.name) else {
            return nil
        }
        let value = viewModel.itemIdentifier
        let reuseIdentifier = sectionable.reuseIdentifier(for: value, at: indexPath) ?? value.name
        if viewModel.itemIdentifier.isEmbeddable {
            self.register(ContentTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        } else {
            self.register(UINib(nibName: value.name, bundle: nil), forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
        let cell = self.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier)
        (cell as? ViewModelBindableType)?.bind(to: viewModel)
        return cell
        
    }
    
    public func viewForFooter(inSection section: Int) -> UIView? {
        guard let sectionable = self.viewModel as? ListViewModelTypeSectionable else {
            return nil
        }
        let indexPath = IndexPath(row: 0, section: section)
        guard let model = sectionable.dataHolder.modelStructure.value.sectionModelAtIndexPath(indexPath, forType: TableViewHeaderType.footer.identifier.name) else {
            return nil
        }
        guard let viewModel = sectionable.sectionItemViewModel(fromModel: model, withType: TableViewHeaderType.footer.identifier.name) else {
            return nil
        }
        
        let value = viewModel.itemIdentifier
        let reuseIdentifier = sectionable.reuseIdentifier(for: value, at: indexPath) ?? value.name
        if viewModel.itemIdentifier.isEmbeddable {
            self.register(ContentTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        } else {
            self.register(UINib(nibName: value.name, bundle: nil), forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
        let cell = self.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier)
        (cell as? ViewModelBindableType)?.bind(to: viewModel)
        return cell
    }
    
    public var disposeBag: DisposeBag {
        get {
            var disposeBag: DisposeBag
            
            if let lookup = objc_getAssociatedObject(self, &AssociatedKeys.disposeBag) as? DisposeBag {
                disposeBag = lookup
            } else {
                disposeBag = DisposeBag()
                objc_setAssociatedObject(self, &AssociatedKeys.disposeBag, disposeBag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            return disposeBag
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.disposeBag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func bind(to viewModel: ViewModelType?) {
        guard let viewModel = viewModel as? ListViewModelType else {
            self.viewModel = nil
            return
        }
        self.viewModel = viewModel
        
        if (viewModel.tableViewDataSource == nil) {
            viewModel.tableViewDataSource = ViewModelTableViewDataSource(viewModel: viewModel)
        }
        self.register(ContentTableHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: defaultListIdentifier)
        self.dataSource = viewModel.tableViewDataSource
        
        viewModel
            .dataHolder
            .reloadAction
            .elements
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in self?.reloadData() })
            .disposed(by: self.disposeBag)
        
        if (self.backgroundView != nil) {
            viewModel.isEmpty.asObservable().map {!$0}.bind(to: self.backgroundView!.rx.isHidden).disposed(by: self.disposeBag)
        }
    }
    public func autosizeItemAt(indexPath: IndexPath, constrainedToWidth width: CGFloat) -> CGFloat {
        guard let viewModel = viewModel as? ListViewModelType else {
            return 0
        }
        guard let dataSource = viewModel.tableViewDataSource as? ViewModelTableViewDataSource else {
            return 0
        }
        return dataSource.autoSizeForItemAtIndexPath(indexPath, width: Float(width)).height
    }
    
}
