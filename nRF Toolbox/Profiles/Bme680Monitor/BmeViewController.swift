///*
//* Copyright (c) 2020, Nordic Semiconductor
//* All rights reserved.
//*
//* Redistribution and use in source and binary forms, with or without modification,
//* are permitted provided that the following conditions are met:
//*
//* 1. Redistributions of source code must retain the above copyright notice, this
//*    list of conditions and the following disclaimer.
//*
//* 2. Redistributions in binary form must reproduce the above copyright notice, this
//*    list of conditions and the following disclaimer in the documentation and/or
//*    other materials provided with the distribution.
//*
//* 3. Neither the name of the copyright holder nor the names of its contributors may
//*    be used to endorse or promote products derived from this software without
//*    specific prior written permission.
//*
//* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//* POSSIBILITY OF SUCH DAMAGE.
//*/
//
//

import UIKit
import CoreBluetooth
import UserNotifications
import Charts
//
//private extension Identifier where Value == Section {
//    static let bme680Value: Identifier<Section> = "bme680Value"
//    static let bme680Chart: Identifier<Section> = "bme680Chart"
//    static let chartSection: Identifier<Section> = "ChartSection"
//}
//
//
extension Identifier where Value == UNNotification {
    static let bmeNotification: Identifier<Self> = "Identifier.UNNotification.bme"
}
class BmeViewController: PeripheralViewController,ChartViewDelegate{
    @IBOutlet var TemperatureCharts: LineChartView!
    @IBOutlet var PressureCharts: LineChartView!
    @IBOutlet var HumidityCharts: LineChartView!
    @IBOutlet var GasResistCharts: LineChartView!
    var xValue = 0

    @IBOutlet private var disconnectBtn: NordicButton!
    @IBOutlet private var handshakeBtn: NordicButton!
    @IBOutlet private var indicateBtn: NordicButton!

    override var peripheralDescription: PeripheralDescription { .bme680 }
    override var navigationTitle: String { "BME680" }
    
    private var peripheralManager: CBPeripheralManager!
    var bmeHandshakeChar: CBCharacteristic!

    private var timer: Timer?
    private var handshakeEnabled: Bool = false
    private var indicateEnabled: Bool = false
    
    @IBAction func bmeHandshake() {
        guard let bmeHandshakeChar = self.bmeHandshakeChar else {
            return
        }
        var val : UInt8 = handshakeEnabled ? 2 : 1
        let data = Data(bytes: &val, count: 1)
        self.activePeripheral?.writeValue(data, for: bmeHandshakeChar, type: CBCharacteristicWriteType.withoutResponse)

        handshakeEnabled.toggle()
        let title = handshakeEnabled ? "ON" : "OFF"
        handshakeBtn.setTitle(title, for: .normal)
    }

    @IBAction func disconnectAction() {
        disconnect()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        handshakeBtn.style = .mainAction
        disconnectBtn.style = .destructive
        indicateBtn.style = .mainAction
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        chartSettings(lineChart: TemperatureCharts  , label:"Temperature"   )
        chartSettings(lineChart: PressureCharts     , label:"Pressure"      )
        chartSettings(lineChart: HumidityCharts     , label:"Humidity"      )
        chartSettings(lineChart: GasResistCharts    , label:"Gas Resistance")
        TemperatureCharts.extraLeftOffset = 20
        HumidityCharts.extraLeftOffset = 20
        bmeUrlSession()
    }
    func chartSettings(lineChart: LineChartView,label: String) {
        lineChart.delegate = self
        let set_a: LineChartDataSet = LineChartDataSet(entries:[ChartDataEntry(x: Double(0), y: Double(0))], label: label)
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.red)
        set_a.drawValuesEnabled = false
        
