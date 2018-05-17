//
//  PhotoLibraryViewController.swift
//  SwiftImagePickerAndViewer
//
//  Created by Changyu Wu on 5/16/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit
import Photos               // Used to access camera roll
import MobileCoreServices   // Used to check if an asset is a GIF image

@objc protocol PhotoLibraryViewControllerDelegate {
    @objc optional func didSelectVideo(videoUrl: URL)       // If selected a video, its url gets returned
    @objc optional func didSelectPhotos(photos: [UIImage])  // If selected photo(s), return array of UIImage
    @objc optional func didSelectGIF(gif: Data)             // If selected gif, return data of the gif
}

class PhotoLibraryViewController: UICollectionViewController {
    var delegate: PhotoLibraryViewControllerDelegate?
    
    var assetType: [PHAssetMediaType]?      // What assets are allowed to be selected? e.g. [.image, .video],
                                            // meaning that both images and videos can be selected
                                            // And, regardless of what 'assetType' is, at most 1 video can be selected
                                            // Here, GIFs are treated same as a video
    private var allowImageSelection: Bool!
    private var allowVideoSelection: Bool!
    
    var limit: Int = 0                  // How many assets can be selected?
    
    private var assets: PHFetchResult<PHAsset>!     // All assets in camera roll
    private var selectedIndexPaths = [IndexPath]()  // Save selected photos' index paths in this array
    private var allIndexPaths = [IndexPath]()       // Save all photos' index paths in this array
    
    private let imageManager = PHCachingImageManager()  // Generate & Cache thumbnails of each asset to display
    private var previousPreheatRect: CGRect = CGRect.zero
    private var photoSize: CGSize!
    private let requestOption = PHImageRequestOptions()
    
    private let modalView = ModalView()     // Disable any user interaction when doing some task
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestOption.isNetworkAccessAllowed = true
        requestOption.resizeMode = .none
        requestOption.version = .original
        
        let size = collectionView!.frame.width / 3
        photoSize = CGSize.init(width: size, height: size)
        
        PHPhotoLibrary.shared().register(self)
        
        let options: PHFetchOptions = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        
        if let type = assetType {
            allowVideoSelection = type.contains(PHAssetMediaType.video)
            allowImageSelection = type.contains(PHAssetMediaType.image)
        } else {
            allowVideoSelection = true
            allowImageSelection = true
        }
        
