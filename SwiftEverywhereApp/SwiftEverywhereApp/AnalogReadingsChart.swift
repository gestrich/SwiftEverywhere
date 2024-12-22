//
//  AnalogReadingsChart.swift
//  SwiftEverywhereApp
//
//  Created by Bill Gestrich on 12/21/24.
//

import Charts
import SECommon
import SwiftUI

struct AnalogReadingsChart: View {
    let analogState: AnalogInputState
    var body: some View {
        VStack(alignment: .trailing) {
            Chart {
                ForEach(analogState.readings) { (reading: AnalogValue) in
                    LineMark(
                        x: .value("Date", reading.uploadDate),
                        y: .value("Reading", analogState.configuration.displayableValue(reading: reading.value))
                    )
                }
            }
            .chartXAxis {
                AxisMarks(format: Date.FormatStyle.dateTime.hour(),
                          values: .automatic(desiredCount: 8))
            }
            .chartYScale(domain: analogState.chartYRange())
        }
    
    }
}
