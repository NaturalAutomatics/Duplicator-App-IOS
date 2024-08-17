//
//  ModelData.swift
//  DublicatorApp
//
//  Created by Yury Noyanov on 26.11.2022.
//  Copyright © 2022 Alex Noyanov. All rights reserved.
//

public class ModelData : Decodable, Encodable {
    var id:String = "123"
    var name:String = "SpaceShip"
    var description:String = "My perfect spaceship model for my collection"
    var imgUrl:String = "Work/images/spasecraft.png"
}

class AllModelData : Decodable, Encodable {
    var modelData:ModelData = ModelData()
}