        if allowVideoSelection && !allowImageSelection {
            options.predicate = NSPredicate.init(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        } else if allowImageSelection && !allowVideoSelection {
            options.predicate = NSPredicate.init(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        } else {
            options.predicate = NSPredicate.init(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
        }
        
        assets = PHAsset.fetchAssets(with: options)
        for i in 0..<assets.count {
            allIndexPaths.append(.init(row: i, section: 0))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onPressCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onPressDone(_ sender: Any) {
        modalView.showModal(message: "Loading images ...")
        
        // Get original photos of selected assets, with correct order
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue.init(label: "Queue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        
        var selectedImages = [UIImage]()
        dispatchQueue.async {
            for indexPath in self.selectedIndexPaths {
                let asset = self.assets[indexPath.row]
                dispatchGroup.enter()
                
                self.getOriginalAsset(asset: asset, onComplete: { (image, _) in
                    if let img = image {
                        selectedImages.append(img)
                    }
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                })
                
                dispatchSemaphore.wait()
            }
        }
        
        dispatchGroup.notify(queue: dispatchQueue) {
            DispatchQueue.main.async {
                self.modalView.dismissModal()
                self.dismiss(animated: true, completion: { self.delegate?.didSelectPhotos!(photos: selectedImages) })
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoPickerCell
        
        // If -1, then this asset is not selected
        let index: Int = selectedIndexPaths.index(of: indexPath) ?? -1
        let asset = assets[indexPath.row]
        let isGIF: Bool = assetIsGIF(asset)
        let isVideo: Bool = asset.mediaType == .video
        if index != -1 {
            // If the asset is already selected, then we want it to be selectable (therefore, it could be deselected)
            cell.selectable = true
            cell.indexLabel.backgroundColor = UIColor.init(red: 64/255, green: 153/255, blue: 1, alpha: 1)
            cell.indexLabel.text = "\(index + 1)"
        } else {
            // If the asset is not selected yet, then whether it should be selectable depends on whether the user
            // has exceeded the selection limit
            cell.selectable = selectedIndexPaths.count < limit
        }
        
        imageManager.requestImage(for: asset, targetSize: photoSize, contentMode: .aspectFill, options: requestOption, resultHandler: { (image, _) in cell.imageView.image = image })
        
        if isVideo || isGIF {
            cell.videoLabel.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
            cell.videoLabel.text = isGIF ? "GIF" : "Video"
            cell.isGIF = isGIF
            cell.isVideo = asset.mediaType == .video
            cell.selectable = selectedIndexPaths.count == 0 && allowVideoSelection
        }
    
        return cell
    }
    
    // Check if an asset is GIF image
    private func assetIsGIF(_ asset: PHAsset) -> Bool {
        if let identifier = asset.value(forKey: "uniformTypeIdentifier") as? String {
            if identifier == kUTTypeGIF as String {
                return true
            }
        }
        
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        
        // If the target cell is not selectable, simply ignore it
        let targetCell = collectionView.cellForItem(at: indexPath) as? PhotoPickerCell
        if !(targetCell?.selectable ?? false) {
            return
        }
        
        // Create a simple bounce animation feedback
        UIView.animate(
            withDuration: 0.1,
            animations: { targetCell?.transform = CGAffineTransform.init(scaleX: 0.95, y: 0.95) },
            completion: { (_) -> Void in
                UIView.animate(
                    withDuration: 0.1,
                    animations: { targetCell?.transform = CGAffineTransform.init(scaleX: 1, y: 1) }
                )
            }
        )
        
        let asset = assets[indexPath.row]
        let isGIF = assetIsGIF(asset)
        
        // If asset is GIF/video, then immediately exit photo picker and return data/url,
        // because at maximum, to allow single video/GIF selection
        if isGIF {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.resizeMode = .none
            options.version = .original
            imageManager.requestImageData(for: asset, options: options, resultHandler: { (data, _, _, _) in
                if let imageData = data {
                    self.dismiss(animated: true, completion: { self.delegate?.didSelectGIF!(gif: imageData) })
                } else {
                    fatalError()    // Change it to something else (your error handler)
                }
            })
        } else if asset.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .original
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: options, resultHandler: { (videoAsset, audioMix, args) -> Void in
                if let video = videoAsset as? AVURLAsset {
                    self.dismiss(animated: true, completion: { self.delegate?.didSelectVideo!(videoUrl: video.url) })
                } else {
                    fatalError()    // Change it to something else (your error handler)
                }
            })
        } else if limit == 1 {
            // If only one photo is allowed to be selected, then exit photo picker and return the photo
            // Ask 'imageManager' to get the original asset instead of the thumbnail
            getOriginalAsset(asset: asset, onComplete: { (image, _) in
                if let img = image {
                    self.dismiss(animated: true, completion: { self.delegate?.didSelectPhotos!(photos: [img]) })
                } else {
                    fatalError()    // Change it to something else (your error handler)
                }
            })
        } else {
            // If reach here, that means the user has just (de)selected a photo (not GIF or video)
            let index: Int = selectedIndexPaths.index(of: indexPath) ?? -1
            if index == -1 {
                selectedIndexPaths.append(indexPath)
                // If upon selecting this photo, the user reaches the limit, then disable all other photos
                if selectedIndexPaths.count == limit {
                    makeUnselectedPhotosSelectable(collectionView: collectionView, selectable: false)
                } else if selectedIndexPaths.count == 1 && allowVideoSelection {
                    makeVideosSelectable(collectionView: collectionView, selectable: false)
                }
                
                collectionView.reloadItems(at: [indexPath])
            } else {
                selectedIndexPaths.remove(at: index)
                if selectedIndexPaths.count == limit - 1 {
                    makeUnselectedPhotosSelectable(collectionView: collectionView, selectable: true)
                } else if selectedIndexPaths.count == 0 && (assetType == nil || (assetType?.contains(PHAssetMediaType.video) ?? false)) {
                    makeVideosSelectable(collectionView: collectionView, selectable: true)
                }
                
                collectionView.reloadItems(at: Array(selectedIndexPaths[index..<selectedIndexPaths.count]) + [indexPath])
            }
        }
    }
    
    private func getOriginalAsset(asset: PHAsset, onComplete: @escaping (UIImage?, [AnyHashable: Any]?) -> ()) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .exact
        option.deliveryMode = .highQualityFormat
        option.version = .original
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: option) { (originalImage, info) in
            onComplete(originalImage, info)
        }
    }
    
    private func makeUnselectedPhotosSelectable(collectionView: UICollectionView, selectable: Bool) {
        for indexPath in allIndexPaths {
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerCell
            if !(cell?.isGIF ?? false) && !(cell?.isVideo ?? false) && !selectedIndexPaths.contains(indexPath) {
                cell?.selectable = selectable
            }
        }
    }
    
    private func makeVideosSelectable(collectionView: UICollectionView, selectable: Bool) {
        for indexPath in allIndexPaths {
            let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerCell
            if (cell?.isGIF ?? false) || (cell?.isVideo ?? false) {
                cell?.selectable = selectable
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    private func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else { return }
        
        let visibleRect = CGRect.init(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in assets.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in assets.object(at: indexPath.item) }
        
        imageManager.startCachingImages(for: addedAssets, targetSize: photoSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets, targetSize: photoSize, contentMode: .aspectFill, options: nil)
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY, width: new.width, height: new.maxY - old.maxY)]
            }
            
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY, width: new.width, height: old.minY - new.minY)]
            }
            
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY, width: new.width, height: old.maxY - new.maxY)]
            }
            
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY, width: new.width, height: new.minY - old.minY)]
            }
            
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    private func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
}

extension PhotoLibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return photoSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PhotoLibraryViewController: PHPhotoLibraryChangeObserver {
    // Observe updates in camera roll and updates this image picker if any asset is added/removed
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: assets) else { return }
        
        DispatchQueue.main.sync {
            assets = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath.init(item: $0, section: 0) }))
                    }
                    
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath.init(item: $0, section: 0) }))
                    }
                    
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath.init(item: $0, section: 0) }))
                    }
                    
                    changes.enumerateMoves({ (fromIndex, toIndex) in
                        collectionView.moveItem(at: IndexPath.init(item: fromIndex, section: 0), to: IndexPath.init(item: toIndex, section: 0))
                    })
                }, completion: nil)
            } else {
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map({ $0.indexPath })
    }
}
