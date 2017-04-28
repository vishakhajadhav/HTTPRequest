//
//	ResultFormat.swift
//
//	Create by Piyush on 7/6/2016
//  Copyright © 2016 Kahuna Systems. All rights reserved.
//

import Foundation


class ResultFormat : NSObject, NSCoding{

	var cause : String!
	var code : Int!
	var message : String!
   
	/**
	 * Instantiate the instance using the passed dictionary values to set the properties values
	 */
	init(fromDictionary dictionary: NSDictionary){
		cause = dictionary["cause"] as? String
		code = dictionary["code"] as? Int
		message = dictionary["message"] as? String
	}

	/**
	 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
	 */
	func toDictionary() -> NSDictionary
	{
		let dictionary = NSMutableDictionary()
		if cause != nil{
			dictionary["cause"] = cause
		}
		if code != nil{
			dictionary["code"] = code
		}
		if message != nil{
			dictionary["message"] = message
		}
		return dictionary
	}

    /**
    * NSCoding required initializer.
    * Fills the data from the passed decoder
    */
    @objc required init(coder aDecoder: NSCoder)
	{
        cause = aDecoder.decodeObjectForKey("cause") as? String
        code = aDecoder.decodeObjectForKey("code") as? Int
        message = aDecoder.decodeObjectForKey("message") as? String

	}

    /**
    * NSCoding required method.
    * Encodes mode properties into the decoder
    */
    @objc func encodeWithCoder(aCoder: NSCoder)
	{
        if cause != nil{
            aCoder.encodeObject(cause, forKey: "cause")
        }
        if code != nil{
            aCoder.encodeObject(code, forKey: "code")
        }
        if message != nil{
            aCoder.encodeObject(message, forKey: "message")
        }
	}

}
