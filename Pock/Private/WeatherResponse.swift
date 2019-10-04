//
//  WeatherResponse.swift
//  Pock
//
//  Created by Yusuf Özgül on 3.10.2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

import Foundation

struct WeatherResponse: Codable {
    let conditionsshort : Conditionsshort?
        let fcsthourly24short : Fcsthourly24short?
        let fcstdaily10short : Fcstdaily10short?
        let monthlyalmanac : Monthlyalmanac?
        let nowlinks : Nowlinks?
        let metadata : Metadata?

        enum CodingKeys: String, CodingKey {

            case conditionsshort = "conditionsshort"
            case fcsthourly24short = "fcsthourly24short"
            case fcstdaily10short = "fcstdaily10short"
            case monthlyalmanac = "monthlyalmanac"
            case nowlinks = "nowlinks"
            case metadata = "metadata"
        }

    }
struct Almanac_summaries : Codable {
    let avg_hi : Int?
    let avg_lo : Int?
    let record_hi : String?
    let record_hi_yr : String?
    let record_lo : String?
    let record_lo_yr : String?

    enum CodingKeys: String, CodingKey {

        case avg_hi = "avg_hi"
        case avg_lo = "avg_lo"
        case record_hi = "record_hi"
        case record_hi_yr = "record_hi_yr"
        case record_lo = "record_lo"
        case record_lo_yr = "record_lo_yr"
    }

}

struct Conditionsshort : Codable {
    let metadata : Metadata?
    let observation : Observation?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case observation = "observation"
    }
}

struct Fcstdaily10short : Codable {
    let metadata : Metadata?
    let forecasts : [Forecasts]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case forecasts = "forecasts"
    }

}

struct Fcsthourly24short : Codable {
    let metadata : Metadata?
    let forecasts : [Forecasts]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case forecasts = "forecasts"
    }

}
struct Forecasts : Codable {
    let classa : String?
    let dow : String?
    let fcst_valid : Int?
    let fcst_valid_local : String?
    let imperial : Imperial?
    let metric : Metric?
    let moonrise : String?
    let moonset : String?
    let moon_phase : String?
    let moon_phase_code : String?
    let num : Int?
    let sunrise : String?
    let sunset : String?
    let night : Night?
    let iconName: String?

    enum CodingKeys: String, CodingKey {

        case classa = "class"
        case dow = "dow"
        case fcst_valid = "fcst_valid"
        case fcst_valid_local = "fcst_valid_local"
        case imperial = "imperial"
        case metric = "metric"
        case moonrise = "moonrise"
        case moonset = "moonset"
        case moon_phase = "moon_phase"
        case moon_phase_code = "moon_phase_code"
        case num = "num"
        case sunrise = "sunrise"
        case sunset = "sunset"
        case night = "night"
        case iconName = "phrase_32char"
    }

}

struct Imperial : Codable {
    let wspd : Int?
    let temp : Int?

    enum CodingKeys: String, CodingKey {

        case wspd = "wspd"
        case temp
    }

}

struct Links : Codable {
    let ios : String?
    let mobile : String?
    let web : String?

    enum CodingKeys: String, CodingKey {

        case ios = "ios"
        case mobile = "mobile"
        case web = "web"
    }

}
struct Metadata : Codable {
    let language : String?
    let transaction_id : String?
    let version : String?
    let latitude : Double?
    let longitude : Double?
    let expire_time_gmt : Int?
    let status_code : Int?

    enum CodingKeys: String, CodingKey {

        case language = "language"
        case transaction_id = "transaction_id"
        case version = "version"
        case latitude = "latitude"
        case longitude = "longitude"
        case expire_time_gmt = "expire_time_gmt"
        case status_code = "status_code"
    }
}

struct Metric : Codable {
    let wspd : Int?
    let temp : Int?

    enum CodingKeys: String, CodingKey {

        case wspd = "wspd"
        case temp
    }
}
struct Monthlyalmanac : Codable {
    let metadata : Metadata?
    let almanac_summaries : [Almanac_summaries]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case almanac_summaries = "almanac_summaries"
    }

}
struct Night : Codable {
    let alt_daypart_name : String?
    let daypart_name : String?
    let fcst_valid : Int?
    let fcst_valid_local : String?
    let icon_cd : Int?
    let icon_extd : Int?
    let long_daypart_name : String?
    let num : Int?
    let phrase_12char : String?
    let phrase_22char : String?
    let phrase_32char : String?
    let pop : Int?
    let precip_type : String?
    let rh : Int?
    let uv_desc : String?
    let uv_index : Int?
    let wdir : Int?
    let wdir_cardinal : String?
    let metric : Metric?
    let imperial : Imperial?

    enum CodingKeys: String, CodingKey {

        case alt_daypart_name = "alt_daypart_name"
        case daypart_name = "daypart_name"
        case fcst_valid = "fcst_valid"
        case fcst_valid_local = "fcst_valid_local"
        case icon_cd = "icon_cd"
        case icon_extd = "icon_extd"
        case long_daypart_name = "long_daypart_name"
        case num = "num"
        case phrase_12char = "phrase_12char"
        case phrase_22char = "phrase_22char"
        case phrase_32char = "phrase_32char"
        case pop = "pop"
        case precip_type = "precip_type"
        case rh = "rh"
        case uv_desc = "uv_desc"
        case uv_index = "uv_index"
        case wdir = "wdir"
        case wdir_cardinal = "wdir_cardinal"
        case metric = "metric"
        case imperial = "imperial"
    }
}

struct Nowlinks : Codable {
    let metadata : Metadata?
    let links : Links?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case links = "links"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata)
        links = try values.decodeIfPresent(Links.self, forKey: .links)
    }

}
struct Observation : Codable {
    let classa : String?
    let valid_time_gmt : Int?
    let imperial : Imperial?
    let metric : Metric?
    let obs_id : String?
    let obs_name : String?
    let pressure_desc : String?
    let pressure_tend : Int?
    let qualifier : String?
    let rh : Int?
    let uv_desc : String?
    let uv_index : Int?
    let wdir : Int?
    let wdir_cardinal : String?
    let wx_icon : Int?
    let wx_phrase : String?

    enum CodingKeys: String, CodingKey {

        case classa = "class"
        case valid_time_gmt = "valid_time_gmt"
        case imperial = "imperial"
        case metric = "metric"
        case obs_id = "obs_id"
        case obs_name = "obs_name"
        case pressure_desc = "pressure_desc"
        case pressure_tend = "pressure_tend"
        case qualifier = "qualifier"
        case rh = "rh"
        case uv_desc = "uv_desc"
        case uv_index = "uv_index"
        case wdir = "wdir"
        case wdir_cardinal = "wdir_cardinal"
        case wx_icon = "wx_icon"
        case wx_phrase = "wx_phrase"
    }

}

