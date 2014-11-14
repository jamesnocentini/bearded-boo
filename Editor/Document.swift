import UIKit

class Player: CBLModel {
    
    @NSManaged var firstname: String
    
    init(firstname: String) {
        super.init(document: kDatabase.createDocument())
        
        setValue("player", ofProperty: "type")
        self.firstname = firstname
    }
    
    override init!(document: CBLDoc) {
        super.init(document: document)
    }
    
    class func queryPlayers() {
        // view code
    }
    
}