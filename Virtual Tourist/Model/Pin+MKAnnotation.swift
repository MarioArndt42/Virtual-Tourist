//
//  Pin+MKAnnotation.swift
//  Virtual Tourist
//
//  Created by Mario Arndt on 06.12.22.
//

import MapKit

extension Pin: MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
}

