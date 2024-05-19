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
    
    func storeExtractVertices(from geometry: SCNGeometry) -> [SCNVector3]? {
        // Get vertex sources
        let url = URL.documentsDirectory.appendingPathComponent("vertices.txt")
        
        if !FileManager.default.fileExists(atPath: url.path) {
            // File doesn't exist, create it
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        
        guard let fileHandle = try FileHandle(forWritingAtPath: url.path) else {
            fatalError("Could not open file for writing.")
        }
        guard let vertexSource = geometry.sources.first(where: { $0.semantic == .vertex }) else {return nil}
        
        
        let stride = vertexSource.dataStride // in bytes
        let offset = vertexSource.dataOffset // in bytes
        let componentsPerVector = vertexSource.componentsPerVector
        let bytesPerComponent = vertexSource.bytesPerComponent
        let bytesPerVector = componentsPerVector * bytesPerComponent
        let vectorCount = vertexSource.vectorCount
        print("VECTOR COUNT")
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
            let point = SCNVector3(x: x, y: y, z: z)
            
            // Append the vertex to the array
            vertices.append(SCNVector3(x, y, z))
            
            let coordinateString = "\(point)\n"
            // Convert the string to Data
            //   if let data = coordinateString.data(using: .utf8) {
            // Write the Data to the file
            if let data = coordinateString.data(using: .utf8) {
                // Write the Data to the file
                fileHandle.write(data)
            }
            print(i)
            
            // ... or just log it
            //  print("x: \(x), y: \(y), z: \(z)")
        }
        fileHandle.closeFile()
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
    
    ///uses weighted averaging: need to be able to change k
    func smoothPointCloud(from geometry: SCNGeometry) -> (smoothed: [SCNVector3], transient: [SCNVector3]){
        let url = URL.documentsDirectory.appendingPathComponent("smoothCloud.txt")
        let url2 = URL.documentsDirectory.appendingPathComponent("transientCloud.txt")
        print(URL.documentsDirectory)
        /*guard let fileHandle = FileHandle(forWritingAtPath: url.path) else {
         fatalError("Could not open file for writing.")
         }*/
        if !FileManager.default.fileExists(atPath: url.path) {
            // File doesn't exist, create it
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        
        guard let fileHandle = try FileHandle(forWritingAtPath: url.path) else {
            fatalError("Could not open file for writing.")
        }
        
        if !FileManager.default.fileExists(atPath: url2.path) {
            // File doesn't exist, create it
            FileManager.default.createFile(atPath: url2.path, contents: nil, attributes: nil)
        }
        
        guard let fileHandle2 = try FileHandle(forWritingAtPath: url2.path) else {
            fatalError("Could not open file 2 for writing.")
        }
        
        // File handle is successfully obtained, you can write to the file here
        
        let pointCloud : [SCNVector3] = extractVertices(from: geometry) ?? []
        var smoothedHeightMap : [SCNVector3] = []//should this be a dictionary? what if the x,z coordinate that is touched isn't exactly equal to a key in the dictionary?
        //go to each value in point cloud
        var yDifferences : [SCNVector3] = []
        var i = 0
        for point in pointCloud {
            print(i)
            let changedPoint = addNewAverage(inputPoint: point, originalPointCloud: pointCloud, k: 3)
            smoothedHeightMap.append(changedPoint)
            let yDifference = SCNVector3(point.x, point.y - changedPoint.y, point.z)
            yDifferences.append(yDifference)
            let coordinateString = "\(changedPoint)\n"
            // Convert the string to Data
            //   if let data = coordinateString.data(using: .utf8) {
            // Write the Data to the file
            if let data = coordinateString.data(using: .utf8) {
                // Write the Data to the file
                fileHandle.write(data)
            }
            let transientString = "\(yDifference)\n"
            // Convert the string to Data
            //   if let data = coordinateString.data(using: .utf8) {
            // Write the Data to the file
            if let data2 = transientString.data(using: .utf8) {
                // Write the Data to the file
                fileHandle2.write(data2)
            }
            //  }
            i += 1
        }
        
        /* let yDifferences = zip(pointCloud, smoothedHeightMap).map { (coord1, coord2) in
         return SCNVector3(x: coord1.x, y: coord1.y - coord2.y, z: coord1.z)
         }*/
        fileHandle.closeFile()
        fileHandle2.closeFile()
        
        print("Coordinates saved to file: \(url)")
        
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
    func createGaussianKernel(size: Int, sigma: Float) -> [Float] {
        var kernel: [Float] = []
        let mean = Float(size - 1) / 2.0
        var sum: Float = 0.0
        
        for i in 0..<size {
            let value = exp(-0.5 * pow((Float(i) - mean) / sigma, 2.0)) / (sigma * sqrt(2.0 * Float.pi))
            kernel.append(value)
            sum += value
        }
        
        // Normalize the kernel
        kernel = kernel.map { $0 / sum }
        
        return kernel
    }
    func distanceBetween(_ a: SCNVector3, and b: SCNVector3) -> Float {
        return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2) + pow(a.z - b.z, 2))
    }
    func applyGaussianFilter(to point: SCNVector3, sigma: Float, vertices: [SCNVector3], kernelSize: Int) -> SCNVector3 {
        
      //  let kernelSize = 5  // Define kernel size
        let kernel: [Float] = createGaussianKernel(size: kernelSize, sigma: sigma)
        
        
        var weightedSumX: Float = 0
        var weightedSumY: Float = 0
        var weightedSumZ: Float = 0
        var weightSum: Float = 0
        
        for i in 0..<vertices.count {
            let distance = distanceBetween(point, and: vertices[i])
            if distance < Float(kernelSize) {
                let weight = exp(-0.5 * pow(distance / sigma, 2.0))
                weightedSumX += vertices[i].x * weight
                weightedSumY += vertices[i].y * weight
                weightedSumZ += vertices[i].z * weight
                weightSum += weight
            }
        }
        return SCNVector3(
            weightedSumX / weightSum,
            weightedSumY / weightSum,
            weightedSumZ / weightSum
        )
    }
    
    //fix
    func getWeightedAverage(to point: SCNVector3, sigma: Float, vertices: [SCNVector3], kernelSize: Int) -> SCNVector3 {
        
      //  let kernelSize = 5  // Define kernel size
        let kernel: [Float] = createGaussianKernel(size: kernelSize, sigma: sigma)
        
        
        var weightedSumX: Float = 0
        var weightedSumY: Float = 0
        var weightedSumZ: Float = 0
        var weightSum: Float = 0
        
        for i in 0..<vertices.count {
            let distance = distanceBetween(point, and: vertices[i])
            if distance < Float(kernelSize) {
                let weight = exp(-0.5 * pow(distance / sigma, 2.0))
                weightedSumX += vertices[i].x * weight
                weightedSumY += vertices[i].y * weight
                weightedSumZ += vertices[i].z * weight
                weightSum += weight
            }
        }
        return SCNVector3(
            weightedSumX / weightSum,
            weightedSumY / weightSum,
            weightedSumZ / weightSum
        )
    }
    
}
