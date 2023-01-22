//
//  LocationCell.swift
//  MyLocations
//
//  Created by admin on 17.01.2023.
//

import UIKit

class LocationCell: UITableViewCell {
    
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var addressLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Helper Method
    func configure(for location: Location) {
      if location.locationDescription.isEmpty {
        descriptionLabel.text = "(No Description)"
      } else {
        descriptionLabel.text = location.locationDescription
      }

      if let placemark = location.placemark {
        var text = ""
        if let tmp = placemark.subThoroughfare {
          text += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
          text += tmp + ", "
        }
        if let tmp = placemark.locality {
          text += tmp
        }
        addressLabel.text = text
      } else {
        addressLabel.text = String(
          format: "Lat: %.8f, Long: %.8f",
          location.latitude,
          location.longitude)
      }
        photoImageView.layer.cornerRadius = 13
        photoImageView.image = thumbnail(for: location)
        photoImageView.tintColor = UIColor(ciColor: .gray)
        photoImageView.layer.borderWidth = 1
        photoImageView.layer.borderColor = CGColor(gray: 0.5, alpha: 1)
    }

    func thumbnail(for location: Location) -> UIImage? {
      if location.hasPhoto, let image = location.photoImage {
        return image
      }
      return UIImage(systemName: "questionmark")
    }
}
