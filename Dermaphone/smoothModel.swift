//
//  smoothModel.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 29/04/2024.
//

import UIKit
import SceneKit
import Foundation

class smoothModel{
    func convertPointCloud(pointCloud : [SCNVector3]) -> [[[Double]]]{
        //INPUT = the pointcloud for the model in the form of a list of SCNvectors
        var smoothedModel = [[[Double]]]()
        for point in pointCloud{
            //in the form [(x,y,z)}] -> [[
        }
        return smoothedModel
        //output = the pointcloud for the smoothed model in the form of a list of SCNvectors
    }
    func convertToPointCloud(coordinates: [SCNVector3]) -> [[[Float]]]? { // Check if the list of coordinates is empty
        guard !coordinates.isEmpty else { return nil // Return nil if the list is empty } // Find the maximum absolute coordinate value in each dimension
            let maxCoordinateX = coordinates.map { abs($0.x) }.max() ?? 0.0
            
            let maxCoordinateY = coordinates.map { abs($0.y) }.max() ?? 0.0
            let maxCoordinateZ = coordinates.map { abs($0.z) }.max() ?? 0.0 // Determine the maximum dimension among X, Y, and Z
            let maxDimension = max(maxCoordinateX, max(maxCoordinateY, maxCoordinateZ)) // Calculate the grid size based on the maximum dimension
            let gridSize = Int(maxDimension) + 1 // Add 1 to ensure all coordinates fit within the grid // Convert coordinates to a 3D point cloud using the calculated grid size\
            let newCloud = convertWithGrid(coordinates: coordinates, gridSize: gridSize)
            return newCloud
        }
        return nil
    }
        
    func convertWithGrid(coordinates: [SCNVector3], gridSize: Int) -> [[[Float]]] {
        var pointCloud = [[[Float]]](repeating: [], count: gridSize)
        
        for position in coordinates {
            let gridX = Int(position.x) + gridSize / 2
            let gridY = Int(position.y) + gridSize / 2
            let gridZ = Int(position.z) + gridSize / 2
            
            if gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize && gridZ >= 0 && gridZ < gridSize {
                pointCloud[gridX].append([position.x,position.y,position.z])
            }
        }
        return pointCloud
    }
    
    func generateKernel(kernelSize: Int, sigma: Double) -> [[[Double]]]{
        var kernel = [[[Double]]]()
        let mean = Double(kernelSize - 1) / 2.0//what is mean?
        
        for z in 0...kernelSize{
            var kernelZ = [[Double]]()
            
            for y in 0...kernelSize {
                var kernelY = [Double]()
                
                for x in 0...kernelSize {
                    let exponent = -(pow(Double(x)-mean, 2) + (pow(Double(y)-mean, 2)) + (pow(Double(z)-mean, 2)) / (2 * pow(sigma, 2)))
                    let value = exp(exponent) / pow(2 * Double.pi * pow(sigma, 2), 1.5)
                    kernelY.append(value)
                }
                kernelZ.append(kernelY)
            }
            kernel.append(kernelZ)
        }
        return kernel
    }
    
    func normaliseKernel(_ kernel: [[[Double]]]) -> [[[Double]]] {//fix to account for negative x values
        var normalizedKernel = kernel
        let totalSum = kernel.flatMap { $0.flatMap { $0 }}.reduce(0,+)
        
        for z in 0...kernel.count {
            for y in 0...kernel[z].count {
                for x in 0...kernel[z][y].count{
                    normalizedKernel[x][y][z] /= totalSum
                }
            }
        }
        return normalizedKernel
    }
    
    func applyGaussianSmoothing(pointcloud: [[[Float]]], kernel: [[[Double]]]) -> [[[Float]]] {
        let kernelSize = kernel.count
        let halfKernelSize = kernelSize / 2
        print("pointcloud", pointcloud)
        let cloudSizeX = pointcloud.count
        let cloudSizeY = pointcloud[0].count//check that they are all the same size
        let cloudSizeZ = pointcloud[0][0].count
        var smoothedCloud = [[[Float]]](repeating: [[Float]](repeating: [Float](repeating: 0.0, count: cloudSizeZ), count: cloudSizeY), count: cloudSizeX)
        print(pointcloud)
        for x in 0...cloudSizeX - 1{
            for y in 0...cloudSizeY - 1{
                for z in 0...cloudSizeZ - 1{
                    
                    var smoothedVal :Float = 0.0
                    
                    for i in 0...kernelSize - 1{
                        for j in 0...kernelSize - 1 {
                            for k in 0...kernelSize - 1 {
                                let indexX = x + i - halfKernelSize
                                let indexY = y + i - halfKernelSize
                                let indexZ = z + i - halfKernelSize
                                
                                if (indexX >= 0 && indexX < cloudSizeX && indexY >= 0 && indexY < cloudSizeY && indexZ >= 0 && indexZ < cloudSizeZ) {
                                    print("index")
                                    print(i)
                                    print(j)
                                    print(k)
                                    print("kernel size", kernel.count)
                                    print("pointcloud size", pointcloud.count)
                                    smoothedVal += pointcloud[indexX][indexY][indexZ] * Float(kernel[i][j][k])
                                
                                }
                            }
                        }
                    }
                    smoothedCloud[x][y][z] = smoothedVal
                }
            }
        }
        return smoothedCloud
    }
}

//convert to pointcloud
//generate kernel
//normalise kernel
//apply gaussiansmoothing
