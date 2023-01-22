//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by admin on 11.01.2023.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    
    var selectedCategoryName = ""
    
    let categories = [
        "No Category",
        "Apple Store",
        "Bar",
        "Bookstore",
        "Club",
        "Grocery Store",
        "Historic Building",
        "House",
        "Icecream Vendor",
        "Landmark",
        "Park"
    ]
    
    // MARK: - Variables and consts
    var selectedIndexPath = IndexPath()
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<categories.count {
            if categories[i] == selectedCategoryName {
                selectedIndexPath = IndexPath(row: i, section: 0)
                break
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(
        for segue: UIStoryboardSegue,
        sender: Any?
    ) {
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPath(for: cell) {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    
    // MARK: - Table View Delegates
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return categories.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)
        
        configureText(for: cell, at: indexPath)
        configureCheckmark(for: cell, at: indexPath)
        
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        Vibration.selection.vibrate()
        if indexPath.row != selectedIndexPath.row {
            selectedIndexPath = indexPath
        }
    }
    
    //MARK: - Helper methods
    func configureCheckmark(
        for cell: UITableViewCell, at index: IndexPath
    ) {
        let checkedIconView = cell.viewWithTag(1001) as! UIImageView
        if index == selectedIndexPath {
            checkedIconView.isHidden = false
        } else {
            checkedIconView.isHidden = true
        }
    }
    
    func configureText(
        for cell: UITableViewCell, at index: IndexPath
    ) {
      let label = cell.viewWithTag(1000) as! UILabel
        label.text = categories[index.row]
    }
}

