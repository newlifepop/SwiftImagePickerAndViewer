//
//  ModalView.swift
//  nearbie
//
//  Created by Changyu Wu on 5/8/18.
//  Copyright © 2018 Changyu Wu. All rights reserved.
//

import UIKit

class ModalView: NSObject {
    private var modalView: UIView!
    
    override init() {
        super.init()
    }
    
    func showModal(message: String) {
        if let window = UIApplication.shared.keyWindow {
            modalView = UIView.init(frame: window.bounds)
            modalView.backgroundColor = UIColor.init(white: 0, alpha: 0.75)
            modalView.alpha = 0
            
            let indicator = UIActivityIndicatorView.init(frame: .init(x: 0, y: 0, width: 16, height: 16))
            indicator.startAnimating()
            
            let messageLabel = UILabel.init(frame: .init(x: indicator.frame.maxX + 20, y: indicator.frame.origin.y, width: 0, height: 0))
            messageLabel.text = message
            messageLabel.textColor = UIColor.white
            messageLabel.font = UIFont.systemFont(ofSize: 16)
            messageLabel.sizeToFit()
            
            let contentContainer = UIView.init(frame: .init(x: 0, y: 0, width: messageLabel.frame.maxX - indicator.frame.minX, height: messageLabel.frame.height))
            contentContainer.addSubview(indicator)
            contentContainer.addSubview(messageLabel)
            
            let panelWidth = contentContainer.frame.width + 40
            let panelHeight = contentContainer.frame.height + 40
            let panel = UIView.init(frame: .init(x: (modalView.frame.width - panelWidth) / 2, y: (modalView.frame.height - panelHeight) / 2, width: panelWidth, height: panelHeight))
            panel.backgroundColor = UIColor.black
            panel.layer.cornerRadius = 10
            contentContainer.frame.origin.x = (panel.frame.width - contentContainer.frame.width) / 2
            contentContainer.frame.origin.y = (panel.frame.height - contentContainer.frame.height) / 2
            panel.addSubview(contentContainer)
            panel.layer.shadowColor = UIColor.black.cgColor
            panel.layer.shadowOffset = .init(width: 0, height: 5)
            panel.layer.shadowRadius = 10
            panel.layer.shadowOpacity = 0.35
            
            modalView.addSubview(panel)
            window.addSubview(modalView)
            UIView.animate(withDuration: 0.25, animations: { self.modalView.alpha = 1 })
        }
    }
    
    func dismissModal() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.modalView.alpha = 0 },
            completion: { (_) in self.modalView.removeFromSuperview() }
        )
    }
}
