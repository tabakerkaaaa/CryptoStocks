//
//  CryptoViewController.swift
//  Crypto
//
//  Created by Никита Бабенко on 12/02/2020.
//  Copyright © 2020 Nikita Babenko. All rights reserved.
//

import UIKit
import Charts

struct CandlesInfo: Codable {
    var close: String

    enum CodingKeys: String, CodingKey {
        case close = "close"
    }
}

class CryptoViewController: UIViewController {
    
    var exactCrypto: CryptoInfo?
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var chartHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var noInternetLabel: UILabel!
    
    var activityIndicator: UIActivityIndicatorView?
    
    private var candlesArray: [CandlesInfo] = []
    private var apiURL: String {
        return "https://api.hitbtc.com/api/2/public/candles/\(exactCrypto!.symbol)?period=M30"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lowLabel.text = exactCrypto?.low
        highLabel.text = exactCrypto?.high
        lastLabel.text = exactCrypto?.last
        volumeLabel.text = exactCrypto?.volume
        
        lowLabel.textColor = .gray
        highLabel.textColor = .gray
        volumeLabel.textColor = .gray
        lastLabel.textColor = .gray
        
        chartHeightConstraint.constant = view.frame.width - 50
        chartView.layoutIfNeeded()
        chartView.noDataText = "No internet connection"
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator!.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator!.hidesWhenStopped = true
        self.view.addSubview(activityIndicator!)
        NSLayoutConstraint.activate([
            activityIndicator!.leftAnchor.constraint(equalTo: view.leftAnchor),
            activityIndicator!.rightAnchor.constraint(equalTo: view.rightAnchor),
            activityIndicator!.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                   constant: chartView.frame.height / 2)
        ])
        
        chartView.isHidden = true
        
        activityIndicator!.startAnimating()
        
        getData { [weak self] candlesArray in
            self?.candlesArray = candlesArray as! [CandlesInfo]
            DispatchQueue.main.async {
                self?.activityIndicator?.stopAnimating()
                self?.chartView.isHidden = false
                self?.noInternetLabel.isHidden = true
                self?.refreshButton.isHidden = true
                self?.view.bringSubviewToFront(self!.chartView)
                self?.plotChart()
            }
        }
    }
}

extension CryptoViewController {
    @IBAction func refreshActionByButton(_ sender: UIButton) {
        self.activityIndicator?.startAnimating()
        
        getData { [weak self] candlesArray in
            self?.candlesArray = candlesArray as! [CandlesInfo]
            DispatchQueue.main.async {
                self?.activityIndicator?.stopAnimating()
                self?.chartView.isHidden = false
                self?.noInternetLabel.isHidden = true
                self?.refreshButton.isHidden = true
                self?.view.bringSubviewToFront(self!.chartView)
                self?.plotChart()
            }
        }
    }
}

extension CryptoViewController {
    private func plotChart() {
        var lineChartEntry  = [ChartDataEntry]()
        
        for i in 0..<candlesArray.count {
            let value = ChartDataEntry(x: Double(i), y: Double(candlesArray[i].close)!)
            lineChartEntry.append(value)
        }
        
        let line = LineChartDataSet(entries: lineChartEntry, label: "Close price")
        let gradientColors = [UIColor.cyan.cgColor, UIColor.clear.cgColor] as CFArray
        let colorLocations:[CGFloat] = [1.0, 0.0]
        let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)
        line.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
        line.drawFilledEnabled = true
        line.drawCirclesEnabled = false
        line.colors = [NSUIColor.blue]
        
        let data = LineChartData()
        data.addDataSet(line)
        

        chartView.data = data
        chartView.chartDescription?.text = "Last \(self.title!) price chart"
    }
}

extension CryptoViewController: NetworkingProtocol {
    internal func getData(completionHandler: @escaping ([Any]) -> ()) {
        if let url = URL(string: apiURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data {
                    do {
                        let readData = try JSONDecoder().decode([CandlesInfo].self, from: data)
                        completionHandler(readData)
                    } catch let error {
                        self?.showError()
                        print(error.localizedDescription)
                    }
                }
                if let error = error {
                    self?.showError()
                    print(error.localizedDescription)
                }
            }.resume()
        }
    }
    
    internal func showError() {
        DispatchQueue.main.async { [weak self] in
            self?.view.bringSubviewToFront(self!.noInternetLabel)
            self?.view.bringSubviewToFront(self!.refreshButton)
            self?.view.setNeedsDisplay()
            self?.activityIndicator?.stopAnimating()
            self?.chartView.isHidden = false
            self?.noInternetLabel.isHidden = false
            self?.refreshButton.isHidden = false
        }
    }
}
