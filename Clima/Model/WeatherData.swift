//
//  WeatherData.swift
//  Clima
//
//  Created by 内田麻美 on 2022/11/28.
//  Copyright © 2022 App Brewery. All rights reserved.
//

import Foundation

//WeatherDataが戻ってくるための構造体を作成する
//JSONデータを分析して咀嚼できるようにしプロパティ名を割り当ててSwiftオブジェクトに変換する必要があるため。
//「Codable」とは、2つのプロトコルを1つにまとめて両方を一度に追加できるようにすること
struct WeatherData: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
    
}

struct Weather: Codable {
    let description: String
    let id: Int
}
