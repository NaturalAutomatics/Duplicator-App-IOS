//
//  ContentView.swift
//  duplicator
//
//  Created by Yury Noyanov on 28.11.2022.
//

import SwiftUI
import CoreNFC


struct ResultView: View {
    var choice: String

    var body: some View {
        Text("You chose \(choice)")
    }
}

class LoggingData: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var _isLogged = false
    
    @Published var _image:UIImage? = nil
    @Published var _text1:String = ""
    @Published var _text2:String = ""
    
    var _messageURL:URL? = nil
    var _model:ModelData? = nil
    var _startPrintResult:StartPrintResult? = nil
    
    var _session: NFCNDEFReaderSession?
    
    var _timer:Timer? = nil
    var _isInAsking = false;

    
    func startScan() {
        guard NFCReaderSession.readingAvailable else {
            return
        }
        
        _session = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
        _session?.alertMessage = "Hold your device near a tag to scan it."
        _session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if var string = String(data: record.payload, encoding: .utf8) {
                    string = string.replacingOccurrences(of:"\u{04}", with:"https://")
                    if let url = URL(string:string) {
                        _messageURL = url
                        updateInterface(url: url)
                    } else {
                        _text2 = string
                    }
                }
            }
        }
        session.invalidate()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let s = error.localizedDescription.description
        print(error.localizedDescription)
        if(s == "Session invalidated by user") {
            return
        }
        //text2.text = error.localizedDescription
    }
    
    func test() {
        let url = URL(string:"https://tests.noyanov.ru/getModelData.php?id=123")!
        updateInterface(url:url)
    }
    
    func updateInterface(url:URL) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async() { [weak self] in
                    self?._text2 = error.localizedDescription
                }
                return
            }
            if let jsonData = data {
                print(jsonData)
                let decoder = JSONDecoder()
                do {
                    let s = String(data: jsonData, encoding: String.Encoding.utf8)
                    //print(s)
                    let model = try decoder.decode(ModelData.self, from: jsonData)
                    print(model)
                    self._model = model
                    DispatchQueue.main.async() { [weak self] in
                        self?._text1 = model.name
                        self?._text2 = model.description
                    }
                    
                    if(!model.imgUrl.hasSuffix("/")) {
                        model.imgUrl = "/" + model.imgUrl
                    }
//                    var components = URLComponents()
//                    components.scheme = url.scheme
//                    components.host = url.host
//                    components.path = model.imgUrl
//                    var url1 = components.url
                    let url3 = URL(string: model.imgUrl, relativeTo: url)
                    if let url3 = url3 {
                        self.downloadImage(from: url3)
                    }
                } catch {
                    //DispatchQueue.main.async() { [weak self] in
                    self._text2 = error.localizedDescription
                    //}
                }
            }
        }
        task.resume()
    }
    
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            if let error = error {
                //DispatchQueue.main.async() { [weak self] in
                    self._text2 = error.localizedDescription
                //}
                return
            }
            guard let data = data else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            // always update the UI from the main thread
            DispatchQueue.main.async() { [weak self] in
                self?._image = UIImage(data: data)
            }
        }
    }
    
    func startDuplicate() {
        let id:String = _model?.id ?? ""
        let url = URL(string:"https://tests.noyanov.ru/api/models/startPrintModel.php?id="+id)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                //DispatchQueue.main.async() { [weak self] in
                self._text2 = error.localizedDescription
                //}
                return
            }
            if let jsonData = data {
                print(jsonData)
                do {
                    let s = String(data: jsonData, encoding: String.Encoding.utf8)
                    print(s)
                    let result = try JSONDecoder().decode(StartPrintResult.self, from: jsonData)
                    self._startPrintResult = result
                                        
                    DispatchQueue.main.async() { [weak self] in
                        self?._text2 = result.status
                        self?.startAskStatusTimer()
                    }
                } catch {
                    DispatchQueue.main.async() { [weak self] in
                        self?._text2 = error.localizedDescription
                    }
                }
            }
        }
        task.resume()
    }
    
    func startAskStatusTimer() {
        //_timer = Timer(timeInterval: 3, repeats: true) { _ in self.askStatus() }
        _timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.askStatus), userInfo: nil, repeats: true)
    }
    
    @objc
    func askStatus() {
        if(_isInAsking){
            return // just didn't read previous asking result
        }
        let id:Int = _startPrintResult?.session ?? 0
        let url = URL(string:"https://tests.noyanov.ru/api/models/getPrintResult.php?id="+String(id))!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            self._isInAsking = true
            if let error = error {
                //DispatchQueue.main.async() { [weak self] in
                self._text2 = error.localizedDescription
                //}
                self._isInAsking = false
                return
            }
            if let jsonData = data {
                print(jsonData)
                do {
                    let s = String(data: jsonData, encoding: String.Encoding.utf8)
                    print(s)
                    let result = try JSONDecoder().decode(StartPrintResult.self, from: jsonData)
                    self._startPrintResult = result
                    
                    DispatchQueue.main.async() { [weak self] in
                        self?._text2 = result.status
                    }
                } catch {
                    DispatchQueue.main.async() { [weak self] in
                        self?._text2 = error.localizedDescription
                        self?._timer?.invalidate()
                        self?._timer = nil
                    }
                }
            }
            self._isInAsking = false
        }
        task.resume()

    }

}

struct ContentView: View {
    @StateObject var _loginData = LoggingData()
    var body: some View {
        VStack {
            if(!_loginData._isLogged) {
                LoginView()
            } else {
                DuplicateView()
            }
        }
        .environmentObject(_loginData)
    }
}

struct LoginView : View {
    @EnvironmentObject var _loginData: LoggingData
    @State var _login:String = ""
    @State var _password:String = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Wellcome to Duplicator application.")
            Text("At first you need authorize you with your login and password.")
            TextField("Login:", text: $_login)
            TextField("Password:", text: $_password)
            
            Button("Login", action: {
                _loginData._isLogged = true
            })
            
            Text("Or use Sign up to register")
            Button("Sign up", action: {
                _loginData._isLogged = true
            })
        }
    }
}


struct DuplicateView : View {
    @EnvironmentObject var _loginData: LoggingData

    var body: some View {
        VStack() {
            HStack {
                Button("<< Back", action: {
                    _loginData._isLogged = false
                })
                Spacer()
            }
            Spacer()
            if let image = _loginData._image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
            }
            Spacer()
            Text(_loginData._text1)
            Text( _loginData._text2)
            Spacer()
            Button((_loginData._model != nil) ? "Duplicate" : "Scan NFC", action: {
                duplicate()
            })
            Spacer()
        }
    }
    
    func duplicate() {
        if(_loginData._model == nil) {
            _loginData.startScan()
        } else {
            _loginData.startDuplicate()
        }
    }
    
    

    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
