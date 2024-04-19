//
//  HapticChart.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 10/04/2024.
//

import SwiftUI
import Charts

struct HapticChart: View {
    let data : [HapticDataPoint]
    var body: some View {
        Chart{
            ForEach(data) { d in
                PointMark(x: PlottableValue.value("Time", d.time), y: PlottableValue.value("Intensity", d.intensity))
            }
        }
        .padding()
        .chartXAxisLabel("Time (seconds)")//DOUBLE CHECK
        .chartYAxisLabel("Taptic Intensity")
        
    }
}

#Preview {
    HapticChart(data: [])
}
