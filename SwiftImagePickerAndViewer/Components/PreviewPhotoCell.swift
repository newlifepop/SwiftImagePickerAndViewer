//
//  PreviewPhotoCell.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit

class PreviewPhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        imageView.image = nil
        for sublayer in imageView.layer.sublayers ?? [] {
            sublayer.removeFromSuperlayer()
        }
    }
}
