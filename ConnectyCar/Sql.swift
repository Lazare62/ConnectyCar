//
//  Sql.swift
//  ConnectyCar
//
//  Created by Remy Krysztofiak on 11/11/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import Foundation

class Sql: NSObject {
    
    var ipAddress : String
    
    init(ipAddress: String) {
        self.ipAddress = ipAddress
    }
    
    func POST(path: String, file: String, postValue: String) {
        let request = NSMutableURLRequest(url: NSURL(string: "http://\(ipAddress):8888/\(path)/\(file)")! as URL)
        request.httpMethod = "POST"
        
        let postString = postValue
        
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                
                print("error= \(String(describing: error))")
                return
                
            } else {
             
                print("response = \(String(describing: response))")
                
                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                print("responseString = \(String(describing: responseString))")
                
            }
            
        }
        task.resume()
    }
    
    
}
