//
//  gradientMethod.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 06/05/2024.
//

import Foundation
import UIKit
import SceneKit

class gradientMethod{
    
    //does it need to be in the form of a dictionary? How can I make this memory efficient?
    func extractVertices(from geometry: SCNGeometry) -> [SCNVector3]? {//returns all the vertices from
        // Get vertex sources
        guard let vertexSource = geometry.sources.first(where: { $0.semantic == .vertex }) else {return nil}


        let stride = vertexSource.dataStride // in bytes
        let offset = vertexSource.dataOffset // in bytes
        let componentsPerVector = vertexSource.componentsPerVector
        let bytesPerComponent = vertexSource.bytesPerComponent
        let bytesPerVector = componentsPerVector * bytesPerComponent
        let vectorCount = vertexSource.vectorCount

        var vertices = [SCNVector3]() // A new array for vertices

        // For each vector, read the bytes
        for i in 0..<vectorCount {
            // Assuming that bytes per component is 4 (a float)
            // If it was 8 then it would be a double (aka CGFloat)
            var vectorData = [Float](repeating: 0, count: componentsPerVector)

            // The range of bytes for this vector
            let byteRange = i * stride + offset ..< i * stride + offset + bytesPerVector
            
            vertexSource.data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in//explain code
                // Bind the raw buffer pointer to the desired type (Float)
                let typedBufferPointer = rawBufferPointer.bindMemory(to: Float.self)

                // Access the base address of the typed buffer pointer
                if let baseAddress = typedBufferPointer.baseAddress {
                    // Calculate the destination pointer for the copy operation
                    let destinationPointer = UnsafeMutablePointer<Float>.allocate(capacity: bytesPerVector / MemoryLayout<Float>.stride)
                    
                    // Convert destinationPointer to UnsafeMutableRawPointer
                    let destinationRawPointer = UnsafeMutableRawPointer(destinationPointer)
                    
                    // Convert destinationRawPointer to UnsafeMutableRawBufferPointer
                    let destinationBufferPointer = UnsafeMutableRawBufferPointer(start: destinationRawPointer, count: bytesPerVector)
                    
                    // Copy bytes from the byte range to the destination buffer pointer
                    rawBufferPointer.copyBytes(to: destinationBufferPointer, from: byteRange)
                    
                    // Convert the copied bytes to an array of Float (vectorData)
                    vectorData = Array(UnsafeBufferPointer(start: destinationPointer, count: bytesPerVector / MemoryLayout<Float>.stride))
                    
                    // Deallocate the memory allocated for the destination pointer
                    destinationPointer.deallocate()
                }
            }


            // At this point you can read the data from the float array
            let x = vectorData[0]
            let y = vectorData[1]
            let z = vectorData[2]

            // Append the vertex to the array
            vertices.append(SCNVector3(x, y, z))

            // ... or just log it
          //  print("x: \(x), y: \(y), z: \(z)")
        }

        return vertices
    }
    
    func getDistance(point1 : SCNVector3, point2 : SCNVector3) -> Float{
        return pow(point1.x - point2.x, 2.0) + pow(point1.z - point2.z, 2.0)
    }
    
    //gets the k closest points to a specified input point
    //time complexity O(n log n)
    //need to also print the distance
    func closestDistance(points: [SCNVector3], inputPoint: SCNVector3, k: Int) -> [SCNVector3] {
        guard !points.isEmpty && k > 0 && k <= points.count else {
            return []
        }
        
        let closestPoints = points.sorted(by: {
            getDistance(point1: inputPoint, point2: $0) < getDistance(point1: inputPoint, point2: $1)
        }).prefix(k)
        
        return Array(closestPoints)
    }
    
    //returns weighted average of multiple points
    func averageValues(closestPoints: [SCNVector3], inputPoint: SCNVector3) -> Float{
        var sum : Float = 1
        var averagedHeight : Float =  0.0
        for i in 0...(closestPoints.count-1){
            if i != 0{
                sum += (1.0 - Float(i)/Float(closestPoints.count))
            }
            averagedHeight += closestPoints[i].y * (1.0 - Float(i)/Float(closestPoints.count))
        }
        return averagedHeight/sum
    }
    
    //returns the smoothed height value for the coordinate as an SCNVector3
    func addNewAverage(inputPoint: SCNVector3, originalPointCloud: [SCNVector3], k: Int) -> SCNVector3{
        let closestPoints = closestDistance(points: originalPointCloud, inputPoint: inputPoint, k: k)
        let averagedHeight = averageValues(closestPoints: closestPoints, inputPoint: inputPoint)
        return (SCNVector3(inputPoint.x, averagedHeight, inputPoint.z))
    }
    
    func smoothPointCloud(from geometry: SCNGeometry) -> (smoothed: [SCNVector3], transient: [SCNVector3]){
        let pointCloud : [SCNVector3] = extractVertices(from: geometry) ?? []
        print("check1")
        var smoothedHeightMap : [SCNVector3] = []//should this be a dictionary? what if the x,z coordinate that is touched isn't exactly equal to a key in the dictionary?
        //go to each value in point cloud
        var yDifferences : [SCNVector3] = []
        var i = 0
        for point in pointCloud {
            print(i)
            let changedPoint = addNewAverage(inputPoint: point, originalPointCloud: pointCloud, k: 3)
            smoothedHeightMap.append(changedPoint)
            yDifferences.append(SCNVector3(point.x, point.y - changedPoint.y, point.z))
            i += 1
        }
        
       /* let yDifferences = zip(pointCloud, smoothedHeightMap).map { (coord1, coord2) in
            return SCNVector3(x: coord1.x, y: coord1.y - coord2.y, z: coord1.z)
        }*/
        
    
        return (smoothedHeightMap, yDifferences)
        //do quickselect to get k closest values (using getDistance)
        //average these heights
        //create new SCNVector3 where point.x/z is the point and point.y = average value
        //create gradient map where value = difference between smoothed and original
    }
    
 /*   func getTransientCloud(originalPoints: [SCNVector3], smoothPointCloud: [SCNVector3]) -> [SCNVector3]{
        //what to do if they end up being different lengths?
        guard originalPoints.count == smoothPointCloud.count else {
                fatalError("Coordinate lists must have the same length.")
            }
            
            // Use map to calculate differences
            let yDifferences = zip(originalPoints, smoothPointCloud).map { (coord1, coord2) in
                return SCNVector3(x: coord1.x, y: coord1.y - coord2.y, z: coord1.z)
            }
            
            return yDifferences
        
    }*/
}
