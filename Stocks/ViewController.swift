//
//  ViewController.swift
//  Stocks
//
//  Created by Владислав on 28.08.2020.
//  Copyright © 2020 Murygin Vladislav. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
]
    private lazy var companies =  [
                    "Apple": "AAPL"
                ]
    

    @IBOutlet var companyNameLabel: UILabel!
    @IBOutlet var companyPickerView: UIPickerView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var companySymbolLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var priceChangeLabel: UILabel!
    @IBOutlet var companyIconImage: UIImageView!
    @IBOutlet var mainScreenView: UIView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        companiesRequest()
    
        companyNameLabel.text = "Tinkoff"
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.hidesWhenStopped = true
      
        requestQuoteUpdate()
        
        
    }
    
    private func requestQuoteUpdate(){
        activityIndicator.startAnimating()
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black

        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
 
        
        
    }
    
    private func companiesRequest() {
        
        let token = "pk_7f54c2b074b34ed399519c24d6f39560"
        var companiesList: [String:String] = [:]
        
        guard let url = URL(string: "https://cloud.iexapis.com/beta/ref-data/symbols?token=\(token)") else { return}
        
        let dataTask = URLSession.shared.dataTask(with: url) {(data,respose, error) in
            if let data = data,
                (respose as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                do {
                    let jsoneObject = try JSONSerialization.jsonObject(with: data)
                    guard
                        let json = jsoneObject as? NSArray
                        else {return print("Invalid JSON") }
                    
                    for index in 0..<json.count {
                        let item = json[index] as? NSDictionary
                        let  symbol = item!["symbol"] as! String
                        let  name = item!["name"] as! String
                     
                        companiesList.updateValue(symbol, forKey: name)
                        
                    }
                    self.companies = companiesList
                     
                    DispatchQueue.main.async {
                    self.companyPickerView.reloadAllComponents()
                        self.requestQuoteUpdate()
                    }

                } catch {
                    print("JSON parsing erroe")
                }
            } else {
                print("JSON parsing erroe")
            }
        }
        dataTask.resume()
    }
    
    private func requestQuote(for symbol: String) {
        let token = "pk_7f54c2b074b34ed399519c24d6f39560"
        
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) {(data,respose, error) in
            if let data = data,
                (respose as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self.parseQuote(from: data)
                DispatchQueue.main.async {
                    self.companyIconImage.image = self.imagUrlToImage(symbol: symbol)
                }
            }else{
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка!", message: "Загрузка данный не удалась. Проверьте интернет. ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        dataTask.resume()
        
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsoneObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsoneObject as? [String:Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
                else {return print("Invalid JSON") }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            print("JSON parsing erroe:" + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "(\(priceChange))"
        
        if priceChange > 0 {
            priceChangeLabel.textColor = .green
        } else if   priceChange < 0 {
            priceChangeLabel.textColor = .red
        } else {
            priceChangeLabel.textColor = .black
        }
    }
    
    private func imagUrlToImage (symbol: String)-> UIImage? {
        let fullImageUrl = "https://storage.googleapis.com/iex/api/logos/\(symbol).png"
        let imageUrl = URL(string: fullImageUrl)!
        let imageData = try! Data(contentsOf: imageUrl)
        return UIImage(data: imageData)
    }
    
}


extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
}

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
    
}

