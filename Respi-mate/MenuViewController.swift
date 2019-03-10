//
//  ViewController.swift
//  Respi-mate
//
//  Created by Aishwarya Pattar on 09/03/2019.
//  Copyright © 2019 Aishwarya Pattar. All rights reserved.
//

import UIKit
import CoreBluetooth

var values: [Double] = []

class MenuViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet weak var RRlabel: UILabel!
    @IBAction func historyButton(_ sender: Any) {
        performSegue(withIdentifier: "historyVC", sender: self)
    }
    
    
    
    // variables
    var centralManager: CBCentralManager!
    var bluefruitPeripheral: CBPeripheral!
    var txCharacteristic : CBCharacteristic?
    var rxCharacteristic : CBCharacteristic?
    var characteristicASCIIValue = NSString()
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var historyController = segue.destination as! HistoryViewController
        historyController.myY = values
    }
    
    override func viewDidLoad() {
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        super.viewDidLoad()
        
        // initialise label of RR peak to be empty
        RRlabel.text = " "
    }
}


extension MenuViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        bluefruitPeripheral = peripheral
        bluefruitPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        bluefruitPeripheral.discoverServices(nil)
    }
}


extension MenuViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            //print(service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        //print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                //print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                //print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                characteristicASCIIValue = ASCIIstring
                //print("Value Recieved: \((characteristicASCIIValue as String))")
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            }
        }
        
        // convert string input from Rx to Double array
        let val = characteristicASCIIValue.doubleValue
        values.append(val)
        //print(values)
    }
}
