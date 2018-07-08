//
//  ViewController.swift
//  MemeEditorV1
//
//  Created by Jessica Mallian on 7/6/18.
//  Copyright © 2018 Jessica Mallian. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    //MARK: outlets
    @IBOutlet weak var takePictureButton: UIBarButtonItem!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var displayImage: UIImageView!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    @IBOutlet weak var topToolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    //MARK: attritubtes for text fields
    let memeTextAttributes: [String: Any] = [
        NSAttributedStringKey.strokeColor.rawValue: UIColor.black,
        NSAttributedStringKey.foregroundColor.rawValue: UIColor.white,
        NSAttributedStringKey.font.rawValue: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedStringKey.strokeWidth.rawValue: -3
    ]
    
    //MARK: lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        //share button is disabled till user picks a photo to meme
        shareButton.isEnabled = false
        
        bottomTextField.delegate = self
        topTextField.delegate = self
        bottomTextField.defaultTextAttributes = memeTextAttributes
        topTextField.defaultTextAttributes = memeTextAttributes
        bottomTextField.backgroundColor = .clear
        topTextField.backgroundColor = .clear
        bottomTextField.autocapitalizationType = .allCharacters
        topTextField.autocapitalizationType = .allCharacters
        bottomTextField.textAlignment = .center
        topTextField.textAlignment = .center
        bottomTextField.text = "BOTTOM"
        topTextField.text = "TOP"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        takePictureButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        //wnat to know when keyboard will appear in order to move the view up so the appearance of the keyboard doesn't cover the bottom textfield
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }

    //MARK storyboard actions
    @IBAction func albumButtonSelected(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .photoLibrary
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonSelected(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .camera
        present(pickerController, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonSelected(_ sender: Any) {
        //generate a memed image
        let memedImage = generateMemedImage()
        
        //define an instance of the ActivityViewController and pass it a meme as an activity item
        let controller = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        //present the ActivityViewController
        present(controller, animated: true, completion: nil)
        
        controller.completionWithItemsHandler = {
            (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            
            self.save()
        }
    }
    
    @IBAction func cancelButtonSelected(_ sender: Any) {
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        displayImage.image = nil        
    }
    
    //MARK UITextField delegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    //MARK UIImagePickerController delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            displayImage.image = image
            displayImage.contentMode = .scaleAspectFit
            //only want share button to be enabled after user selects a picture
            shareButton.isEnabled = true
            print("enable share button")
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("user canceled")
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: keyboard notification methods
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        //only want to move view if the bottom text field is being edited, not the top since the keyboard only blocks the bottom textfield
        print("keyboard will show called")
        if bottomTextField.isFirstResponder {
            print("bottom textfield is first responsder")
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    //MARK: meme methods
    func generateMemedImage() -> UIImage {
        //hide toolbars
        topToolBar.isHidden = true
        bottomToolBar.isHidden = true
        
        //render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //show toolbars
        topToolBar.isHidden = false
        bottomToolBar.isHidden = false
        
        return memedImage
    }
    
    func save() {
        let memedImage = generateMemedImage()
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, picture: displayImage.image!, memedImage: memedImage)
        
        //save meme in array created in AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.memeArray.append(meme)

    }
}

