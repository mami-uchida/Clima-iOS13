//
//  WeatherManager.swift
//  Clima
//
//  Created by 内田麻美 on 2022/11/26.
//  Copyright © 2022 App Brewery. All rights reserved.
//

import Foundation
import CoreLocation

//プロトコルは、プロトコルを使用するクラスと同じファイルに作成
protocol WeatherManagerDelegate {
    
    //天気予報マネージャからエラーを受け渡すメソッド
    func didUpdateWeather(_ weatherManager: WeatherManager, weather: WeatherModel)
    
    //WeaherManagerでコードが失敗しそうな時はこのdidFailWithErrorメソッドをトリガー
    //デリゲートに「ここで問題が発生しました」と通知できるようになりWeatherManagerから受け渡すことが出来るようになる
    func didFailWithError(error: Error)
    
}


struct WeatherManager {
    //都市の部分は無しでAPIURLを貼付
    //(都市の部分はユーザーがUITextFieldに入力した内容を使って後々コードを追加）
    let weatherURL = "https://api.openweathermap.org/data/2.5/weather?appid=cf0aeae2f1e73e2ffc72f1d85179a529&units=metric"
    
    //デリゲートをオプショナルのWeatherManagerDelegateとして設定
    //何らかのクラスや構造体がデリゲートとして設定されていればデリゲートを呼び出して天気を更新するように指示が可能
    var delegate: WeatherManagerDelegate?
    
    
    
    //テキストフィールドに入力された都市の天気を取得するためのメソッド
    //WeatherViewControllerの「 weatherManager.fetchWeather(cityName: city)」で実行
    //cityNameを受け取ってurlStringを作成
    func fetchWeather(cityName: String) {
        let urlString = "\(weatherURL)&q=\(cityName)"
        //performRequestを呼び出しこのurlStringを入力として渡しアクセス
        performRequest(with: urlString)
    }
    
    
    //現在の位置情報に基づく温度と天気の状態を取得し表示させるメソッド
    //このfetchWeatherメソッドはlatitude緯度とlongitude経度のパラメータ名を持つ
    func fetchWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        //latitude,longituteを受け取ってurlStringを作成
        let urlString = "\(weatherURL)&lat=\(latitude)&lon=\(longitude)"
        //performRequestを呼び出しこのurlStringを入力として渡しアクセス
        performRequest(with: urlString)
    }
    
    
    
    //気象データを取得するために以下のセッションタスク1〜4を実行する
    //リクエストは urlStringに基づいて行われる
    //2のURLセッションがネットワークワーキングを完了し、3のタスクが完了するとcompletionHandlerが呼び出される
    //URLStringでリクエストを実行し、URLSessionを使ってopenWeatherMapからデータをフェッチ吸うためのネットワーキングを行う
    //そしてデータを解析し天気オブジェクトを作成してデリゲートに返す
    func performRequest(with urlString: String) {
        
        
        // 1. URLを作る(入力として取得したURLの文字列を渡す必要がある）
        //作成されたURLをオプショナルバインディング
        if let url = URL(string: urlString) {
            
            
            // 2. URLセッションを作成
            //sessionという定数を作成しURLSessionオブジェクトを設定
            let session = URLSession(configuration: .default)
            
            
            // 3. セッションにタスクを与える
            //指定されたURLの内容を取得し完了後にハンドラまたはメソッドを呼び出す定数taskを作成(クロージャ)
            let task = session.dataTask(with: url) {(data, response, error) in
                //ifを使ってhandleメソッドの内部でネットワーク処理全体のerrorがnilに等しくなかったら先に進んでエラーを表示
                if error != nil {
                    //デリゲートを渡しdidFailWithErrorを実行しアンラップされたエラーオブジェクトを渡す(クロージャ内なのでself)
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                
                //エラーがなかったらsafeDataと呼ぶlet定数を作成し、オプショナルバインディングを使って戻ってきたデータオブジェクトをアンラップ
                if let safeData = data {
                    //そしてparseJSONメソッドを呼び出し、データオブジェクトとしての要件を満たすこのアンラップされたsafeDataを渡す(クロージャ内なのでself)
                    if let weather = self.parseJSON(safeData) {
                        //セッションタスクが完了するとdidUpdateWeatherを呼び出してその気象データを送信
                        //didUpdateWeatherではnilにならないのでこのオプショナルは通過し
                        //didupdateWeatherをトリガーとしてweatherオブジェクトを入力として渡す(クロージャ内なのでself)
                        self.delegate?.didUpdateWeather(self, weather: weather)
                    }
                }
            }
            
            //4. タスクの開始を完了させる
            //このメソッドはURLSessionのdateTaskを返す。出力を定数コードのタスクとして設定
            task.resume()
        }
    }
    
    
    
    
    
    //OpenWeatherMapからWeatherDataを取得し、JSONレスポンスを渡すためのネットワークコード。
    //「Decodable」とはJSON表現から自分自身をデコードできる型になった事を意味する
    //parseJSONメソッドを呼び出し、データオブジェクトとしての要件を満たすこのアンラップされたsafeDataを渡すことができる
    func parseJSON(_ weatherData: Data) -> WeatherModel? {
        
        // JSONDecoderからdecoder定数を作成
        let decodar = JSONDecoder()
        do {
            //decoderを使ってデコードしていく
            //オブジェクトではなくtype（型）で参照したいので.selfをつけて型で参照
            let decodeData = try decodar.decode(WeatherData.self, from: weatherData)
            let id = decodeData.weather[0].id
            let temp = decodeData.main.temp
            let name = decodeData.name
            
            let weather = WeatherModel(conditionId: id, cityName: name, temperature: temp)
            return weather
            //もしエラーが投げられたとしてもそのエラーをキャッチすることができるcatchを用意する
        } catch {
            //エラーをキャッチして再びデリゲートを呼び出す
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
}
