//
//  CGFloat+.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit

extension CGFloat {
    static var unsafeAreaBottomHeight: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? CGFloat(0)
    }
    
    static var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    
    static var componentHorizontalMargin: CGFloat {
        return CGFloat(10)
    }
    
    static var componentVerticalMargin: CGFloat {
        return CGFloat(16)
    }
}
