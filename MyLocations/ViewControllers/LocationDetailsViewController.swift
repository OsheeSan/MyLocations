//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by admin on 11.01.2023.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    
    
    //MARK: - Variables adn consts
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    var locationToEdit: Location? {
      didSet {
        if let location = locationToEdit {
          descriptionText = location.locationDescription
          categoryName = location.category
          date = location.date
          coordinate = CLLocationCoordinate2DMake(
            location.latitude,
            location.longitude)
          placemark = location.placemark
        }
      }
    }
    var descriptionText = ""
    var image: UIImage?
    var observer: Any!
    
    //MARK: - Outlets
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var addPhotoLabel: UILabel!
    @IBOutlet var imageHeight: NSLayoutConstraint!
    @IBOutlet var imageWidth: NSLayoutConstraint!
    

    // MARK: - Actions
    @IBAction func done() {
        Vibration.success.vibrate()
        guard let mainView = navigationController?.parent?.view
        else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        
        
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        
        location.locationDescription = descriptionTextView.text
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
      location.date = date
      location.placemark = placemark
        // Save image
        if let image = image {
          // 1
          if !location.hasPhoto {
            location.photoID = Location.nextPhotoID() as NSNumber
          }
          // 2
          if let data = image.jpegData(compressionQuality: 0.5) {
            // 3
            do {
              try data.write(to: location.photoURL, options: .atomic)
            } catch {
              print("Error writing file: \(error)")
            }
          }
        }
      // 3
      do {
        try managedObjectContext.save()
          let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
          do {
              let results = try managedObjectContext.fetch(fetchRequest)
//              for result in results as! [Location]{
//                  managedObjectContext.delete(result)
//              }
              for result in results as! [Location]{
                  print("Date : \(result.date), cat : \(result.category)")
              }
          } catch {
              fatalCoreDataError(error)
          }
        afterDelay(0.6) {
          hudView.hide()
          self.navigationController?.popViewController(
            animated: true)
        }
      } catch {
        // 4
          fatalCoreDataError(error)
      }
    }

    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func categoryPickerDidPickCategory(
      _ segue: UIStoryboardSegue
    ) {
      let controller = segue.source as! CategoryPickerViewController
      categoryName = controller.selectedCategoryName
      categoryLabel.text = categoryName
    }
    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = locationToEdit{
            title = "Edit Location"
            if location.hasPhoto {
                if let theImage = location.photoImage {
                    show(image: theImage)
                }
            }
        }
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String(
            format: "%.8f",
            coordinate.latitude)
        longitudeLabel.text = String(
            format: "%.8f",
            coordinate.longitude)
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        dateLabel.text = format(date: date)
        // Hide keyboard
        let gestureRecognizer = UITapGestureRecognizer(
          target: self,
          action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        listenForBackgroundNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Vibration.selection.vibrate()
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        Vibration.selection.vibrate()
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    // MARK: - Table View Delegates
    override func tableView(
        _ tableView: UITableView,
        willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 0 {
            pickPhoto()
        }
            tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func listenForBackgroundNotification() {
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                
                if let weakSelf = self {
                    if weakSelf.presentedViewController != nil {
                        weakSelf.dismiss(animated: false, completion: nil)
                    }
                    weakSelf.descriptionTextView.resignFirstResponder()
                }
            }
    }
    deinit {
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer!)
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        imageHeight.constant = 260
        imageWidth.constant = 260
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        tableView.reloadData()
    }
    
    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        if let tmp = placemark.subThoroughfare {
            text += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
            text += tmp + ", "
        }
        if let tmp = placemark.locality {
            text += tmp + ", "
        }
        if let tmp = placemark.administrativeArea {
            text += tmp + " "
        }
        if let tmp = placemark.postalCode {
            text += tmp + ", "
        }
        if let tmp = placemark.country {
            text += tmp
        }
        return text
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @objc func hideKeyboard(
      _ gestureRecognizer: UIGestureRecognizer
    ) {
      let point = gestureRecognizer.location(in: tableView)
      let indexPath = tableView.indexPathForRow(at: point)

      if indexPath != nil && indexPath!.section == 0 &&
      indexPath!.row == 0 {
        return
      }
      descriptionTextView.resignFirstResponder()
    }
}
extension LocationDetailsViewController: UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
  // MARK: - Image Helper Methods
  func takePhotoWithCamera() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    present(imagePicker, animated: true, completion: nil)
  }
    // MARK: - Image Picker Delegates
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
      if let theImage = image {
        show(image: theImage)
      }
      dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(
      _ picker: UIImagePickerController
    ) {
      dismiss(animated: true, completion: nil)
    }
    func choosePhotoFromLibrary() {
      let imagePicker = UIImagePickerController()
      imagePicker.sourceType = .photoLibrary
      imagePicker.delegate = self
      imagePicker.allowsEditing = true
      present(imagePicker, animated: true, completion: nil)
    }
    
    func pickPhoto() {
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        showPhotoMenu()
      } else {
        choosePhotoFromLibrary()
      }
    }

    func showPhotoMenu() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      let alert = UIAlertController(
        title: nil,
        message: nil,
        preferredStyle: .actionSheet)

      let actCancel = UIAlertAction(
        title: "Cancel",
        style: .cancel,
        handler: nil)
      alert.addAction(actCancel)

      let actPhoto = UIAlertAction(
        title: "Take Photo",
        style: .default){_ in
            self.takePhotoWithCamera()
        }
      alert.addAction(actPhoto)

      let actLibrary = UIAlertAction(
        title: "Choose From Library",
        style: .default){_ in
            self.choosePhotoFromLibrary()
        }
      alert.addAction(actLibrary)

      present(alert, animated: true, completion: nil)
    }
}
