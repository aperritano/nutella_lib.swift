//
//  ViewController.swift
//  NutellaMobileGUI
//
//  Created by Gianluca Venturini on 19/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import UIKit
import Nutella

class ViewController: UIViewController, NutellaNetDelegate, NutellaLocationDelegate, UITableViewDataSource {
    
    var nutella: Nutella?

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var textLabel: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var parametersTableView: UITableView!
    
    @IBAction func startMonitoring(sender: AnyObject) {
        self.startButton.enabled = false
        self.textLabel.enabled = false
        
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        
        
        nutella = Nutella(brokerHostname: textLabel.text, appId: "crepe", runId: "default", componentId: "test_component")
        nutella?.resourceId = resourceId
        nutella?.netDelegate = self
        nutella?.locationDelegate = self
        
        nutella?.location.resource[resourceId!]?.notifyEnter = true
    }
    
    @IBAction func ipadSelectionChanged(sender: AnyObject) {
        nutella?.location.resource[nutella!.resourceId!]?.notifyUpdate = false
        nutella?.location.resource[nutella!.resourceId!]?.notifyEnter = false
        nutella?.location.resource[nutella!.resourceId!]?.notifyExit = false
        
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        
        nutella?.location.resource[resourceId!]?.notifyUpdate = true
        nutella?.location.resource[resourceId!]?.notifyEnter = true
        nutella?.location.resource[resourceId!]?.notifyExit = true
        
        nutella?.resourceId = resourceId
        if let x = nutella?.location.resource[resourceId!]?.continuous.x {
            self.stepper.value = x
        }
        parametersTableView.reloadData()
    }
    
    @IBAction func positionChanged(sender: AnyObject) {
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        if let stepper = sender as? UIStepper {
            let position = stepper.value
            nutella?.location.resource[resourceId!]?.continuous.x = position
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func responseReceived(channelName: String, requestName: String?, response: AnyObject) {
        println("Response received")
    }
    
    // MARK: NutellaLocationDelegate
    func resourceUpdated(resource: NLManagedResource) {
        // Update resource
        println(resource.rid)
        println(resource.continuous.x)
        println(resource.continuous.y)
        parametersTableView.reloadData()
    }
    
    func resourceEntered(dynamicResource: NLManagedResource, staticResource: NLManagedResource) {
        println("---- ENTER ----")
        println(dynamicResource.rid)
        println(staticResource.rid)
    }
    
    func resourceExited(dynamicResource: NLManagedResource, staticResource: NLManagedResource) {
        println("---- EXIT ----")
        println(dynamicResource.rid)
        println(staticResource.rid)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("ciao") as? UITableViewCell
        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ciao")
            
        }
        if tableView.tag == 1 {
            let key = self.nutella!.location.resource[self.nutella!.resourceId!]!.parameters[indexPath.row]
            let value = self.nutella!.location.resource[self.nutella!.resourceId!]!.parameter[key]!
            cell!.textLabel?.text = key + ":" + value
        }
        return cell!

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            if let numParam = self.nutella?.location.resource[self.nutella!.resourceId!]?.parameters.count {
                return numParam
            }
            return 0
        }
        else if tableView.tag == 2 {
            return 0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView.tag == 1 {
            return "Property"
        }
        else if tableView.tag == 2 {
            return "Dynamic resources"
        }
        return "Table"
    }

}

