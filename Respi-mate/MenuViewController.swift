//
//  ViewController.swift
//  Respi-mate
//
//  Created by Aishwarya Pattar on 09/03/2019.
//  Copyright © 2019 Aishwarya Pattar. All rights reserved.
//

import UIKit
import CoreBluetooth


class MenuViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet weak var RRlabel: UILabel!
    

    // variables
    var centralManager: CBCentralManager!
    var bluefruitPeripheral: CBPeripheral!
    var txCharacteristic : CBCharacteristic?
    var rxCharacteristic : CBCharacteristic?
    var characteristicASCIIValue = NSString()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialise label of RR peak to be empty
        RRlabel.text = " "
        
    }


}

