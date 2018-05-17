//
//  SelectedPhotosViewController.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit
import Photos
import AVKit

class SelectedPhotosViewController: UICollectionViewController {
    private var assets = [Asset]()
    
    private var photoSize: CGFloat!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoSize = (view.bounds.width - 4 * .componentHorizontalMargin) / 3
        collectionView?.contentInset = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onPressPickPhotos(_ sender: Any) {
        performSegue(withIdentifier: "photoLibrary", sender: self)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PreviewPhotoCell
        
        let asset = assets[indexPath.row].data
        if let photo = asset as? UIImage {
            cell.imageView.image = photo
        } else if let videoUrl = asset as? URL {
            let player = AVPlayer.init(url: videoUrl)
            let playerLayer = AVPlayerLayer.init(player: player)
            playerLayer.frame = cell.imageView.frame
            playerLayer.videoGravity = .resizeAspect
            cell.imageView.layer.addSublayer(playerLayer)
            player.play()
        } else if let imageData = asset as? Data {
            cell.imageView.image = UIImage.gif(data: imageData)
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PreviewPhotoCell {
            presentImageView(initialIndex: indexPath.row, initialView: cell.imageView)
        }
    }
    
    private func presentImageView(initialIndex: Int, initialView: UIImageView) {
        if let window = UIApplication.shared.keyWindow {
            let container = UIView.init(frame: window.frame)
            container.alpha = 0
            container.backgroundColor = UIColor.black
            let imageView = UIImageView.init(frame: .init(origin: initialView.convert(initialView.bounds.origin, to: container), size: initialView.frame.size))
            imageView.image = initialView.image
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            container.addSubview(imageView)
            
            window.addSubview(container)
            
            UIView.animate(
                withDuration: 0.75,
                animations: {
                    container.alpha = 1
                    imageView.frame = container.frame
                },
                completion: { (_) in
                    let imageViewerController = ImageViewerController()
                    imageViewerController.modalTransitionStyle = .crossDissolve
                    imageViewerController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                    imageViewerController.assets = self.assets
                    imageViewerController.initialIndex = initialIndex
                    self.present(
                        imageViewerController,
                        animated: false,
                        completion: { container.removeFromSuperview() }
                    )
                }
            )
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoLibrary" {
            let photoLibraryViewController = (segue.destination as! UINavigationController).viewControllers.first as! PhotoLibraryViewController
            photoLibraryViewController.delegate = self
            photoLibraryViewController.assetType = nil
            photoLibraryViewController.limit = 4
        }
    }
}

extension SelectedPhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat.componentHorizontalMargin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat.componentHorizontalMargin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: photoSize, height: photoSize)
    }
}

extension SelectedPhotosViewController: PhotoLibraryViewControllerDelegate {
    func didSelectGIF(gif: Data) {
        assets = [Asset.init(assetType: .gif, data: gif)]
        collectionView?.reloadData()
    }
    
    func didSelectVideo(videoUrl: URL) {
        assets = [Asset.init(assetType: .video, data: videoUrl)]
        collectionView?.reloadData()
    }
    
    func didSelectPhotos(photos: [UIImage]) {
        assets.removeAll()
        for photo in photos {
            assets.append(Asset.init(assetType: .image, data: photo))
        }
        collectionView?.reloadData()
    }
}
