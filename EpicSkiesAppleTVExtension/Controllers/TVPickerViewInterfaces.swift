//
//  TVPickerViewInterfaces.swift
//  TVPickerView
//
//  Created by Max Chuquimia on 25/10/2015.
//  Copyright © 2015 Chuquimian Productions. All rights reserved.
//

import UIKit

// MARK: - Public Protocols For TVPickerView

public protocol TVPickerInterface {
    
    weak var focusDelegate: TVPickerViewFocusDelegate? { get set }
    
    weak var dataSource: TVPickerViewDataSource? { get set }
    
    weak var delegate: TVPickerViewDelegate? { get set }
    
    var deepFocus: Bool { get }
    
    var selectedIndex: Int { get }
    
    func reloadData()

    func scrollToIndex(_ idx: Int)
}

public protocol TVPickerViewFocusDelegate: class {
    
    func pickerView(_ picker: TVPickerView, deepFocusStateChanged isDeepFocus: Bool)
}

public protocol TVPickerViewDelegate: class {
    func pickerView(_ picker: TVPickerView, didChangeToIndex index: Int)
}

public protocol TVPickerViewDataSource: class {

    func numberOfViewsInPickerView(_ picker: TVPickerView) -> Int

    func pickerView(_ picker: TVPickerView, viewForIndex idx: Int, reusingView view: UIView?) -> UIView
}
