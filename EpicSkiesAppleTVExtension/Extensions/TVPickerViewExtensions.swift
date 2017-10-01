//
//  TVPickerViewExtensions.swift
//  TVPickerView
//
//  Created by Max Chuquimia on 25/10/2015.
//  Copyright © 2015 Chuquimian Productions. All rights reserved.
//

import UIKit

// MARK: - UIViewExtensions For Custom TVPickerView

extension UIView {

    func setupForPicker(_ picker: TVPickerView) -> Self {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let size = CGSize(width: picker.bounds.width / 2.0, height: picker.bounds.height)
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        return self
    }
    
    func setX(_ x: CGFloat, _ dx: CGFloat) {
        center.x = x
        let scaleAmount = (1 - max(dx, 0.65)) + 0.65
        layer.transform = CATransform3DMakeScale(1.0 * scaleAmount, 1.0 * scaleAmount, 1.0)
    }

    func sizeToView(_ v: UIView) {
        frame = v.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
