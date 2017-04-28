//
//	CheckResponseFormat.swift
//  MyCity311
//
//  Created by Piyush on 6/7/16.
//  Copyright © 2016 Kahuna Systems. All rights reserved.
//

import Foundation


class CheckResponseFormat : NSObject{

	var result : ResultFormat!

    override init() {
    }

	/**
	 * Instantiate the instance using the passed dictionary values to set the properties values
	 */
	init(fromDictionary dictionary: NSDictionary){
		if let resultData = dictionary["status"] as? NSDictionary{
			result = ResultFormat(fromDictionary: resultData)
		}
	}

	/**
	 * Returns all the available property values in the form of NSDictionary object where the key is the approperiate json key and the value is the value of the corresponding property
	 */
	func toDictionary() -> NSDictionary
	{
		let dictionary = NSMutableDictionary()
		if result != nil{
			dictionary["status"] = result.toDictionary()
		}
		return dictionary
	}

    /**
    * NSCoding required initializer.
    * Fills the data from the passed decoder
    */
    @objc required init(coder aDecoder: NSCoder)
	{
         result = aDecoder.decodeObject(forKey: "status") as? ResultFormat

	}

    /**
    * NSCoding required method.
    * Encodes mode properties into the decoder
    */
    @objc func encodeWithCoder(aCoder: NSCoder)
	{
		if result != nil{
			aCoder.encode(result, forKey: "status")
		}

	}

}
