//
//  HapticChart.swift
//  Dermaphone
//
//  Created by Ewan, Aleera C on 10/04/2024.
//

import SwiftUI
import Charts

struct HapticChart: View {
    /*var data = [
        HapticDataPoint(intensity: 1.0, time: 0),
        HapticDataPoint(intensity: 0.9, time: 0.1),
        HapticDataPoint(intensity: 0.8, time: 0.2),
        HapticDataPoint(intensity: 0.8, time: 0.3),
        HapticDataPoint(intensity: 0.9, time: 0.4),
        HapticDataPoint(intensity: 0.4, time: 0.5),
        HapticDataPoint(intensity: 0.6, time: 0.6),
        HapticDataPoint(intensity: 0.7, time: 0.7),
        HapticDataPoint(intensity: 0.8, time: 0.8),
        HapticDataPoint(intensity: 0.4, time: 0.9),
        HapticDataPoint(intensity: 1.0, time: 1.0),
        HapticDataPoint(intensity: 0.9, time: 1.1),
        HapticDataPoint(intensity: 0.9, time: 1.2)
    ]*/
    let data : [HapticDataPoint]
    var body: some View {
        Chart{
            ForEach(data) { d in
                BarMark(x: PlottableValue.value("Time", d.time), y: PlottableValue.value("Intensity", d.intensity))
            }
        }
        .padding()
    }
}

#Preview {
    HapticChart(data: [])
}
