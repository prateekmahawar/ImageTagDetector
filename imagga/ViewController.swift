//
//  ViewController.swift
//  imagga
//
//  Created by Prateek Mahawar on 21/08/16.
//  Copyright © 2016 Prateek Mahawar. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
  
    let imagePicker = UIImagePickerController()
    var selectedPhoto : UIImage!
    var tags = [String]()
    var colors = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.hidden = true
        activityIndicatorView.hidden = true
        
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        imgView.image = nil
    }
    

    @IBAction func selectImageBtnPressed(sender: AnyObject) {
        self.imagePicker.delegate = self
        self.imagePicker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            self.imagePicker.sourceType = .Camera
        } else {
            self.imagePicker.sourceType = .PhotoLibrary
        }
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        selectedPhoto = info[UIImagePickerControllerEditedImage] as? UIImage
        self.imgView.image = selectedPhoto
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {

        picker.dismissViewControllerAnimated(true, completion: nil)

    }
    
    @IBAction func submitBtnPressed(sender: AnyObject) {
        if imgView.image == nil {
            print("No Image Selected")
        } else {
            let image = imgView.image
            progressView.progress = 0.0
            progressView.hidden = false
            activityIndicatorView.hidden = false
            activityIndicatorView.startAnimating()
            view.userInteractionEnabled = false
            uploadImage(image!, progress: { [unowned self] percent in
                self.progressView.setProgress(percent, animated: true)
                }, completion: { [unowned self] tags, colors in
                    
                    
                    self.progressView.hidden = true
                    self.activityIndicatorView.hidden = true
                    self.activityIndicatorView.stopAnimating()
                    self.view.userInteractionEnabled = true
                    self.tags = tags
                    self.colors = colors
                   
                 
                    self.performSegueWithIdentifier("DetailsFile", sender: tags)
            })
        }
        
    }
    func uploadImage(image: UIImage, progress: (percent:Float) -> Void, completion:(tags:[String], colors: [String]) -> Void) {
        
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            print("Image can't be converted")
            return
        }
        Alamofire.upload(.POST,
                         "http://api.imagga.com/v1/content",
                         headers: ["Authorization": "Basic YWNjXzk2MDZkNjhkNTY2MjhkMDoyNTQxNDJmYTMwMWE0ODRjNWJmMzdkZTlhOTdmZDlmNA=="],
                         multipartFormData: { multipartFormData in
                            multipartFormData.appendBodyPart(data: imageData, name: "imageFile",
                            fileName: "image.jpg", mimeType: "image/jpeg")
                        },
                         
                         encodingCompletion: { encodingResult in
                            
                            switch encodingResult {
                            case .Success(let upload, _, _):
                                upload.progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        let percent = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
                                        progress(percent: percent)
                                    }
                                }
                                upload.validate()
                                upload.responseJSON { response in
                                 
                                    guard response.result.isSuccess else {
                                        print("Error while uploading file: \(response.result.error)")
                                        completion(tags: [String](), colors: [String]())
                                        return
                                    }
                                    
                                    guard let responseJSON = response.result.value as? [String: AnyObject],
                                        uploadedFiles = responseJSON["uploaded"] as? [AnyObject],
                                        firstFile = uploadedFiles.first as? [String: AnyObject],
                                        firstFileID = firstFile["id"] as? String else {
                                            print("Invalid information received from service")
                                            completion(tags: [String](), colors: [String]())
                                            return
                                    }
                                    
                                    print("Content uploaded with ID: \(firstFileID)")
                                    
                                    self.downloadTags(firstFileID) { tags in
                                        completion(tags: tags, colors: [String]())
                                        
                                    }
                                }
                            case .Failure(let encodingError):
                                print(encodingError)
                            }
        })
    }
    func downloadTags(contentID: String, completion: ([String]) -> Void) {
        Alamofire.request(
            .GET,
            "http://api.imagga.com/v1/tagging",
            parameters: ["content": contentID],
            headers: ["Authorization" : "Basic YWNjXzk2MDZkNjhkNTY2MjhkMDoyNTQxNDJmYTMwMWE0ODRjNWJmMzdkZTlhOTdmZDlmNA=="]
            )
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("Error while fetching tags: \(response.result.error)")
                    completion([String]())
                    return
                }
                guard let responseJSON = response.result.value as? [String: AnyObject],
                    results = responseJSON["results"] as? [AnyObject],
                    firstResult = results.first,
                    tagsAndConfidences = firstResult["tags"] as? [[String: AnyObject]] else {
                        print("Invalid tag information received from the service")
                        completion([String]())
                        return
                }
                let tags = tagsAndConfidences.flatMap({ dict in
                    return dict["tag"] as? String
                })
                
              
                completion(tags)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DetailsFile" {
            if let detailsVC = segue.destinationViewController as? TagsTVC {
                if let details = sender as? [String] {
                    detailsVC.tags = details
                }
            }
        }
    }
    
}

