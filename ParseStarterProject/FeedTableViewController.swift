//
//  FeedTableViewController.swift
//  ParseStarterProject
//
//  Created by Rob Percival on 19/05/2015.
//  Copyright (c) 2015 Parse. All rights reserved.
//

import UIKit
import Parse

class FeedTableViewController: UITableViewController {
    
    var messages = [String]()
    var usernames = [String]()
    var users = [String: String]()
    var time = [String]()
    var newMessage: String = ""
    
    var refresher: UIRefreshControl!
    var activityIndicator = UIActivityIndicatorView()
    
    @IBAction func composeMessage(sender: UIBarButtonItem) {

        tableView.setContentOffset(CGPointZero, animated: true)
        
    }
    
    @IBAction func settings(sender: UIBarButtonItem) {
        
        //Move to settings Page
        print("settings button pressed")
        
        
    }
    
    @IBAction func homeButton(sender: UIBarButtonItem) {
        
        //Move to home
        print("homebutton pressed")
        
    }
    
    @IBAction func composeButton(sender: UIBarButtonItem) {
        
        //Move to compose
        print("compose button pressed")
        
    }
    
    @IBAction func sendNewMessage(sender: AnyObject) {
        
        let indexPath = NSIndexPath(forRow: 0, inSection: 0) // This defines what indexPath is which is used later to define a cell
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath) as! newMessageCell
        
        let newMessage = selectedCell.newMessage.text //textFied is your textfield name.
        
        // Send "newMessage" to parse and update table view
        
        activityIndicator = UIActivityIndicatorView(frame: self.view.frame)
        activityIndicator.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        PFGeoPoint.geoPointForCurrentLocationInBackground { (geopoint, error) in
            
            if let geopoint = geopoint {
                
                let post = PFObject(className: "Message")
                post["message"] = newMessage
                post["userId"] = PFUser.currentUser()!.objectId!
                post["location"] = geopoint
                let date = NSDate()
                post["date"] = date
                
                
                post.saveInBackgroundWithBlock({ (success, error) in
                    
                    self.activityIndicator.stopAnimating()
                    
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    if error == nil {
                        
                        //self.displayAlert("Success!", message: "Posted!")
                        
                        selectedCell.newMessage.text = ""
                        
                        self.reloadData()
                        
                        
                    } else {
                        
                        self.displayAlert("Could not post image", message: "Please try again later")
                        
                    }
                    
                    
                })
                
                
                
            }
        }

        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        let query = PFUser.query()
        
        query?.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if let users = objects {
                
                self.messages.removeAll(keepCapacity: true)
                self.users.removeAll(keepCapacity: true)
                self.usernames.removeAll(keepCapacity: true)
                self.time.removeAll(keepCapacity: true)
                
                for object in users {
                    
                    if let user = object as? PFUser {
                        
                        self.users[user.objectId!] = user.username!
                        
                    }
                }
            }
            
        }
        
        getFeed(false)
        
        refresher = UIRefreshControl()
        
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        
        refresher.addTarget(self, action: #selector(FeedTableViewController.reloadData), forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.addSubview(refresher)
        
        
    }
    
    func reloadData() {
        
        getFeed(true)
        
    }
    
    
    @IBAction func signOut(sender: UIBarButtonItem) {
        
        PFUser.logOut()
        let Login = storyboard!.instantiateViewControllerWithIdentifier("ViewController")
        self.presentViewController(Login, animated: true, completion: nil)
        
    }
    
    func getFeed(isReload: Bool) {
        
        if isReload == false {
        
        PFGeoPoint.geoPointForCurrentLocationInBackground { (geopoint, error) in
            
            if error == nil {
                
                if let geoPoint = geopoint {
                    
                    let query = PFQuery(className: "Message")
                    query.whereKey("location", nearGeoPoint: geoPoint, withinMiles: 30)
                    query.limit = 100
                    query.addDescendingOrder("createdAt")
                    
                    query.findObjectsInBackgroundWithBlock({ (objects, error) in
                        
                        if let objects = objects {
                            
                            for object in objects {
                        
                                
                                self.hoursSince(object.createdAt!)
                                self.messages.append(object["message"] as! String)
                                self.usernames.append(self.users[object["userId"] as! String]!)
                                self.tableView.reloadData()
                                
                            }
                            
                        }
                        
                    })
                    
                    
                }
                
            }
            
        }
            
        } else if isReload == true {
            
            let query = PFUser.query()
            
            query?.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                
                if let users = objects {
                    
                    self.messages.removeAll(keepCapacity: true)
                    self.users.removeAll(keepCapacity: true)
                    self.usernames.removeAll(keepCapacity: true)
                    self.time.removeAll(keepCapacity: true)
                    
                    for object in users {
                        
                        if let user = object as? PFUser {
                            
                            self.users[user.objectId!] = user.username!
                            
                        }
                    }
                }
                
            }
         
            PFGeoPoint.geoPointForCurrentLocationInBackground { (geopoint, error) in
                
                if error == nil {
                    
                    if let geoPoint = geopoint {
                        
                        let query = PFQuery(className: "Message")
                        query.whereKey("location", nearGeoPoint: geoPoint, withinMiles: 30)
                        query.limit = 100
                        query.addDescendingOrder("createdAt")
                        
                        query.findObjectsInBackgroundWithBlock({ (objects, error) in
                            
                            if let objects = objects {
                                
                                for object in objects {
                                    
                                    
                                    self.hoursSince(object.createdAt!)
                                    self.messages.append(object["message"] as! String)
                                    self.usernames.append(self.users[object["userId"] as! String]!)
                                    self.tableView.reloadData()
                                    self.refresher.endRefreshing()
                                    
                                }
                                
                            }
                            
                        })
                        
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func hoursSince(newDate: NSDate) {

        let interval = round(NSDate().timeIntervalSinceDate(newDate))
        
        let (h,m,_) = secondsToHoursMinutesSeconds(interval)
        
        if(round(h) == 1.0) {
            
            self.time.append("\(Int(round(h))) hour ago.")
            
        } else if(h > 1) {
            
            self.time.append("\(Int(round(h))) hours ago.")
            
        } else if (h < 1) {
            
            self.time.append("\(Int(round(m))) minutes ago.")
            
        }

        
    }
    
    func secondsToHoursMinutesSeconds (seconds : Double) -> (Double, Double, Double) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return usernames.count+1
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            
            let messageCell = tableView.dequeueReusableCellWithIdentifier("newMessageCell", forIndexPath: indexPath) as! newMessageCell
            
            return messageCell
            
        } else {
        
        let myCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! cell
        
        myCell.username.text = usernames[indexPath.row-1]
        
        myCell.message.text = messages[indexPath.row-1]
        
        myCell.message.sizeToFit()
        
        myCell.time.text = time[indexPath.row-1]
            
        //print(messages.count)

        return myCell
            
        }
        
    }
    
    func displayAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        })))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
 
    
}



    extension UIViewController {
        func hideKeyboardWhenTappedAround() {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
            view.addGestureRecognizer(tap)
        }
        
        func dismissKeyboard() {
            view.endEditing(true)
        }
}
