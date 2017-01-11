//
//  UILabel.swift
//  Boomerang
//
//  Created by Stefano Mondino on 21/11/16.
//
//

import UIKit
import RxSwift
import RxCocoa


private struct AssociatedKeys {
    static var viewModel = "viewModel"
    static var DisposeBag = "boomerang_disposeBag"
    
}
extension UITextField : ViewModelBindable {
    
    public var viewModel: ViewModelType? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.viewModel) as? ViewModelType}
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public var disposeBag: DisposeBag {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.DisposeBag) as! DisposeBag}
        set { objc_setAssociatedObject(self, &AssociatedKeys.DisposeBag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public func bind(_ viewModel: ViewModelType?) {
        self.viewModel = viewModel
        guard let vm = viewModel as? TextInput else {
            return
        }
        self.placeholder = vm.title
        
        self.disposeBag = DisposeBag()
        vm.string.asObservable().distinctUntilChanged().delay(0.0, scheduler: MainScheduler.instance).bindTo(self.rx.text).addDisposableTo(self.disposeBag)
        self.rx.text.map { $0 ?? ""}.bindTo(vm.string).addDisposableTo(self.disposeBag)
        
    }
    
    
    
    
}

extension UITextView : ViewModelBindable {
    
    public var viewModel: ViewModelType? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.viewModel) as? ViewModelType}
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewModel, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public var disposeBag: DisposeBag {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.DisposeBag) as! DisposeBag}
        set { objc_setAssociatedObject(self, &AssociatedKeys.DisposeBag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public func bind(_ viewModel: ViewModelType?) {
        self.viewModel = viewModel
        guard let vm = viewModel as? TextInput else {
            return
        }
        
        
        self.disposeBag = DisposeBag()
        
        vm.string.asObservable().distinctUntilChanged().delay(0.0, scheduler: MainScheduler.instance).bindTo(self.rx.text).addDisposableTo(self.disposeBag)
        self.rx.text.map { $0 ?? ""}.bindTo(vm.string).addDisposableTo(self.disposeBag)
    }
    
    
    
    
}
