//
//  APIManager.swift
//  i-aint-reading-all-that
//
//  Created by Bram Adams on 4/13/23.
//

import Foundation
import Alamofire
import KeychainSwift

class APIManager {
    static let shared = APIManager()
    private let openAIURL = "https://api.openai.com/v1"
    private let keychain = KeychainSwift()
    var apiKey: String {
            get {
                return keychain.get("openai_api_key") ?? ""
            }
            set {
                keychain.set(newValue, forKey: "openai_api_key")
            }
        }

    private init() {}

    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]

        let url = "\(openAIURL)/audio/transcriptions"
        

        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(fileURL, withName: "file")
            multipartFormData.append("whisper-1".data(using: .utf8)!, withName: "model")
        }, to: url, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let transcription = json["text"] as? String {
                    completion(.success(transcription))
                } else {
                    print(value)
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func chatAPI(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let url = "\(openAIURL)/chat/completions"
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "summarize the following text into bullet points"],
                ["role": "user", "content": prompt]
            ]
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], let choices = json["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let text = message["content"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func summarizeToBulletPoints(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        chatAPI(prompt: "Summarize this text into bullet points. Retain first person voice: \(text)", completion: completion)
    }
}
