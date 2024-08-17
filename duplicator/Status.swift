//
//  Status.swift
//  DublicatorApp
//
//  Created by Yury Noyanov on 27.11.2022.
//  Copyright © 2022 Alex Noyanov. All rights reserved.
//

import Foundation

class Status : Decodable {
    var id:String = ""
    var status:String=""
}

class StartPrintResult : Decodable {
    var id:String = ""
    var status:String = ""
    var session:Int = 0
}
