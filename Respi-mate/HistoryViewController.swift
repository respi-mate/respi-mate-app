//
//  HistoryViewController.swift
//  Respi-mate
//
//  Created by Aishwarya Pattar on 09/03/2019.
//  Copyright © 2019 Aishwarya Pattar. All rights reserved.
//

import UIKit


class HistoryViewController: UIViewController {
    
    @IBOutlet weak var lineChartView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // TODO: receive x and y values from MenuViewController
        
        
        
        // initialises graph upon loading
        setChartValues()
        
        // makes bubbles appear when you click on data
        let marker:BalloonMarker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                                 font: .systemFont(ofSize: 12),
                                                 textColor: .white,
                                                 insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = lineChartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        lineChartView.marker = marker
    }
    
    // TODO: need to modify based on inputs received
    func setChartValues() {
        
        // sets x and y values
        let entries = (0..<time.count).map { (i) -> ChartDataEntry in
            let yVal = y[i]
            let timeVal = time[i]
            return ChartDataEntry(x: timeVal, y: yVal)
        }
        
        let set = LineChartDataSet(values: entries, label: "Breathing")
        let data = LineChartData(dataSet: set)
        self.lineChartView.data = data
        
        // modify line plot
        set.drawCirclesEnabled = false
        set.drawValuesEnabled = false
        set.lineWidth = 2
        
        // modify lineChartView
        self.lineChartView.dragYEnabled = false
        self.lineChartView.rightAxis.enabled = false
        
    }
    
}
