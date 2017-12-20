//
//  ViewController.swift
//  ConnectyCar
//
//  Created by Remy Krysztofiak on 08/09/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion
import CoreData

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var motionManager = CMMotionManager()
    
    var context: NSManagedObjectContext!
    
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var directionSlider: UISlider!{
        didSet{
            directionSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2*2))
        }
    }
    @IBOutlet weak var speedSlider: UISlider!{
        didSet{
            speedSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
        }
    }
    
    var timer = Timer()
    let minuteur = 0.005
    var sendData = true
    var direction = 100
    var lastDirection = 0
    var speed = 90
    var lastSpeed = 0
    
    var manager:CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var vaneCharacteristic:CBCharacteristic?
    
    
    var deviceName = "ConnectyCar"
    var serviceUUID = CBUUID(string: "FFE0")
    var charUUID = CBUUID(string: "FFE1")
    
    var rasp = Sql(ipAddress: "")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("vue 1")
        getIP()
        manager = CBCentralManager(delegate: self, queue: nil)
        interval()
        directionSlider.isEnabled = false
    }
    
    func getIP(){
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: "IpAddress", in: context)
        
        // Configure Fetch Request
        fetchRequest.entity = entityDescription
        
        do {
            let result = try context.fetch(fetchRequest)
            print(result)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        
        do {
            let result = try context.fetch(fetchRequest)
            
            if (result.count > 0) {
                let ipAddress = result[0] as! NSManagedObject
                
                rasp.ipAddress = ipAddress.value(forKey: "ip")! as! String
            }
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    func interval(){
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(minuteur), target: self, selector: #selector(self.checkSlider), userInfo: nil, repeats: true)
    }
    
    @objc func checkSlider(){
        if(lastDirection != direction)||(lastSpeed != speed){
            lastDirection = direction
            lastSpeed = speed
            sendMessageToDevice(value: "D\(lastDirection)V\(lastSpeed)E")
        }
    }
    
    @IBAction func direction(_ sender: Any) {
        if(directionSlider.isTracking){
            direction = Int(directionSlider.value)
        }else{
            directionSlider.value = 100
            direction = 100
        }
        
    }
    
    @IBAction func speed(_ sender: Any) {
        if(speedSlider.isTracking){
            speed = Int(speedSlider.value)
        }else{
            speedSlider.value = 90
            speed = 90
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        motionManager.gyroUpdateInterval = 0.01
        
        motionManager.startDeviceMotionUpdates(
            to: OperationQueue.current!, withHandler: {
                (deviceMotion, error) -> Void in
                
                if(error == nil) {
                    if(self.sendData == true){
                        self.handleDeviceMotionUpdate(deviceMotion: deviceMotion!)
                    }
                    
                } else {
                    //handle the error
                }
        })
    }
    
    func degrees(radians:Double) -> Double {
        return 180 / M_PI * radians
    }
    
    func handleDeviceMotionUpdate(deviceMotion:CMDeviceMotion) {
        var attitude = deviceMotion.attitude
        var roll = degrees(radians: attitude.roll)
        var pitch = Int(degrees(radians: attitude.pitch)) + 100
        var yaw = degrees(radians: attitude.yaw)
        if((pitch >= 45)&&(pitch <= 135)&&(gyro.isOn)){
            direction = pitch
            
            directionSlider.value = Float(direction)
        }
        
        
    }
    
    @IBOutlet weak var gyro: UISwitch!
    @IBAction func gyroscope(_ sender: Any) {
        if gyro.isOn {
            gyro.setOn(false, animated:true)
            directionSlider.isEnabled = true
            direction = 100
            directionSlider.value = Float(direction)
        } else {
            gyro.setOn(true, animated:true)
            directionSlider.isEnabled = false
        }
    }
    
    
    
    
    
    
    
    
    
    
    //MARK:- scan for devices
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
    
    //MARK:- connect to a device
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
                    
                    self.connectedPeripheral.delegate = self
                    manager.connect(peripheral, options: nil)
                    print("connecter")
                    sendData = true
                    //stateLabel.backgroundColor = UIColor(red: 30/255, green: 215/255, blue: 95/255, alpha: 1)
                    //self.stateLabel.text = "connecté à \(deviceName)"
                }
            }
        }
        
    }
    
    //MARK:- discorverSerice
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices(nil)
        
    }
    
    //MARK:- get service
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
    
    //MARK:- get char
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
                            
                        vaneCharacteristic = try characteristic
                    }catch{
                        print("erreur")
                    }
                    
                    peripheral.readValue(for: characteristic)
                    
                }
            }
            
        }
        
        
    }
    
    
    //MARK:- characteristic change
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == charUUID {
            let content = String(data: characteristic.value!, encoding: String.Encoding.utf8)
            if(content != nil) {
                var voitureString = content!
                
                var temperatureMotor = subString(query: voitureString, firstChar: "", secondChar: "V")
                var voitureId = subString(query: voitureString, firstChar: "V", secondChar: "B")
                var batterie = subString(query: voitureString, firstChar: "B", secondChar: "E")
                
                print("VoitureID : \(voitureId), Temperature Moteur : \(temperatureMotor), Batterie : \(batterie)")
                
                let date = NSDate()
                
            }
            
        }
        
    }
    
    
    
    //MARK:- disconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    
    func sendMessageToDevice(value: String) {
        
        if(self.vaneCharacteristic != nil){
            do {
                let dataToSend = try value.data(using: String.Encoding.utf8)
                
                
                if (connectedPeripheral != nil) {
                    
                        self.connectedPeripheral?.writeValue(dataToSend!, for: self.vaneCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
                    print("Send : \(value)")
                } else {
                    print("haven't discovered device yet")
                }
                
            } catch {
                print("erreur")
            }
        }
        
    }
    
    
    func subString(query: String, firstChar: String, secondChar: String)-> String {
        let regex = try! NSRegularExpression(pattern:"\(firstChar)(.*?)\(secondChar)", options: [])
        let tmp = query as NSString
        var results = String()
        
        regex.enumerateMatches(in: query, options: [], range: NSMakeRange(0, query.characters.count)) { result, flags, stop in
            if let range = result?.range(at: 1) {
                results = tmp.substring(with: range)
            }
        }
        return String(describing: results)
    }
    
}

