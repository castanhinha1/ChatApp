

import UIKit
import Parse
import FBSDKLoginKit
import GoogleMaps

class FeedTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    var messageID = [String]()
    var messages = [String]()
    var usernames = [String]()
    var users = [String: String]()
    var time = [String]()
    var newMessage: String = ""
    var messageCell: newMessageCell?
    
    var refresher: UIRefreshControl!
    var activityIndicator = UIActivityIndicatorView()
    var placesClient: GMSPlacesClient?
    var possiblePlaces: [String] = []
    
    @IBAction func composeMessage(sender: UIBarButtonItem) {

        self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
        
    }
    
    @IBAction func settings(sender: UIBarButtonItem) {
        
        //Move to settings Page
        print("settings button pressed")
        
        //possiblePlaces = ["bar", "amusement_park", "bakery", "book_store", "cafe", "casino", "gym", "movie_theater", "night_club", "park", "restaurant", "shopping_mall", "stadium", "university"]
        
        possiblePlaces = ["atm"]

        placesClient!.currentPlaceWithCallback({ (placeLikelihoods, error) -> Void in
            if error != nil {
                print("Current Place error: \(error!.localizedDescription)")
                return
            }
            
            for likelihood in placeLikelihoods!.likelihoods {
                if let likelihood = likelihood as? GMSPlaceLikelihood {
                    let place = likelihood.place
                    
                    for y in place.types {
                        for z in self.possiblePlaces {
                            if y == z {
                                
                                print("Current Place name \(place.name) at likelihood \(likelihood.likelihood)")
                                print("Current Place address \(place.formattedAddress)")
                                print(place.types)
                                
                            }
                            else {
                                print("no matches")
                            }
                        }
                    }
                    
                    
                    

                }
            }
        })
        
        
    }
    
    @IBAction func homeButton(sender: UIBarButtonItem) {
        
        //Move to home
        print(PFUser.currentUser()?.objectId)
        
    }
    
    @IBAction func composeButton(sender: UIBarButtonItem) {
        
        //Move to compose
        print("compose button pressed")
        
    }
    
    @IBAction func composeNewMessage(sender: UIBarButtonItem) {
        
        self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
        
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
                
                if newMessage != nil {
                
                post.saveInBackgroundWithBlock({ (success, error) in
                    
                    self.activityIndicator.stopAnimating()
                    
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    if error == nil {
                        
                        selectedCell.newMessage.text = ""
                        
                        self.getFeed(true)
                        
                        
                        
                    } else {
                        
                        self.displayAlert("Could not post image", message: "Please try again later")
                        
                    }
                    
                    
                })
                
                } else {
                    
                    self.messageCell!.sendButton.enabled = false
                    
                }
                
            }
        }

        
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient()
        
        let query = PFUser.query()
        
        query?.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            if let users = objects {
                
                self.messageID.removeAll(keepCapacity: false)
                self.messages.removeAll(keepCapacity: false)
                self.users.removeAll(keepCapacity: false)
                self.usernames.removeAll(keepCapacity: false)
                self.time.removeAll(keepCapacity: false)
                
                for object in users {
                    
                    if let user = object as? PFUser {
                        
                        self.users[user.objectId!] = user["firstName"]! as! String
                        
                    }
                }
            }
            
        }
        
        getFeed(false)
        
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        getFeed(true)
        
        
        
    }
    
    
    @IBAction func signOut(sender: UIBarButtonItem) {
        
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
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
                                self.messageID.append(object.objectId!)
                                self.messages.append(object["message"] as! String)
                                
                                if self.users.isEmpty == false {
                                
                                self.usernames.append(self.users[object["userId"] as! String]!)
                                
                                } else {
                                    
                                    print("users doesnt have anything in it.")
                                }
                                
                                self.tableView.reloadData()
                                
                            }
                            
                        } else {
                            
                            print(error)
                            
                        }
                        
                    })
                    
                    
                }
                
            }
            
        }
            
        } else if isReload == true {
            
            let query = PFUser.query()
            
            query?.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                
                if let users = objects {
                    
                    self.messageID.removeAll(keepCapacity: false)
                    self.messages.removeAll(keepCapacity: false)
                    self.users.removeAll(keepCapacity: false)
                    self.usernames.removeAll(keepCapacity: false)
                    self.time.removeAll(keepCapacity: false)
                    
                    for object in users {
                        
                        if let user = object as? PFUser {
                            
                            self.users[user.objectId!] = user["firstName"]! as! String
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
                                    self.messageID.append(object.objectId!)
                                    self.messages.append(object["message"] as! String)
                                    self.usernames.append(self.users[object["userId"] as! String]!)
                                    self.tableView.reloadData()
                                    self.refreshControl!.endRefreshing()
                                    
                                    
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
            
        } else if(h > 1 && h < 24) {
            
            self.time.append("\(Int(round(h))) hours ago.")
            
        } else if(h > 24 && h < 48) {
        
            self.time.append("1 day ago.")
            
        } else if(h > 48 && h < 72) {
          
            self.time.append("2 days ago.")
            
        } else if(h > 72 && h < 96) {
            
            self.time.append("3 days ago.")
            
        } else if(h > 96 && h < 120) {
            
            self.time.append("4 days ago.")
            
        } else if(h > 120 && h < 144) {
            
            self.time.append("5 days ago.")
            
        } else if(h > 144 && h < 168) {
            
            self.time.append("6 days ago.")
            
        } else if(h > 168 && h < 192) {
            
            self.time.append("1 week ago.")
            
        } else if(h > 384) {
            
            self.time.append("A Few Weeks ago.")
            
        } else if (h < 1) {
            
            if (round(m) <= 0) {
                
                self.time.append("1 minute ago.")
                
            } else {
            
            self.time.append("\(Int(round(m))) minutes ago.")
            
                //print(round(m))
                
            }
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
            
            messageCell = tableView.dequeueReusableCellWithIdentifier("newMessageCell", forIndexPath: indexPath) as? newMessageCell
            
            messageCell!.newMessage.delegate = self
            
            return messageCell!
            
        } else {
        
        let myCell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! cell
        
        myCell.username.text = usernames[indexPath.row-1]
        
        myCell.message.text = messages[indexPath.row-1]
        
        myCell.message.sizeToFit()
        
        myCell.time.text = time[indexPath.row-1]

        return myCell
            
        }
        
    }
    
    var valueToPassMessageId:String = ""
    var valueToPassUsername:String = ""
    var valueToPassTime:String = ""
    var valueToPassMessage:String = ""

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let indexPath = tableView.indexPathForSelectedRow!;
        
        valueToPassMessageId = messageID[indexPath.row-1]
        valueToPassUsername = usernames[indexPath.row-1]
        valueToPassTime = time[indexPath.row-1]
        valueToPassMessage = messages[indexPath.row-1]
        
        performSegueWithIdentifier("showDetail", sender: self)
        
        
    }
    
    
    
    // Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Commments View Controller
        if segue.identifier == "showDetail" {
            
            let vc = segue.destinationViewController as! CommentsTableViewController
            
            vc.messageId = valueToPassMessageId
            vc.originalMessage = valueToPassMessage
            vc.originalSender = valueToPassUsername
            vc.originalTime = valueToPassTime
            
            
        }
    }
 
 
    
    func displayAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        })))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
 
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        textField.returnKeyType = UIReturnKeyType.Send
        
        tableView.allowsSelection = false
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        tableView.allowsSelection = true
        
    }
    
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendNewMessage(self)
        return true
    }
    
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        
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
