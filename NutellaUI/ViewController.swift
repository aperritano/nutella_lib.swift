//
//  ViewController.swift
//  NutellaUI
//
//  Created by Anthony Perritano on 6/22/16.
//  Copyright © 2016 ltg.evl.uic.edu. All rights reserved.
//

import UIKit
import Nutella

class ViewController: UIViewController {
    
    var nutella: Nutella?
    
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var reloadButton: UIButton!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nutellaSetup()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func nutellaSetup() {
        
        
        self.nutella = Nutella(brokerHostname: "localhost",
                               appId: "wallcology",
                               runId: "default",
                               componentId: "test_component")
        self.nutella?.netDelegate = self
        self.nutella?.resourceId = "hello"
       // self.nutella?.net.subscribe("echo_out")
        
        
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        //            // ... do any setup ...
        //
        //
        //
        //
        //        })
        //
        
        
    }
    
    @IBAction func publishMessageToNutella(_ sender: UIButton){
        if let message = messageTextField.text {
            outputTextView.text = outputTextView.text + " SENT: " + message + "TIMESTAMP: \(Date()) \n"
            
            if let nutella = nutella {
                
                let block = DispatchWorkItem {
                    var m = "Hello Major Tom, are you receiving this? Turn the thrusters on, we're standing by"
                    var dict = [String:String]()
                    dict["group"] = "1"
                    
                    nutella.net.asyncRequest("all_notes_with_group", message: dict as AnyObject, requestName: "all_notes_with_group")
                    //nutella.net.publish("all_notes", message: dict as AnyObject)
                }
                
                DispatchQueue.main.async(execute: block)
                
            }
            
            
        }
        
    }
    
    @IBAction func reloadAction(_ sender: UIButton) {
        nutellaSetup()
    }
    
}

extension ViewController: NutellaNetDelegate {
    
    /**
     Called when a message is received from a publish.
     
     - parameter channel: The name of the Nutella chennal on which the message is received.
     - parameter message: The message.
     - parameter from: The actor name of the client that sent the message.
     */
    func messageReceived(_ channel: String, message: AnyObject, componentId: String?, resourceId: String?) {
        print("messageReceived \(channel) message: \(message) componentId: \(componentId) resourceId: \(resourceId)")
    }
    
    /**
     A response to a previos request is received.
     
     - parameter channelName: The Nutella channel on which the message is received.
     - parameter requestName: The optional name of request.
     - parameter response: The dictionary/array/string containing the JSON representation.
     */
    func responseReceived(_ channelName: String, requestName: String?, response: AnyObject) {
        print("responseReceived \(channelName) requestName: \(requestName) response: \(response)")
        
    }
    
    /**
     A request is received on a Nutella channel that was previously handled (with the handleRequest).
     
     - parameter channelName: The name of the Nutella chennal on which the request is received.
     - parameter request: The dictionary/array/string containing the JSON representation of the request.
     */
    func requestReceived(_ channelName: String, request: AnyObject?, componentId: String?, resourceId: String?) -> AnyObject? {
        print("responseReceived \(channelName) request: \(request) componentId: \(componentId)")
        return nil
    }
}

extension ViewController: NutellaLocationDelegate {
    func resourceUpdated(_ resource: NLManagedResource) {
        
    }
    func resourceEntered(_ dynamicResource: NLManagedResource, staticResource: NLManagedResource) {
        
    }
    func resourceExited(_ dynamicResource: NLManagedResource, staticResource: NLManagedResource) {
        
    }
    
    func ready() {
        print("NutellaLocationDelegate:READY")
        //self.nutella?.net.subscribe("echo_out")
        //    })
        
        //        if let nutella = self.nutella {
        //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        //                // ... do any setup ...
        //            nutella.net.subscribe("echo_out")            })
        //
        //        }
        
    }
}

