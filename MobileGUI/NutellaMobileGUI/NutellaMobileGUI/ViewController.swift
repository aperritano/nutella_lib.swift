//
//  ViewController.swift
//  NutellaMobileGUI
//
//  Created by Gianluca Venturini on 19/01/15.
//  Copyright (c) 2015 Gianluca Venturini. All rights reserved.
//

import UIKit
import Nutella

class ViewController: UIViewController, NutellaNetDelegate {
    
    var nutella: Nutella?

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var textLabel: UITextField!
    
    @IBAction func startMonitoring(sender: AnyObject) {
        var resourceId = segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex)
        
        
        nutella = Nutella(brokerHostname: textLabel.text, runId: "crepe", componentId: "test_component")
        nutella?.resourceId = resourceId
        nutella?.netDelegate = self
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

}