        lineChart.xAxis.labelPosition = .bottom
        lineChart.leftAxis.granularityEnabled = true
        lineChart.rightAxis.drawLabelsEnabled = false
        lineChart.pinchZoomEnabled = true
        lineChart.doubleTapToZoomEnabled = false
        lineChart.data = LineChartData(dataSets: [set_a])

    }
    func bmeUrlSession() {
        let url = URL(string: "https://ne1-bme680-sensor.herokuapp.com/")
        //let url = URL(string: "https://www.muryou-tools.com/test/posttestutf8.php")
//        let request = URLRequest(url: url!)
//        let session = URLSession.shared
//        session.dataTask(with: request) { (data, response, error) in
//            if error == nil, let data = data, let response = response as? HTTPURLResponse {
//                // HTTPヘッダの取得
//                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
//                // HTTPステータスコード
//                print("statusCode: \(response.statusCode)")
//                print(String(data: data, encoding: String.Encoding.utf8) ?? "")
//            }
//        }.resume()
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let str: NSString = "abc" as NSString
        let myData: NSData = str.data(using: String.Encoding.utf8.rawValue)! as NSData
        request.httpBody = myData as Data
//        request.setValue("abc",forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                print("statusCode: \(response.statusCode)")
                print(String(data: data, encoding: String.Encoding.utf8) ?? "")
            }
        }
        task.resume()
    }

    func updateCounter(bmeCharts: LineChartView,yValue: UInt32) {
//        if (bmeCharts.data?.entryCount)! > 15 {
//            bmeCharts.data?.removeEntry(xValue: 0, dataSetIndex: 0)
//        }
        if(xValue == 1){
            bmeCharts.data?.removeEntry(xValue: 0, dataSetIndex: 0)
        }
        bmeCharts.data?.appendEntry(ChartDataEntry(x: Double(xValue), y: Double(yValue)), toDataSet: 0)
        
//        bmeCharts.setVisibleXRangeMinimum(5)
        bmeCharts.notifyDataSetChanged()
        
    }
    
    
    override func didDiscover(characteristic: CBCharacteristic, for service: CBService, peripheral: CBPeripheral) {
        super.didDiscover(characteristic: characteristic, for: service, peripheral: peripheral)
        switch (service.uuid, characteristic.uuid) {
//        case (.bmeService, .bmeHandshake):
//            bmeHandshakeChar = characteristic
//            self.handshakeBtn.isEnabled = true
        case (.bme680Service, .bme680HandshakeChar):
            bmeHandshakeChar = characteristic
            self.handshakeBtn.isEnabled = true
            var val = UInt8(0)
            let data = Data(bytes: &val, count: 1)
            peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
//        case (.txPowerLevelService, .txPowerLevelCharacteristic):
//            peripheral.readValue(for: characteristic)
        default:
            break
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            SystemLog(category: .ble, type: .error).log(message: "Did not write characteristic \(characteristic), error: \(error.debugDescription)")
            return
        }
    }

    override func didUpdateValue(for characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case .bme680MeasChar:
            indicateEnabled.toggle()
            let title = indicateEnabled ? "ind ON" : "ind OFF"
            indicateBtn.setTitle(title, for: .normal)
            
            let data: bme680MeasurementCharacteristic
            do {
                data = try bme680MeasurementCharacteristic(with: characteristic.value!, date: Date())
            } catch let error {
                displayErrorAlert(error: error)
                return
            }
//            SystemLog(category: .ble, type: .debug).log(message: "characteristic \(data.index)")
            xValue = xValue + 1
            updateCounter(bmeCharts: TemperatureCharts  ,yValue: data.temperature)
            updateCounter(bmeCharts: PressureCharts     ,yValue: data.pressure)
            updateCounter(bmeCharts: HumidityCharts     ,yValue: data.humidity)
            updateCounter(bmeCharts: GasResistCharts    ,yValue: data.gasresist)

//            do {
//                batterySection.update(with: try BatteryCharacteristic(with: data))
//                reloadSection(id: .battery)
//            } catch let error {
//                displayErrorAlert(error: error)
//            }
//        case .txPowerLevelCharacteristic:
//            let value: Int8? = try? characteristic.value?.read()
//            txValue = value.map(Int.init)
//            self.update(rssi: rssi, txValue: txValue)
        default:
            super.didUpdateValue(for: characteristic)
        }
    }

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)
        switch status {
//        case .connected(_):
//            self.activePeripheral?.readRSSI()
        case .disconnected, .poweredOff:
//            timer?.invalidate()
//            txValue = nil
//            rssi = nil
//
//            rssiView.filledBars = 0
//            distanceView.unfilledSectors = distanceView.numberOfSectors
//            distanceLabel.text = "Unknown"

            handshakeBtn.isEnabled = false
        default:
            break
        }
    }

}

extension BmeViewController: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            let service = CBMutableService(type: .bme680Service, primary: true)
            let characteristic = CBMutableCharacteristic(
                type: .bme680HandshakeChar,
                properties: .writeWithoutResponse,
                value: nil,
                permissions: .writeable)
            service.characteristics = [characteristic]
            peripheralManager.add(service)
        default:
            break
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let attributeRequest = requests.first,
              attributeRequest.characteristic.uuid == .bme680HandshakeChar else {
            return
        }

    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        SystemLog(category: .ble, type: .debug).log(message: "Will Restore characteristic: \(dict)")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            SystemLog(category: .ble, type: .error).log(message: error.localizedDescription)
        } else {
            SystemLog(category: .ble, type: .debug).log(message: "added service: \(service.debugDescription)")
        }
    }


//override func viewDidLoad() {
//    super.viewDidLoad()
//    handshakeBtn.style = .mainAction
//    disconnectBtn.style = .destructive
//    indicateBtn.style = .mainAction
//    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
//    chartSettings(lineChart: TemperatureCharts)
//    chartSettings(lineChart: PressureCharts)
//    chartSettings(lineChart: HumidityCharts)
//    chartSettings(lineChart: GasResistCharts)
//
//}
//
//
//
//
//var i = 1
//func updateCounter(bmeChar: bme680MeasurementCharacteristic) {
////        let number1 = Int.random(in: 0 ... 100)
//
//    if (self.bmeCharts.data?.entryCount)! > 5 {
//        self.bmeCharts.data?.removeEntry(xValue: 0, dataSetIndex: 0)
//    }
//
////        self.bmeCharts.data?.appendEntry(ChartDataEntry(x: Double(i), y: Double(number1)), toDataSet: 0)
//    self.bmeCharts.data?.appendEntry(ChartDataEntry(x: Double(i), y: Double(bmeChar.temperature)), toDataSet: 0)
//
//    self.bmeCharts.setVisibleXRange(minXRange: 1, maxXRange: 5)
//    self.bmeCharts.notifyDataSetChanged()
//    i = i + 1
//}

}
