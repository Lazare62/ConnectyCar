//
//  ConfigurationViewController.swift
//  ConnectyCar
//
//  Created by Remy Krysztofiak on 12/12/2017.
//  Copyright © 2017 Remy Krysztofiak. All rights reserved.
//

import UIKit
import CoreData

class ConfigurationViewController: UIViewController {
    
    var context: NSManagedObjectContext!

    @IBOutlet weak var ipTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("vue 2")
    }

    @IBAction func retour(_ sender: Any) {
        clearDatabase(entity: "IpAddress")
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let ipAddress = IpAddress(context: context)
        if(ipTextField.text == ""){
            
            let popAlert = UIAlertController(title: "Zone de Saisie vide 😐", message: "La zone de saisie doit être remplie avant d'enregister", preferredStyle: .alert)
            let popAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                self.performSegue(withIdentifier: "VC", sender: self)
            }
            let popActionCancel = UIAlertAction(title: "Annuler", style: .cancel) { (_) in
            }
            popAlert.addAction(popActionCancel)
            popAlert.addAction(popAction)
            self.present(popAlert, animated: true,completion: nil)
        }else {
            ipAddress.ip = ipTextField.text
            
            do{
                try self.context.save()
                print("sauvegarder")
                let popAlert = UIAlertController(title: "Enregistrement Réussi 👌", message: "Vôtre ip a bien été enregistrer", preferredStyle: .alert)
                let popAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                }
                popAlert.addAction(popAction)
                self.present(popAlert, animated: true,completion: nil)
            }catch{
                print("errreur")
            }
        }
    }
    
    func clearDatabase( entity:String ) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("delete")
        } catch {
            print ("There was an error")
        }
    }
}
