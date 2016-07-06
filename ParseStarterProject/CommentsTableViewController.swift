//
//  CommentsTableViewController.swift
//  ParseStarterProject
//
//  Created by Dylan Castanhinha on 6/23/16.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse


class CommentsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate{
    
    var messages = [String]()
    var commentSender = [String]()
    var commentTime = [String]()
    
    
    var originalMessage: String = ""
    var originalSender: String = ""
    var originalTime: String = ""
    var messageId: String?
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var newComment: UITextField!
    
    func loadComments() {
        
        messages.removeAll()
        commentSender.removeAll()
        commentTime.removeAll()
        
        let query = PFQuery(className: "Comment")
        query.whereKey("messageId", equalTo: messageId!)
        query.limit = 100
        query.addDescendingOrder("createdAt")
        
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            
            if let objects = objects {
                
                for object in objects {
                    
                    //Add Comments to Array
                    
                    self.messages.append(object["message"] as! String)
                    
                    self.commentSender.append((PFUser.currentUser()?.objectForKey("firstName"))! as! String)
                    
                    self.tableView.reloadData()
                    
                    
                    
                }
                
            } else {
                
                print(error)
                
            }

        
        }
        
    }
    
    @IBAction func sendComment(sender: AnyObject) {
    
        let comment = PFObject(className:"Comment")
        comment["createdBy"] = PFUser.currentUser()
        comment["messageId"] = messageId
        comment["message"] = newComment.text
        
        comment.saveInBackgroundWithBlock({ (success, error) in
            
            if error == nil {
                
                print("Comment Saved")
                
            } else {
                
                print("Comment did not save")
                
            }
            
            
        })
        loadComments()
        self.tableView.reloadData()
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 89
        tableView.rowHeight = UITableViewAutomaticDimension
        
        loadComments()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count+1
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.row == 0 {
            
            let messageCell = tableView.dequeueReusableCellWithIdentifier("message", forIndexPath: indexPath) as? message
            
            messageCell?.user.text = originalSender
            messageCell?.originalMessage.text = originalMessage
            messageCell?.time.text = originalTime
            
            return messageCell!
            
        } else {
        
            let commentCell = tableView.dequeueReusableCellWithIdentifier("comment", forIndexPath: indexPath) as! comment
            
            commentCell.comment.text = messages[indexPath.row-1]
            commentCell.User.text = commentSender[indexPath.row-1]
            commentCell.time.text = "12:30"
            
            return commentCell
            
        }
        
    }

    override func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    override func dismissKeyboard() {
        view.endEditing(true)
    }
    
    

}
