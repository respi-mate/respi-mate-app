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
var flag = 0
var temp: [Double] = []

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
    
    
    override func viewDidLoad() {
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        super.viewDidLoad()
        
        // initialise label of RR peak to be empty
        RRlabel.text = "18"
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        var historyController = segue.destination as! HistoryViewController
        historyController.myY = values
    }
    
    
    func procesData() {
        while temp.count < 199 {
            
        }
        
        //temp.removeAll()
        flag = 0
        
        let (signals,avgFilter,stdFilter) = ThresholdingAlgo(y: temp, lag: 90, threshold: 1.3, influence: 1)
        
        var indx: [Int] = []
        indx.append(0)
        
        for i in 1...signals.count - 1 {
            if (signals[i] + signals[i - 1] == 1) && signals[i - 1] == 0 {
                if (i - indx.last!) > 50 {
                    indx.append(i)
                }
            }
        }
        //print(indx)
        
        var freq: [Double] = []
        
        for i in 1...indx.count - 1 {
            let temp = Double(indx[i] - indx[i - 1])
            freq.append(60/(temp * 0.2))
        }
        
        var avg_freq = 0.0
        
        for i in 0...freq.count - 1 {
            avg_freq = avg_freq + freq[i]
        }
        avg_freq = avg_freq / Double(freq.count)
        RRlabel.text = String(avg_freq)
        
    }
    
    // Function to calculate the arithmetic mean
    func arithmeticMean(array: [Double]) -> Double {
        var total: Double = 0
        for number in array {
            total += number
        }
        return total / Double(array.count)
    }
    
    // Function to calculate the standard deviation
    func standardDeviation(array: [Double]) -> Double
    {
        let length = Double(array.count)
        let avg = array.reduce(0, {$0 + $1}) / length
        let sumOfSquaredAvgDiff = array.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        return sqrt(sumOfSquaredAvgDiff / length)
    }
    
    // Function to extract some range from an array
    func subArray<T>(array: [T], s: Int, e: Int) -> [T] {
        if e > array.count {
            return []
        }
        return Array(array[s..<min(e, array.count)])
    }

    // Smooth z-score thresholding filter
    func ThresholdingAlgo(y: [Double],lag: Int,threshold: Double,influence: Double) -> ([Int],[Double],[Double]) {
        
        // Create arrays
        var signals   = Array(repeating: 0, count: y.count)
        var filteredY = Array(repeating: 0.0, count: y.count)
        var avgFilter = Array(repeating: 0.0, count: y.count)
        var stdFilter = Array(repeating: 0.0, count: y.count)
        
        // Initialise variables
        for i in 0...lag-1 {
            signals[i] = 0
            filteredY[i] = y[i]
        }
        
        // Start filter
        avgFilter[lag-1] = arithmeticMean(array: subArray(array: y, s: 0, e: lag-1))
        stdFilter[lag-1] = standardDeviation(array: subArray(array: y, s: 0, e: lag-1))
        
        for i in lag...y.count-1 {
            if abs(y[i] - avgFilter[i-1]) > threshold*stdFilter[i-1] {
                if y[i] > avgFilter[i-1] {
                    signals[i] = 1      // Positive signal
                } else {
                    // Negative signals are turned off for this application
                    //signals[i] = -1       // Negative signal
                }
                filteredY[i] = influence*y[i] + (1-influence)*filteredY[i-1]
            } else {
                signals[i] = 0          // No signal
                filteredY[i] = y[i]
            }
            // Adjust the filters
            avgFilter[i] = arithmeticMean(array: subArray(array: filteredY, s: i-lag, e: i))
            stdFilter[i] = standardDeviation(array: subArray(array: filteredY, s: i-lag, e: i))
        }
        
        return (signals,avgFilter,stdFilter)
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
        if flag < 200 {
            temp.append(val)
            flag  = flag + 1
        }
        //print(temp)
    }
}
