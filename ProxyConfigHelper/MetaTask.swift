//
//  MetaTask.swift
//  com.metacubex.ClashX.ProxyConfigHelper


import Cocoa

class MetaTask: NSObject {
    
    struct MetaServer: Encodable {
        let serverAddr: String
        let serverSecret: String
        
        func jsonString() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            guard let data = try? encoder.encode(self),
                  let string = String(data: data, encoding: .utf8) else {
                return ""
            }
            return string
        }
    }
    
    
    let proc = Process()
    var uiPath: String?
    let procQueue = DispatchQueue(label: "com.metacubex.ClashX.ProxyConfigHelper.MetaProcess")
    
    
    @objc func setLaunchPath(_ path: String) {
        proc.executableURL = .init(fileURLWithPath: path)
    }
    
    @objc func setUIPath(_ path: String) {
        uiPath = path
    }
    
    @objc func start(_ confPath: String,
               confFilePath: String,
               result: @escaping stringReplyBlock) {
        
        var resultReturned = false
        
        func returnResult(_ re: String) {
            guard !resultReturned else { return }
            resultReturned = true
            
            DispatchQueue.main.async {
                result(re)
            }
        }
        
        var args = [
            "-d",
            confPath
        ]
        
        if confFilePath != "" {
            args.append(contentsOf: [
                "-f",
                confFilePath
            ])
        }
        
        procQueue.async {
            do {
                if let info = try self.test(confPath, confFilePath: confFilePath) {
                    returnResult(info)
                    return
                } else {
                    print("Test meta config success.")
                }
                
                guard let serverResult = self.parseConfFile(confPath, confFilePath: confFilePath) else {
                    returnResult("Can't decode config file.")
                    return
                }
                
                self.proc.arguments = args
                let pipe = Pipe()
                
                
                pipe.fileHandleForReading.readabilityHandler = { pipe in
                    guard let output = String(data: pipe.availableData, encoding: .utf8) else {
                        return
                    }
                    
                    output.split(separator: "\n").map {
                        self.formatMsg(String($0))
                    }.forEach {
                        if $0.starts(with: "External controller listen error:") || $0.starts(with: "External controller serve error:") {
                            returnResult($0)
                        }
                        
                        /*
                        if let range = $0.range(of: "RESTful API listening at: ") {
                            self.serverAddr = String($0[range.upperBound..<$0.endIndex])
                        }
                         */
                        
                        if $0 == "Apply all configs finished." {
                            returnResult(serverResult.jsonString())
                        }
                    }
                }
                
                
                self.proc.standardOutput = pipe
                
                self.proc.terminationHandler = { _ in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let string = String(data: data, encoding: String.Encoding.utf8) else {
                        
                        returnResult("Meta process terminated, no found output.")
                        return
                    }
                    
                    let results = string.split(separator: "\n").map(String.init).map(self.formatMsg(_:))
                    
                    returnResult(results.joined(separator: "\n"))
                }
                try self.proc.run()
            } catch let error {
                returnResult("Start meta error, \(error.localizedDescription).")
            }
        }
    }

    @objc func stop() {
        DispatchQueue.main.async {
            guard self.proc.isRunning else { return }
            self.proc.interrupt()
        }
    }
    
    func test(_ confPath: String, confFilePath: String) throws -> String? {
        let proc = Process()
        proc.executableURL = self.proc.executableURL
        var args = [
            "-t",
            "-d",
            confPath
        ]
        if confFilePath != "" {
            args.append(contentsOf: [
                "-f",
                confFilePath
            ])
        }
        let pipe = Pipe()
        proc.standardOutput = pipe
        
        proc.arguments = args
        try proc.run()
        proc.waitUntilExit()
        
        guard proc.terminationStatus == 0 else {
            return "Test failed, status \(proc.terminationStatus)"
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let string = String(data: data, encoding: String.Encoding.utf8) else {
            return "Test failed, no found output."
        }
        
        let results = string.split(separator: "\n").map(String.init).map(formatMsg(_:))
        
        guard let re = results.last else {
            return "Test failed, no found output."
        }
        
        if re.hasPrefix("configuration file"),
           re.hasSuffix("test is successful") {
            return nil
        } else if re.hasPrefix("configuration file"),
                  re.hasSuffix("test failed") {
            return results.count > 1
            ? results[results.count - 2]
            : "Test failed, unknown result."
        } else {
            return re
        }
    }
    
    
    func formatMsg(_ msg: String) -> String {
        guard msg.starts(with: "time="),
              let msgRange = msg.range(of: "msg=\"") else {
            return msg
        }
        var re = String(msg[msgRange.upperBound..<msg.endIndex])
        
        while re.last == "\"" || re.last == "\n" {
            re.removeLast()
        }
        
        if re.contains("time=") {
            print(re)
        }
        
        return re
    }
    
    func parseConfFile(_ confPath: String, confFilePath: String) -> MetaServer? {
        let fileURL = confFilePath == "" ? URL(fileURLWithPath: confPath).appendingPathComponent("config.yaml", isDirectory: false) : URL(fileURLWithPath: confFilePath)
        
        guard let data = FileManager.default.contents(atPath: fileURL.path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let lines = content.split(separator: "\n").map(String.init)
        
        let serverAddr = lines.first(where: { $0.starts(with: "external-controller: ") })?.dropFirst("external-controller: ".count) ?? ""
        
        let serverSecret = lines.first(where: { $0.starts(with: "secret: ") })?.dropFirst("secret: ".count) ?? ""
        
        return MetaServer(serverAddr: String(serverAddr),
                          serverSecret: String(serverSecret))
    }
}
