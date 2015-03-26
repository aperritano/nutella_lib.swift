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
    @IBOutlet weak var textLabel: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    @IBAction func startMonitoring(sender: AnyObject) {
        self.startButton.enabled = false
        self.textLabel.enabled = false
        
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        
        
        nutella = Nutella(brokerHostname: textLabel.text, runId: "crepe", componentId: "test_component")
        nutella?.resourceId = resourceId
        nutella?.netDelegate = self
        nutella?.locationDelegate = self
    }
    @IBAction func ipadSelectionChanged(sender: AnyObject) {
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        nutella?.resourceId = resourceId
    }
    
    @IBAction func positionChanged(sender: AnyObject) {
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        if let stepper = sender as? UIStepper {
            let position = stepper.value
            nutella?.location.resource[resourceId!]?.continuous.x = position
            nutella?.location.resource[resourceId!]?.notifyUpdate = true
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
    
    func managedResourceUpdated(resource: NLManagedResource) {
        // Update resource
        println(resource.rid)
        println(resource.continuous.x)
        println(resource.continuous.y)
    }

}

