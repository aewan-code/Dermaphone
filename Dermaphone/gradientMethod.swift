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
        let url = URL.documentsDirectory.appendingPathComponent("vertices5.txt")
        
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
        if closestPoints.count == 0{
            return inputPoint.y
        }
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
    
    
    func gaussianKernel(size: Int, sigma: Float) -> [[Float]] {
        let mid = size / 2
        var kernel = Array(repeating: Array(repeating: Float(0.0), count: size), count: size)
        let sigmaSquared = 2 * sigma * sigma
        var sum = Float(0.0)
        
        for x in 0..<size {
            for y in 0..<size {
                let xDist = x - mid
                let yDist = y - mid
                let distSquared = Float(xDist * xDist + yDist * yDist)
                let exponent = distSquared / sigmaSquared
                kernel[x][y] = (1 / (Float.pi * sigmaSquared)) * exp(-exponent)
                sum += kernel[x][y]
            }
        }
        
        // Normalize the kernel
        for x in 0..<size {
            for y in 0..<size {
                kernel[x][y] /= sum
            }
        }
        
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
        print("kernelsize", kernelSize)
        for i in 0..<vertices.count {
            let distance = distanceBetween(point, and: vertices[i])
            if distance < Float(kernelSize)/50 {
                let weight = exp(-0.5 * pow(distance / sigma, 2.0))
                weightedSumX += vertices[i].x * weight
                weightedSumY += vertices[i].y * weight
                weightedSumZ += vertices[i].z * weight
                weightSum += weight
            }
        }
        if weightSum == 0 {
            return point
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
    
    func applyMexicanHatFilter(to point: SCNVector3, sigma: Float, vertices: [SCNVector3], kernelSize: Int) -> SCNVector3 {
        var weightedSumX: Float = 0
        var weightedSumY: Float = 0
        var weightedSumZ: Float = 0
        var weightSum: Float = 0
        
        for vertex in vertices {
            let distance = distanceBetween(point, and: vertex)
            if distance < Float(kernelSize) {
                // Calculate Mexican Hat weight
                let scaledDistance = distance / sigma
                let weight = (1 - scaledDistance * scaledDistance) * exp(-0.5 * scaledDistance * scaledDistance)
                
                weightedSumX += vertex.x * weight
                weightedSumY += vertex.y * weight
                weightedSumZ += vertex.z * weight
                weightSum += weight
            }
        }
        
        if weightSum != 0 {
            return SCNVector3(
                weightedSumX / weightSum,
                weightedSumY / weightSum,
                weightedSumZ / weightSum
            )
        } else {
            return point  // Return the original point if no weights were applied
        }
    }
    
    func createHeightMap1(from vertices: [SCNVector3], gridSize: Int) -> [[Float]] {
        guard !vertices.isEmpty, gridSize > 1 else { return [[Float]]() }
        
        let minX = vertices.min(by: { $0.x < $1.x })?.x ?? 0
        let maxX = vertices.max(by: { $0.x < $1.x })?.x ?? 0
        let minZ = vertices.min(by: { $0.z < $1.z })?.z ?? 0
        let maxZ = vertices.max(by: { $0.z < $1.z })?.z ?? 0
        
        let deltaX = (maxX - minX) / Float(gridSize - 1)
        let deltaZ = (maxZ - minZ) / Float(gridSize - 1)
        
        // Creating grid for spatial hashing
        var grid = [Int: [SCNVector3]]()
        for vertex in vertices {
            let indexX = Int((vertex.x - minX) / deltaX)
            let indexZ = Int((vertex.z - minZ) / deltaZ)
            let hash = indexZ * gridSize + indexX
            grid[hash, default: []].append(vertex)
        }
        
        var heightMap = Array(repeating: Array(repeating: Float(0), count: gridSize), count: gridSize)
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                let hash = j * gridSize + i
                let points = grid[hash] ?? []
                // Simple averaging or nearest neighbor within the cell
                if let nearest = points.min(by: { distanceSquared(from: $0, to: SCNVector3(minX + Float(i) * deltaX, 0,  minZ + Float(j) * deltaZ)) < distanceSquared(from: $1, to: SCNVector3(minX + Float(i) * deltaX, 0, minZ + Float(j) * deltaZ)) }) {
                    heightMap[i][j] = nearest.y
                }
            }
        }
        return heightMap
    }
    
    func createHeightMap2(from vertices: [SCNVector3], gridSize: Int) -> [[Float]] {
        guard !vertices.isEmpty, gridSize > 1 else { return [[Float]]() }
        
        let minX = vertices.min(by: { $0.x < $1.x })?.x ?? 0
        let maxX = vertices.max(by: { $0.x < $1.x })?.x ?? 0
        let minZ = vertices.min(by: { $0.z < $1.z })?.z ?? 0
        let maxZ = vertices.max(by: { $0.z < $1.z })?.z ?? 0
        
        let deltaX = (maxX - minX) / Float(gridSize - 1)
        let deltaZ = (maxZ - minZ) / Float(gridSize - 1)
        
        var heightMap = Array(repeating: Array(repeating: Float.nan, count: gridSize), count: gridSize)
        
        for vertex in vertices {
            let indexX = min(Int((vertex.x - minX) / deltaX), gridSize - 1)
            let indexZ = min(Int((vertex.z - minZ) / deltaZ), gridSize - 1)
            heightMap[indexZ][indexX] = vertex.y
        }
        
        interpolateHeightMap(&heightMap) // Apply interpolation to fill NaN values
        //   gaussianSmoothing(&heightMap, sigma: 1.0) // Optional: Smooth the height map
        
        return heightMap
    }
    
    func interpolateHeightMap(_ heightMap: inout [[Float]]) {
        let gridSize = heightMap.count
        for i in 0..<gridSize {
            for j in 0..<gridSize {
                if heightMap[i][j].isNaN {
                    // Collect heights from neighboring cells for averaging
                    var totalHeight: Float = 0
                    var count: Int = 0
                    
                    for di in -1...1 {
                        for dj in -1...1 {
                            let ni = i + di
                            let nj = j + dj
                            if ni >= 0 && ni < gridSize && nj >= 0 && nj < gridSize && !heightMap[ni][nj].isNaN {
                                totalHeight += heightMap[ni][nj]
                                count += 1
                            }
                        }
                    }
                    
                    if count > 0 {
                        heightMap[i][j] = totalHeight / Float(count)
                    }
                    
                }
            }
        }
    }
    
    
    
    func distanceSquared(from: SCNVector3, to: SCNVector3) -> Float {
        return (from.x - to.x) * (from.x - to.x) + (from.z - to.z) * (from.z - to.z)
    }
    
    func applySobelOperator(to heightMap: [[Float]]) -> [[Float]] {
        let rows = heightMap.count
        let cols = heightMap[0].count
        var gradientMap = Array(repeating: Array(repeating: Float(0), count: cols), count: rows)
        
        let Gx = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]] // Sobel kernel for horizontal changes
        let Gy = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]] // Sobel kernel for vertical changes
        
        for i in 1..<rows-1 {
            for j in 1..<cols-1 {
                var sumX: Float = 0
                var sumY: Float = 0
                
                for k in 0...2 {
                    for l in 0...2 {
                        sumX += Float(heightMap[i-1+k][j-1+l]) * Float(Gx[k][l])
                        sumY += Float(heightMap[i-1+k][j-1+l]) * Float(Gy[k][l])
                    }
                }
                
                let magnitude = sqrt(sumX*sumX + sumY*sumY) // Gradient magnitude
                gradientMap[i][j] = magnitude
            }
        }
        
        return gradientMap
    }
    
    func mexicanHatKernel(size: Int, sigma: Float) -> [[Float]] {
        let radius = size / 2
        var kernel = Array(repeating: Array(repeating: Float(0), count: size), count: size)
        
        for i in -radius...radius {
            for j in -radius...radius {
                let value = (1 - (Float(i*i + j*j) / (sigma * sigma))) * exp(-(Float(i*i + j*j) / (2 * sigma * sigma)))
                kernel[i + radius][j + radius] = value
            }
        }
        
        return kernel
    }
    
    func applyKernel(kernel: [[Float]], to heightMap: [[Float]]) -> [[Float]] {
        let rows = heightMap.count
        let cols = heightMap[0].count
        var outputMap = Array(repeating: Array(repeating: Float(0), count: cols), count: rows)
        
        let kernelSize = kernel.count
        let kernelRadius = kernelSize / 2
        
        for i in kernelRadius..<(rows - kernelRadius) {
            for j in kernelRadius..<(cols - kernelRadius) {
                var sum: Float = 0
                
                for k in 0..<kernelSize {
                    for l in 0..<kernelSize {
                        sum += kernel[k][l] * heightMap[i - kernelRadius + k][j - kernelRadius + l]
                    }
                }
                
                outputMap[i][j] = sum
            }
        }
        
        return outputMap
    }
    
    func applyGaussianToHeightMap(heightMap: [[Float]], k: Int, sigma: Float) -> [[Float]]{
        let kernel = self.gaussianKernel(size: k, sigma: sigma)
        let appliedKernel = self.applyKernel(kernel: kernel, to: heightMap)
        var highPassHeightMap = Array(repeating: Array(repeating: Float(0), count: heightMap.count), count: heightMap.count)
        for i in 0..<(heightMap.count){
            for j in 0..<(heightMap.count){
                highPassHeightMap[i][j] = heightMap[i][j] - appliedKernel[i][j]
            }
        }
        //RETURN THE DIFFERENCE BETWEEN THE GAUSSIAN AND THAT VALUE
        return appliedKernel//highPassHeightMap
        
    }
    func getGaussianSmoothed(heightMap: [[Float]], k: Int, sigma: Float) -> [[Float]]{
        let kernel = self.gaussianKernel(size: k, sigma: sigma)
        let appliedKernel = self.applyKernel(kernel: kernel, to: heightMap)
        var highPassHeightMap = Array(repeating: Array(repeating: Float(0), count: heightMap.count), count: heightMap.count)
        for i in 0..<(heightMap.count){
            for j in 0..<(heightMap.count){
                highPassHeightMap[i][j] = heightMap[i][j] - appliedKernel[i][j]
            }
        }
        return highPassHeightMap
        
    }
    //returns gradient height map and min and max values to scale it by
    func convertHeightMapToGradient(heightMap : [[Float]])->([[Float]], Float, Float){
        var gradientHeightMap = Array(repeating: Array(repeating: Float(0), count: heightMap.count), count: heightMap.count)
        var maxPoint : Float = 1
        var minPoint : Float = 0
        for i in 0..<(heightMap.count){
            for j in 0..<(heightMap.count){
                if i != 0 && j != 0 && i != (heightMap.count - 1) && j != (heightMap.count - 1){
                    let gradient_x = (heightMap[i+1][j] - heightMap[i-1][j]) / 2
                    let gradient_z = (heightMap[i][j+1] - heightMap[i][j-1]) / 2
                    let gradientMag = (gradient_x * gradient_x) + (gradient_z * gradient_z)
                    gradientHeightMap[i][j] = gradientMag
                    if gradientMag < minPoint{
                        minPoint = gradientMag
                    }
                    if gradientMag > maxPoint{
                        maxPoint = gradientMag
                    }
                }
            }
        }
        return (gradientHeightMap, minPoint, maxPoint)
    }
    
    func dynamicGridSize(min: Float, max1: Float, desiredCellWidth: Float) -> Int {
        let range = max1 - min
        return max(10, Int(ceil(range / desiredCellWidth)))  // Ensure at least a minimum grid size
    }
    func extractHeightMap(from geometry: SCNGeometry, gridSizeX: Int, gridSizeZ: Int) -> [[Float]]? {
        // Ensure the vertex source is available and correctly formatted
        guard let vertexSource = geometry.sources.first(where: { $0.semantic == .vertex }) else { return nil }
        
        let stride = vertexSource.dataStride // in bytes
        let offset = vertexSource.dataOffset // in bytes
        let componentsPerVector = vertexSource.componentsPerVector
        let bytesPerComponent = vertexSource.bytesPerComponent
        let vectorCount = vertexSource.vectorCount
        
        // Initialize min and max variables
        var minX = Float.greatestFiniteMagnitude
        var maxX = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude
        var maxZ = -Float.greatestFiniteMagnitude
        
        // Temporary array to hold all vertices for min/max calculation
        var vertices = [SCNVector3]()
        
        // Extract all vertices to compute min/max and fill vertices array
        vertexSource.data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            let bufferPointer = rawBufferPointer.bindMemory(to: Float.self)
            
            for i in 0..<vectorCount {
                let baseIndex = (i * stride + offset) / MemoryLayout<Float>.stride
                
                let x = bufferPointer[baseIndex]     // Assuming x is the first component
                let y = bufferPointer[baseIndex + 1] // Assuming y is the height (second component)
                let z = bufferPointer[baseIndex + 2] // Assuming z is the third component
                
                vertices.append(SCNVector3(x, y, z))
                
                // Update min and max values
                minX = min(minX, x)
                maxX = max(maxX, x)
                minZ = min(minZ, z)
                maxZ = max(maxZ, z)
            }
        }
        
        // Extract vertices and find min/max as previously described
        let desiredCellWidth = 0.01
        // Calculate dynamic grid sizes based on min/max and desired cell width
        let gridSizeX = dynamicGridSize(min: minX, max1: maxX, desiredCellWidth: Float(desiredCellWidth))
        let gridSizeZ = dynamicGridSize(min: minZ, max1: maxZ, desiredCellWidth: Float(desiredCellWidth))
        
        // Initialize heightMap array
        var heightMap = Array(repeating: Array(repeating: Float.nan, count: gridSizeZ), count: gridSizeX)
        
        // Process vertices to populate the height map
        for vertex in vertices {
            let x = vertex.x
            let z = vertex.z
            let y = vertex.y
            
            // Dynamic normalization to grid indices
            let ix = min(gridSizeX - 1, max(0, Int((x - minX) / (maxX - minX) * Float(gridSizeX - 1))))
            let iz = min(gridSizeZ - 1, max(0, Int((z - minZ) / (maxZ - minZ) * Float(gridSizeZ - 1))))
            
            // Set or average y value in the height map
            heightMap[ix][iz] = y  // Adjust this line to handle averaging or max pooling if needed
        }
        
        return heightMap
    }
    
    func createGeom() -> SCNGeometry{
        let height : [[Float]] = [[0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.0], [0.25, 1.25, 3.25, 4.75, 5.0, 5.0, 4.75, 3.25, 1.25, 0.25], [0.0, 0.75, 2.25, 3.75, 4.75, 4.75, 3.75, 2.25, 0.75, 0.0], [0.0, 0.25, 1.25, 2.25, 3.25, 3.25, 2.25, 1.25, 0.25, 0.0], [0.0, 0.0, 0.25, 0.75, 1.25, 1.25, 0.75, 0.25, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0]]
        
        let rows = height.count
        let cols = height[0].count

        var vertices = [SCNVector3]()

        for z in 0..<rows {
            for x in 0..<cols {
                let y = height[z][x]
                vertices.append(SCNVector3(x: Float(x), y: y, z: Float(z)))
            }
        }
        
        var indices: [Int32] = []

        for z in 0..<rows - 1 {
            for x in 0..<cols - 1 {
                let topLeft = z * cols + x
                let topRight = topLeft + 1
                let bottomLeft = (z + 1) * cols + x
                let bottomRight = bottomLeft + 1

                // First triangle: topLeft, bottomLeft, topRight
                indices.append(contentsOf: [Int32(topLeft), Int32(bottomLeft), Int32(topRight)])
                // Second triangle: topRight, bottomLeft, bottomRight
                indices.append(contentsOf: [Int32(topRight), Int32(bottomLeft), Int32(bottomRight)])
            }
        }
        print("create vertex data")
        // Creating the geometry source with vertices
        let vertexData = NSData(bytes: vertices, length: vertices.count * MemoryLayout<SCNVector3>.size) as Data
        print("create vertex source")
        
        
        let vertexSource = SCNGeometrySource(data: vertexData,
                                             semantic: .vertex,
                                             vectorCount: vertices.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SCNVector3>.size)

        print("create index data")
        // Creating the geometry element with indices
        let indexData = NSData(bytes: indices, length: indices.count * MemoryLayout<Int32>.size)
        print("create element")
        let element = SCNGeometryElement(data: indexData as Data,
                                         primitiveType: .triangles,
                                         primitiveCount: indices.count / 3,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        print("create geometry")
        // Create the geometry
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        return geometry

    }
    func createHeightMap(from geometry: SCNGeometry, resolutionX: Int, resolutionZ: Int) -> [[Float]] {
        guard let vertexSource = geometry.sources(for: .vertex).first else {
            fatalError("Vertex source not found")
        }
        
        let vertexData = vertexSource.data
        let stride = vertexSource.dataStride
        let offset = vertexSource.dataOffset
        let vectorCount = vertexSource.vectorCount

        // Initialize the height map with default values
        var heightMap = Array(repeating: Array(repeating: Float.nan, count: resolutionZ), count: resolutionX)

        // Bounds for normalization
        var minX = Float.greatestFiniteMagnitude
        var maxX = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude
        var maxZ = -Float.greatestFiniteMagnitude

        // First pass: find min and max for normalization
        for i in 0..<vectorCount {
            vertexData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                let vertexPointer = buffer.baseAddress!.advanced(by: i * stride + offset).assumingMemoryBound(to: Float.self)
                let x = vertexPointer.pointee
                let z = vertexPointer.advanced(by: 2).pointee
                
                minX = min(minX, x)
                maxX = max(maxX, x)
                minZ = min(minZ, z)
                maxZ = max(maxZ, z)
            }
        }
        
        // Second pass: populate height map
        for i in 0..<vectorCount {
            vertexData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                let vertexPointer = buffer.baseAddress!.advanced(by: i * stride + offset).assumingMemoryBound(to: Float.self)
                let x = vertexPointer.pointee
                let y = vertexPointer.advanced(by: 1).pointee
                let z = vertexPointer.advanced(by: 2).pointee
                
                // Normalize and scale (x, z) to grid indices
                let ix = Int(((x - minX) / (maxX - minX)) * Float(resolutionX - 1))
                let iz = Int(((z - minZ) / (maxZ - minZ)) * Float(resolutionZ - 1))
                
                // Handle multiple y values: take the maximum or average them out
                if heightMap[ix][iz].isNaN {
                    heightMap[ix][iz] = y
                } else {
                    // Replace the next line with your chosen method (average, min, max, etc.)
                    heightMap[ix][iz] = max(heightMap[ix][iz], y)
                }
            }
        }
        
        return heightMap
    }
    
    func createCustomCone(top: SCNVector3, radius: CGFloat, slices: Int) -> SCNGeometry {
        var vertices = [SCNVector3]()
        vertices.append(top) // Top vertex of the cone

        // Calculate the vertices around the base with varying angular increments
        let centerBase = SCNVector3(top.x, top.y - Float(radius), top.z)
        vertices.append(centerBase) // Center of the base for easy base creation

        for i in 0..<slices {
            let angularIncrement = CGFloat(i) * 2.0 * .pi / CGFloat(slices)
            let x = centerBase.x + Float(cos(angularIncrement) * radius)
            let z = centerBase.z + Float(sin(angularIncrement) * radius)
            let y = centerBase.y
            
            vertices.append(SCNVector3(x, y, z))
        }
        
        return createGeometry(vertices: vertices, topIndex: 0, baseCenterIndex: 1, slices: slices)
    }
    
    func createGeometry(vertices: [SCNVector3], topIndex: Int, baseCenterIndex: Int, slices: Int) -> SCNGeometry {
        var indices: [Int32] = []
        
        // Side triangles
        for i in 0..<slices {
            let nextIndex = (i + 1) % slices
            indices.append(Int32(topIndex))
            indices.append(Int32(baseCenterIndex + i + 1))
            indices.append(Int32(baseCenterIndex + nextIndex + 1))
        }

        // Base triangles
        for i in 0..<slices {
            let nextIndex = (i + 1) % slices
            indices.append(Int32(baseCenterIndex))
            indices.append(Int32(baseCenterIndex + i + 1))
            indices.append(Int32(baseCenterIndex + nextIndex + 1))
        }

        // Create geometry
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [vertexSource], elements: [element])
    }

    func getTransformedVertices(node: SCNNode) -> [SCNVector3] {
        guard let geometry = node.geometry,
              let vertexSource = geometry.sources(for: .vertex).first else {
            fatalError("No vertex data available")
        }

        let vertexData = vertexSource.data
        let vertexCount = vertexSource.vectorCount
        let stride = vertexSource.dataStride
        let offset = vertexSource.dataOffset

        var transformedVertices = [SCNVector3]()

        // Retrieve transformation matrix from the node
        let transformationMatrix = node.worldTransform

        for index in 0..<vertexCount {
            let baseAddress = vertexData.withUnsafeBytes { pointer -> UnsafePointer<Float> in
                pointer.baseAddress!.advanced(by: index * stride + offset).assumingMemoryBound(to: Float.self)
            }
            let vertex = SCNVector3(x: baseAddress.pointee, y: baseAddress.advanced(by: 1).pointee, z: baseAddress.advanced(by: 2).pointee)
            let transformedVertex = vertex.applyingTransformation(transformationMatrix)
            transformedVertices.append(transformedVertex)
        }

        return transformedVertices
    }

    func createHeightMap4(from vertices: [SCNVector3], resolutionX: Int, resolutionZ: Int) -> [[Float]] {
        // Initialize the height map with NaN values
        var heightMap = Array(repeating: Array(repeating: Float.nan, count: resolutionZ), count: resolutionX)

        // Determine bounds for normalization
        let (minX, maxX, minZ, maxZ) = vertices.reduce((Float.infinity, -Float.infinity, Float.infinity, -Float.infinity)) { (bounds, vertex) in
            (min(bounds.0, vertex.x), max(bounds.1, vertex.x), min(bounds.2, vertex.z), max(bounds.3, vertex.z))
        }

        // Populate the height map
        vertices.forEach { vertex in
            // Normalize coordinates to fit within the grid
            let ix = Int(((vertex.x - minX) / (maxX - minX)) * Float(resolutionX - 1))
            let iz = Int(((vertex.z - minZ) / (maxZ - minZ)) * Float(resolutionZ - 1))

            // Check bounds (to handle edge cases where ix or iz might be out of range)
            guard ix >= 0, ix < resolutionX, iz >= 0, iz < resolutionZ else {
                return // Skip this vertex if out of bounds
            }

            // Assign height value using y-coordinate, choose method to handle multiple values (e.g., max, average)
            if heightMap[ix][iz].isNaN {
                heightMap[ix][iz] = vertex.y
            } else {
                // Use the maximum height for overlapping vertices or choose another method like average
                heightMap[ix][iz] = max(heightMap[ix][iz], vertex.y)
            }
        }

        return heightMap
    }
    
    func fillNaNWithClosest(heightMap: inout [[Float]]) {
        let rows = heightMap.count
        let cols = heightMap[0].count
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]  // Directions: right, down, left, up
        var queue = Queue<(Int, Int, Float)>()

        // Enqueue all non-NaN positions
        for i in 0..<rows {
            for j in 0..<cols {
                if !heightMap[i][j].isNaN {
                    queue.enqueue((i, j, heightMap[i][j]))
                }
            }
        }

        // Process the queue
        while !queue.isEmpty {
            if let (x, y, value) = queue.dequeue() {
                for (dx, dy) in directions {
                    let nx = x + dx
                    let ny = y + dy
                    // Ensure the new position is within bounds and is NaN
                    if nx >= 0 && nx < rows && ny >= 0 && ny < cols && heightMap[nx][ny].isNaN {
                        heightMap[nx][ny] = value  // Assign the closest non-NaN value
                        queue.enqueue((nx, ny, value))  // Add the new position to the queue
                    }
                }
            }
        }
    }

    func convertHeightMapToGradient1(heightMap : [[Float]])->([[Float]], Float, Float){
        var gradientHeightMap = Array(repeating: Array(repeating: Float(0), count: heightMap.count), count: heightMap.count)
        var maxPoint : Float = 1
        var minPoint : Float = 0
        for i in 0..<(heightMap.count){
            for j in 0..<(heightMap.count){
                if i != 0 && j != 0 && i != (heightMap.count - 1) && j != (heightMap.count - 1){
                    let gradient_x = (heightMap[i+1][j] - heightMap[i-1][j]) / 2
                    let gradient_z = (heightMap[i][j+1] - heightMap[i][j-1]) / 2
                    let gradientMag = (gradient_x * gradient_x) + (gradient_z * gradient_z)
                    gradientHeightMap[i][j] = gradientMag
                    if gradientMag < minPoint{
                        minPoint = gradientMag
                    }
                    if gradientMag > maxPoint{
                        maxPoint = gradientMag
                    }
                }
            }
        }
        return (gradientHeightMap, minPoint, maxPoint)
    }

    func detectPeaks(heightMap: [[Float]])->[[Float]]{
        let gaussmap = getGaussianSmoothed(heightMap: heightMap, k: 5, sigma: 1)//CHECK
        var newHeightMap = Array(repeating: Array(repeating: Float(0), count: gaussmap.count), count: gaussmap.count)
        //get gaussian
        
        for i in 0..<(gaussmap.count){
            for j in 0..<(gaussmap.count){
                var surrounding : [Float] = []
                if i != 0 && j != 0 && i != (gaussmap.count - 1) && j != (gaussmap.count - 1){
                    let gauss1 = gaussmap[i-1][j-1]
                    let gauss2 = gaussmap[i-1][j]
                    let gauss3 = gaussmap[i-1][j+1]
                    let gauss4 = gaussmap[i][j-1]
                    let gauss5 = gaussmap[i][j+1]
                    let gauss6 = gaussmap[i+1][j-1]
                    let gauss7 = gaussmap[i+1][j]
                    let gauss8 = gaussmap[i+1][j+1]
                    let current = gaussmap[i][j]
                    if (gauss1 < current) && (gauss2 < current) && (gauss3 < current) && (gauss5 < current) && (gauss6 < current) && (gauss7 < current) && (gauss8 < current){
                        print("peak")
                        newHeightMap[i][j] = ((current - gauss1) + (current - gauss2) + (current - gauss3) + (current - gauss4) + (current - gauss5) + (current - gauss6) + (current - gauss7) + (current - gauss8))/Float(8)
                    }
                    else{
                        print(i)
                        print(j)
                        newHeightMap[i][j] = 0
                    }
             //      let gradient_x = (heightMap[i+1][j] - heightMap[i-1][j]) / 2
              //      let gradient_z = (heightMap[i][j+1] - heightMap[i][j-1]) / 2
               //     let gradientMag = (gradient_x * gradient_x) + (gradient_z * gradient_z)
                        //    newHeightMap[i][j] = gradientMag
                }
            }
        }

        //for each value, check if it is greater than k surrounding neighbours. if so, = average height difference, otherwise = 0
        
        return newHeightMap
    }
    
    func convertHeightMapToVertices(heightMap: [[Float]], resolutionX: Int, resolutionZ: Int, minX: Float, maxX: Float, minZ: Float, maxZ: Float) -> [SCNVector3] {
        var vertices: [SCNVector3] = []
        
        for ix in 0..<resolutionX {
            for iz in 0..<resolutionZ {
                let x = minX + Float(ix) / Float(resolutionX - 1) * (maxX - minX)
                let z = minZ + Float(iz) / Float(resolutionZ - 1) * (maxZ - minZ)
                print("x , z :", ix, iz)
                var y = Float(0)
             //   print(heightMap)
                if heightMap[ix][iz] != Float.nan{
                    y = heightMap[ix][iz]
                }
              //  let y = heightMap[ix][iz]
                //if let y = heightMap[ix][iz]{
                    vertices.append(SCNVector3(x, y, z))
               // }
               // else{
                    
              //  }
                
                
            }
        }
        
        return vertices
    }

    func compareVertices(originalVertices: [SCNVector3], heightMapVertices: [SCNVector3]) -> Float {
        //guard originalVertices.count == heightMapVertices.count else {
            print(originalVertices.count)
            print(heightMapVertices.count)
          //  fatalError("Vertex count mismatch")
       // }
        
        var totalDifference: Float = 0.0
        let numVertices = originalVertices.count
        
        for i in 0..<numVertices {
            let originalVertex = originalVertices[i]
            let heightMapVertex = closestDistance(points: heightMapVertices, inputPoint: originalVertex, k: 1)
            
          //  let heightMapVertex = heightMapVertices[i]
            print(i)
            
            let difference = abs(originalVertex.y - heightMapVertex[0].y)
            print(difference)
            totalDifference += difference
        }
        
        let averageDifference = totalDifference / Float(numVertices)
        print("total difference: ", totalDifference)
        print("average difference: ", averageDifference)
        return averageDifference
    }




    
}
extension SCNVector3 {
    func applyingTransformation(_ transform: SCNMatrix4) -> SCNVector3 {
        let glkMatrix = SCNMatrix4ToGLKMatrix4(transform)
        let glkVector = GLKMatrix4MultiplyVector3WithTranslation(glkMatrix, GLKVector3Make(x, y, z))
        return SCNVector3(glkVector.x, glkVector.y, glkVector.z)
    }
}

struct Queue<Element> {
    private var elements: [Element] = []

    mutating func enqueue(_ element: Element) {
        elements.append(element)
    }

    mutating func dequeue() -> Element? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    var isEmpty: Bool {
        elements.isEmpty
    }
}
