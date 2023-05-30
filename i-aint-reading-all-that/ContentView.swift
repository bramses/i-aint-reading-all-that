import SwiftUI
import AVFoundation
import KeychainSwift

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder!
    @State private var bulletPoints: String = ""
    @State private var apiKey: String = APIManager.shared.apiKey
    @State private var isApiKeyVisible = false
    @State private var isLoading = false

    private let keychain = KeychainSwift()

    var body: some View {
        VStack {
            HStack {
                    if isApiKeyVisible {
                        TextField("Paste your API key here", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Paste your API key here", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }

                    Button(action: {
                        isApiKeyVisible.toggle()
                    }) {
                        Image(systemName: isApiKeyVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding()

                Button(action: {
                    APIManager.shared.apiKey = apiKey
                }) {
                    Text("Save API Key")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()

            Text("i aint reading all that")
                .font(.title)
            ScrollView {
                Text(bulletPoints)
            }
            .padding()

            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
                isRecording.toggle()
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()

            Button(action: {
                UIPasteboard.general.string = bulletPoints
            }) {
                Text("Copy to Clipboard")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
            if isLoading {
                            ActivityIndicator(style: .large)
                        }
            
        }
    }
    
    func startRecording() {
            let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder.record()
            } catch {
                print("Could not start recording")
            }
        }

    func stopRecording() {
            audioRecorder.stop()
            isLoading = true

            APIManager.shared.transcribeAudio(fileURL: audioRecorder.url) { result in
                switch result {
                case .success(let transcription):
                    APIManager.shared.summarizeToBulletPoints(text: transcription) { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            switch result {
                            case .success(let summary):
                                bulletPoints = summary
                            case .failure(let error):
                                print("Error summarizing text: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        isLoading = false
                        print("Error transcribing audio: \(error)")
                    }
                }
            }
        }

        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
