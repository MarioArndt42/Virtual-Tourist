//
//  UIViewController+Extensions.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import UIKit

extension UIViewController {
    
    // Alert controller
    func showAlert(message: String, title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true)
    }
}
