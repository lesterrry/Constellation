//
//  Data.swift
//  
//
//  Created by aydar.media on 24.07.2023.
//

import Foundation

struct SlidResponse: Decodable {
    struct Desc: Decodable {
        let id: String?
        let code: String?
        let token: String?
        let message: String?
        let userToken: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case code = "code"
            case token = "token"
            case message = "message"
            case userToken = "user_token"
        }
    }
    
    let state: Int
    let desc: Desc
}

public struct ApiResponse: Decodable {
    public struct Device: Decodable {
        public struct Common: Decodable {
            let battery: Float?
            let gsmLevel: Float?
            let gpsLevel: Float?
            
            enum CodingKeys: String, CodingKey {
                case battery = "battery"
                case gsmLevel = "gsm_lvl"
                case gpsLevel = "gps_lvl"
            }
        }
        public struct State: Decodable {
            let door: Bool?
            let alarm: Bool?
            let valet: Bool?
            let stayHome: Bool?
            let arm: Bool?
            let parkingBrake: Bool?
            let ignition: Bool?
            let trunk: Bool?
            let hood: Bool?
            let hijack: Bool?
            let additionalSensorBypass: Bool?
            let shockBypass: Bool?
            let tiltBypass: Bool?
            let running: Bool?
            
            enum CodingKeys: String, CodingKey {
                case door = "door"
                case alarm = "alarm"
                case valet = "valet"
                case stayHome = "stay_home"
                case arm = "arm"
                case parkingBrake = "pbrake"
                case ignition = "ign"
                case trunk = "trunk"
                case hood = "hood"
                case hijack = "hijack"
                case additionalSensorBypass = "add_sens_bpass"
                case shockBypass = "shock_bpass"
                case tiltBypass = "tilt_bpass"
                case running = "run"
            }
        }
        let deviceId: Int
        let alias: String?
        let common: Common?
        let state: State?
        
        enum CodingKeys: String, CodingKey {
            case deviceId = "device_id"
            case alias = "alias"
            case common = "common"
            case state = "state"
        }
    }
    
    public enum Data: Decodable {
        case device(Device)
        public init(from decoder: Decoder) throws {
            if let deviceValue = try? decoder.singleValueContainer().decode(Device.self) { self = .device(deviceValue); return }
            
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "Value can't be decoded")
        }
    }
    
    // TODO: Removed due to type mismatch across requests
    // let code: String
    let codestring: String
    let realplexorId: String?
    let userId: String?
    let devices: [Device]?
    let data: Data?
    
    enum CodingKeys: String, CodingKey {
        case codestring = "codestring"
        case realplexorId = "realplexor_id"
        case userId = "user_id"
        case devices = "devices"
        case data = "data"
    }
}

extension ApiResponse.Data: CustomStringConvertible {
    public var description: String {
        switch self {
        case .device(let device):
            return "Device(device_id: \(device.deviceId), alias: \(device.alias ?? "Nil"))"
        }
    }
}
