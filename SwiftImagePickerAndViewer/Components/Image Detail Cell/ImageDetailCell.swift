//
//  ImageDetailCell.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit

class ImageDetailCell: UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var parentViewController: UIViewController?
    
    override func prepareForReuse() {
        for sublayer in imageView.layer.sublayers ?? [] {
            sublayer.removeFromSuperlayer()
        }
        parentViewController = nil
        imageView.image = nil
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let scrollX = abs(scrollView.contentOffset.x)
        let scrollY = abs(scrollView.contentOffset.y)
        
        if scrollX == 0.0 && scrollY >= 30 {
            parentViewController?.dismiss(
                animated: true,
                completion: {
                    self.parentViewController?.view.subviews.forEach({
                        $0.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
                    })
            })
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollX = abs(scrollView.contentOffset.x)
        let scrollY = abs(scrollView.contentOffset.y)
        
        if scrollX == 0.0 {
            parentViewController?.view.backgroundColor = UIColor.init(white: 0, alpha: 1 - scrollY / 250)
        }
    }
}
