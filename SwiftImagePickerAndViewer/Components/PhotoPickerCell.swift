//
//  PhotoPickerCell.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit

class PhotoPickerCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!  // Display the image for selection
    @IBOutlet weak var indexLabel: UILabel!     // If selected, display the index, otherwise make it transparent
    @IBOutlet weak var videoLabel: UILabel!     // If the asset is a video or GIF image, add this label to it
    @IBOutlet weak var coverView: UIView!       // If the asset should not be selected, then cover the cell with it
    
    // Should this asset be selectable?
    var selectable: Bool = true {
        didSet {
            if selectable {
                coverView.frame.size = .zero
            } else {
                coverView.frame.size = frame.size
                coverView.backgroundColor = UIColor.init(white: 0, alpha: 0.75)
            }
        }
    }
    
    var isVideo: Bool = false
    var isGIF: Bool = false
    
    override func prepareForReuse() {
        imageView.image = nil
        indexLabel.text = nil
        indexLabel.backgroundColor = UIColor.clear
        videoLabel.text = nil
        videoLabel.backgroundColor = UIColor.clear
        coverView.frame.size = .zero
        isVideo = false
        isGIF = false
    }
}
