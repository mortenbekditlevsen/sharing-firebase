//
//  File.swift
//  
//
//  Created by Morten Bek Ditlevsen on 27/06/2024.
//

import Foundation
import IdentifiedCollections

// This protocol has no additional requirements and is used to mark
// documents in the database that use their `Identifiable` id as their
// key.
public protocol KeyedById: Identifiable {}

extension IdentifiedArray where Element: KeyedById {
    
}
