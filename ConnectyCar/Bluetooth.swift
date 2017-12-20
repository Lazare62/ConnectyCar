//
//  Bluetooth.swift
//  ConnectyCar
//
//  Created by Remy Krysztofiak on 18/11/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import Foundation
import CoreBluetooth

class Bluetooth: NSObject {
    
    
    var manager:CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var bleCharacteristic:CBCharacteristic?
    
    var deviceName : String
    var serviceUUID = CBUUID(string: "FFE0")
    var charUUID = CBUUID(string: "FFE1")
    
    init(deviceName: String, service: String, char: String) {
        
        self.deviceName = deviceName
        self.serviceUUID = CBUUID(string: service)
        self.charUUID = CBUUID(string: char)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .poweredOn:
            print("powered on")
            central.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            print("powered off")
            
        case .resetting:
            print("resetting")
            
        case .unauthorized:
            print("unauthorized")
            
        case .unknown:
            print("unknown")
            
        case .unsupported:
            print("unsupported")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        if let device = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("Appareil: \(device)")
            if(deviceName.isEmpty){
                
            }else {
                if (device) == deviceName{
                    
                    self.manager.stopScan()
                    do {
                        self.connectedPeripheral = try peripheral
                    }catch {
                        print("Erreur")
                    }
                    
                    self.connectedPeripheral.delegate = self as! CBPeripheralDelegate
                    manager.connect(peripheral, options: nil)
                    print("connecter")
                }
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices(nil)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            print("service : \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
            if(serviceUUID.uuidString.isEmpty){
                
            }else{
                if service.uuid == serviceUUID {
                    
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            print("Char : \(characteristic.uuid)")
            if(charUUID.uuidString.isEmpty){
                
            }else{
                if characteristic.uuid == charUUID {
                    
                    do {
                        self.connectedPeripheral.setNotifyValue(true, for: characteristic)
                        
                        bleCharacteristic = try characteristic
                    }catch{
                        print("erreur")
                    }
                    
                    peripheral.readValue(for: characteristic)
                    
                }
            }
            
        }
        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == charUUID {
            let content = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            if(content != nil) {
                print("Reception : \(String(describing: content))")
            }
            
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    
    func sendMessageToDevice(value: String) {
        
        if(self.bleCharacteristic != nil){
            do {
                let dataToSend = try value.data(using: String.Encoding.utf8)
                
                
                if (connectedPeripheral != nil) {
                    
                    self.connectedPeripheral?.writeValue(dataToSend!, for: self.bleCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
                    print("Send : \(value)")
                } else {
                    print("haven't discovered device yet")
                }
                
            } catch {
                print("erreur")
            }
        }
        
    }
    
}
