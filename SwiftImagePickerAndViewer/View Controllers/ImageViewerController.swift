//
//  ImageViewerController.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit
import Photos
import AVKit

private let reuseIdentifier: String = "ImageDetailCell"

enum AssetType {
    case image
    case video
    case gif
}

struct Asset {
    var assetType: AssetType
    var data: Any
}

class ImageViewerController: UIViewController {
    private var assetCollectionView: UICollectionView!
    private var collectionViewLayout: UICollectionViewFlowLayout!
    
    var assets: [Asset]!
    var initialIndex: Int!
    private var currentIndex: Int!
    
    private var indexLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func configureContent() {
        view.isOpaque = false
        view.backgroundColor = UIColor.black
        
        collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = view.bounds.size
        collectionViewLayout.minimumLineSpacing = 0
        assetCollectionView = UICollectionView.init(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        assetCollectionView.register(UINib.init(nibName: "ImageDetailCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        assetCollectionView.delegate = self
        assetCollectionView.dataSource = self
        assetCollectionView.isPagingEnabled = true
        assetCollectionView.showsHorizontalScrollIndicator = false
        assetCollectionView.backgroundColor = UIColor.clear
        view.addSubview(assetCollectionView)
        
        assetCollectionView.scrollToItem(at: .init(item: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
        currentIndex = initialIndex
        
        let indexLabelWidth: CGFloat = 50
        let indexLabelHeight: CGFloat = 30
        let indexLabelOriginX: CGFloat = (view.bounds.width - indexLabelWidth) / 2
        let indexLabelOriginY: CGFloat = view.bounds.height - .unsafeAreaBottomHeight - .componentVerticalMargin - indexLabelHeight
        indexLabel = UILabel.init(frame: .init(x: indexLabelOriginX, y: indexLabelOriginY, width: indexLabelWidth, height: indexLabelHeight))
        indexLabel.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        indexLabel.textColor = UIColor.white
        indexLabel.font = UIFont.systemFont(ofSize: 14)
        indexLabel.textAlignment = .center
        indexLabel.text = "\(currentIndex + 1) / \(assets.count)"
        view.addSubview(indexLabel)
        
        let cancelButton = UIButton.init(type: .system)
        cancelButton.frame = .init(x: .componentHorizontalMargin, y: .statusBarHeight + .componentVerticalMargin, width: 32, height: 32)
        cancelButton.clipsToBounds = true
        cancelButton.layer.cornerRadius = cancelButton.frame.height / 2
        cancelButton.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        cancelButton.setImage(#imageLiteral(resourceName: "cancel"), for: .normal)
        cancelButton.tintColor = UIColor.init(white: 1, alpha: 0.85)
        cancelButton.addTarget(self, action: #selector(onPressCancel), for: .touchUpInside)
        view.addSubview(cancelButton)
    }
    
    @objc private func onPressCancel() {
        dismiss(animated: true, completion: {
            self.view.subviews.forEach({
                $0.layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
            })
        })
    }
}

extension ImageViewerController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageDetailCell
        cell.parentViewController = self
        
        let asset = assets[indexPath.row]
        switch asset.assetType {
        case .image:
            if let photo = asset.data as? UIImage {
                cell.imageView.image = photo
            }
            break
        case .gif:
            if let data = asset.data as? Data {
                cell.imageView.image = UIImage.gif(data: data)
            }
            break
        case .video:
            if let videoUrl = asset.data as? URL {
                addPlayerLayer(to: cell, with: videoUrl)
            }
            break
        }
        
        return cell
    }
    
    private func addPlayerLayer(to view: UIView, with url: URL) {
        let player = AVPlayer.init(url: url)
        let playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = view.frame
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let itemWidth: CGFloat = collectionViewLayout.itemSize.width
        let itemWithSpaceWidth: CGFloat = itemWidth + collectionViewLayout.minimumLineSpacing
        
        for i in 0..<assetCollectionView.numberOfItems(inSection: 0) {
            if assetCollectionView.contentOffset.x <= CGFloat(i) * itemWithSpaceWidth + itemWidth / 2 {
                currentIndex = i
                indexLabel.text = "\(currentIndex + 1) / \(assets.count)"
                break
            }
        }
    }
}
