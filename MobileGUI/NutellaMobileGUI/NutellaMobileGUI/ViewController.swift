//
//  ViewController.swift
//  NutellaMobileGUI
//
//  Created by Gianluca Venturini on 19/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import UIKit
import Nutella

class ViewController: UIViewController, NutellaNetDelegate, NutellaLocationDelegate {
    
    var nutella: Nutella?

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var runSegmentedControl: UISegmentedControl!
    @IBOutlet weak var brokerText: UITextField!
    @IBOutlet weak var brokerLabel: UILabel!
    @IBOutlet weak var appIdText: UITextField!
    @IBOutlet weak var runIdLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var habitatLabel: UILabel!
    @IBOutlet weak var yWallConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWall: UIImageView!
    
    @IBAction func startMonitoring(sender: AnyObject) {
        self.startButton.enabled = false
        self.brokerText.enabled = false
        self.appIdText.enabled = false
        
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        var runId = runSegmentedControl.titleForSegmentAtIndex(runSegmentedControl.selectedSegmentIndex)
        
        self.brokerLabel.text = self.brokerText.text
        self.runIdLabel.text = runId
        
        switch resourceId! {
            case "wallscope0":
                self.habitatLabel.text = "Habitat 1"
            case "wallscope1":
                self.habitatLabel.text = "Habitat 2"
            case "wallscope2":
                self.habitatLabel.text = "Habitat 3"
            case "wallscope3":
                self.habitatLabel.text = "Habitat 4"
            default:
                self.habitatLabel.text = "Error"
        }
        self.habitatLabel.alpha = 1;
        
        self.yWallConstraint.constant = 0
        self.view.setNeedsUpdateConstraints()
        UIView.animateWithDuration(1.0, animations: {
            self.view.layoutIfNeeded()
        })
        
        nutella = Nutella(brokerHostname: brokerText.text,
            appId: appIdText.text,
            runId: runId!,
            componentId: "test_component",
            netDelegate: self,
            locationDelegate: self)
        nutella?.resourceId = resourceId
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
    
    func ready() {
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        
        nutella?.location.resource[resourceId!]?.notifyEnter = true
        nutella?.location.resource[resourceId!]?.notifyEnter = false
        
        var table1 = nutella?.location.resource["Table1"]
        var discrete1 = nutella?.location.resource["discrete1"]
        var discrete = discrete1?.discrete
        var x = discrete?.x
        
        println(x)

        /*
        switch(x!) {
            case .Letter(let letter):
                println(letter)
            case .Number(let number):
                println(number)
        }
        */
    }

}

