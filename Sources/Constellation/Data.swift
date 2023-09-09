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
            public let battery: Float?
            public let gsmLevel: Float?
            public let gpsLevel: Float?
            public let engineTemperature: Float?
            public let moduleTemperature: Float?
            
            enum CodingKeys: String, CodingKey {
                case battery = "battery"
                case gsmLevel = "gsm_lvl"
                case gpsLevel = "gps_lvl"
                case engineTemperature = "etemp"
                case moduleTemperature = "ctemp"
            }
        }
        public struct State: Decodable {
            public let door: Bool?
            public let alarm: Bool?
            public let valet: Bool?
            public let stayHome: Bool?
            public let arm: Bool?
            public let parkingBrake: Bool?
            public let ignition: Bool?
            public let trunk: Bool?
            public let hood: Bool?
            public let hijack: Bool?
            public let additionalSensorBypass: Bool?
            public let shockBypass: Bool?
            public let tiltBypass: Bool?
            public let running: Bool?
            
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
        public struct OBD: Decodable {
            public let remainingDistance: Int?
            
            enum CodingKeys: String, CodingKey {
                case remainingDistance = "dist_to_empty"
            }
        }
        
        public let deviceId: Int
        public let alias: String?
        public let common: Common?
        public let state: State?
        public let obd: OBD?
        
        enum CodingKeys: String, CodingKey {
            case deviceId = "device_id"
            case alias = "alias"
            case common = "common"
            case state = "state"
            case obd = "obd"
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
    public let devices: [Device]?
    public let data: Data?
    
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
