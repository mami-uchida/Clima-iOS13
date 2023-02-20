//
//  ViewController.swift
//  Clima
//
//  Created by Angela Yu on 01/09/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreLocation

//UITextViewDelegateを追加することによって、自身のクラスつまり天気予報のビューコントローラーがテキストフィールドのテキスト編集と検証を管理することができるようになる。
//WeatherManagerDelegateも追加する必要がある。なぜならdidUpdateWeatherメソッドをすでに実装しているから。
class WeatherViewController: UIViewController {
    
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    //WeatherNanager構造体の（）を初期化
    var weatherManager = WeatherManager()
    //携帯電話のGPS位置情報を取得する役割を担っている
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //locationManagerに登録できるようにそしてrequestLocationが実際にこのメソッドをトリガーしたときに応答できるように現在のクラスをデリゲートとして設定しなければならない
        //そしてlocationManagerで位置情報をを受け取るためには現在のクラスをlocationManagerのデリゲートとして設定する必要がある
        //requestLocationの実行前にこの一行を入れるとアプリがクラッシュしない。
        locationManager.delegate = self
        
        //locationManagerを使うために最初に許可要求を出さなければならない
        //以下の一行を追加するとユーザーに許可を求めるポップアップ画面がでる
        locationManager.requestWhenInUseAuthorization()
        
        //位置情報を要求(このメソッドは現在地を一度だけ配信するよう要求する、というもの）
        //ユーザーがアプリを使用中ずっとターンバイターンの位置データが必要な場合、代わりにstartUpdatingLocationというメソッドを使用するとよい）
        locationManager.requestLocation()
        
        
        
        
        
        //この現在のクラスをデリゲートとして設定する必要がある
        //そうするとweatherManagerのdelegateはnilにならない
        weatherManager.delegate = self
        
        //selfは現在のビューコントローを指す。
        //delegateを現在のクラスとして設定し、
        //テキストフィールドで何が起こっておるのかを伝えることができるという考え方。
        searchTextField.delegate = self
    }
}



//MARK: - UITextFieldDelegate

extension WeatherViewController: UITextFieldDelegate {
    //「検索ボタン」を押下することによってテキストフィールドに入力された文字にアクセスするコード。
    //(※これだけだとキーボード上のgoを押下してもアクセスはできない）
    @IBAction func searchPressed(_ sender: UIButton) {
        //[endEditing]メソッドを追加して[true]に設定すると検索フィールドに編集が終わった事を伝えることができるようになってキーボードを解除をできる（引っ込められる）
        searchTextField.endEditing(true)
    }
    //キーボードの「go」を押下することによってテキストフィールドに入力された文字にアクセスするコード。
    //「textFieldShouldReturn」とは現在のクラスであるデリゲートに、テキストフィールドがリターンボタンの押下を処理すべきかどうかを問い合わせるもの。
    //返り値を実際に処理すべきかどうかをテキストフィールドに伝えるためにtrue,falseを返さなければならない。
    //今回の場合リターンボタンのIBActionのように使う。goを押した瞬間この中括弧内の処理が読み込まれる。
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //[endEditing]メソッドを追加して[true]に設定すると検索フィールドに編集が終わった事を伝えることができるようになってキーボードを解除をできる（引っ込められる）
        searchTextField.endEditing(true)
        return true
    }
    //テキストフィールドが空文字列まま検索が行われようとしている時に、何をするか？
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        //早期リターンで前提条件を満たしているかチェックし、満たしていなけばreturnで抜ける
        //テキストフィールドが空文字列でなければ検索を続行
        guard let text = textField.text, text.isEmpty else { return true }
        //空文字列だったらプレイスホルダー（テキストフィールドのこと）で警告。
        textField.placeholder = "Type something here."
        return false
    }
    
    //検索が終わったらテキストフィールドの文字を消すコード。
    //[textFieldDidEndEditing]はユーザーが編集が終わったことを知り、中括弧内の処理を読み込まれる。
    func textFieldDidEndEditing(_ textField: UITextField) {
        //クリアにする直前にsearchTextField.textを使ってその都市の天気を取得する
        //ちなみにWeatherManagerに渡すのはオプショナルな文字列ではなく確定した文字列なのでif letを使ってアンラップ.
        //これによってcityプロパティは適切な文字列となりweatherManagerを呼び出す際に使えるようになった。
        if let city = searchTextField.text {
            //WeatherManagerのfetchWeatherメソッドを実行し、その都市の天気を呼び出す。
            weatherManager.fetchWeather(cityName: city)
        }
        //クリアにする
        searchTextField.text = ""
    }
}


//MARK: - WeatherManagerDelegate

extension WeatherViewController:WeatherManagerDelegate {
    //取得した気象データを各々に表示
    //以下の関数を作成するとWeatherModelオブジェクトをweatherとして渡すことができる
    func didUpdateWeather(weather: WeatherModel) {
        
        //取得中のデータのネットワーク状況でエラーが出ないようDispatchQueueをつける。
        DispatchQueue.main.async {
            //まずtemperatureLabelへの表示
            //クロージャ内なのでselfが必要。
            self.temperatureLabel.text = weather.temperatureString
            //conditionImageViewへの表示
            //UIKitからくるユーザーインターフェイスの画像が設定されるのでシステム名と呼ばれるものを使って初期化する.
            //WeatherViewControllerでこのconditionNameを利用することでconditionImageViewに入れるインターフェイスの画像を出力することができる。
            self.conditionImageView.image = UIImage(systemName: weather.conditionName)
            self.cityLabel.text = weather.cityName
        }
    }
    
    //これでWeatherManagerを使用中に発生したエラーを処理できるようになる。
    func didFailWithError(error: Error) {
        print(error)
    }
}

//MARK: - CLLocationManagerDelegate

extension WeatherViewController:CLLocationManagerDelegate {
    
    //locationPressedボタンでlocationManagerの位置情報を使って天気を取得し表示を変更する
    @IBAction func locationPressed(_ sender: UIButton) {
        //requestLocationを取得し、最高神のトリガーとして再度呼び出し天気を取得する
        locationManager.requestLocation()
    }
    
    //アプリが起動するとすぐlocationManagerが場所を見つけてメソッドをトリガーする
    //locations（CLLocationの配列）も手に入れることができる
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //lastはオプショナルなのでバインドしてアンラップする必要がある
        if let location = locations.last {
            //アプリをロードしし天気を把握したらlocationManagerを停止できるようにする一行。
            locationManager.stopUpdatingLocation()
            //その場所となる緯度・経度の定数を作成する
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            //WeatherManagerのfetchWeatherを実行させる]
            //このメソッドを呼び出して天気データを取得できるようにした。データの取得に成功するとデータがdidUpdateWeatherDelegateメソッドの中に戻ってくる。
            //そしてtemperatureLabelとconditionImageViewを更新することができる
            weatherManager.fetchWeather(latitude: lat, longitude: lon)
            
        }
    }
    
    //このメソッドはエラーがあった場合プリントするメソッド。
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        
    }
}
