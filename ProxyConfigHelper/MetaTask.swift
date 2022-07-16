//
//  MetaTask.swift
//  com.metacubex.ClashX.ProxyConfigHelper


import Cocoa

class MetaTask: NSObject {
    
    struct MetaServer: Encodable {
        let externalController: String
        let secret: String
        var log: String = ""
        
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
        
        if let uiPath = uiPath {
            args.append(contentsOf: [
                "-ext-ui",
                uiPath
            ])
        }
        
        killOldProc()
        
        procQueue.async {
            do {
                if let info = self.test(confPath, confFilePath: confFilePath) {
                    returnResult(info)
                    return
                } else {
                    print("Test meta config success.")
                }
                
                guard var serverResult = self.parseConfFile(confPath, confFilePath: confFilePath) else {
                    returnResult("Can't decode config file.")
                    return
                }
                
                self.proc.arguments = args
                let pipe = Pipe()
                var logs = [String]()
                
                pipe.fileHandleForReading.readabilityHandler = { pipe in
                    guard let output = String(data: pipe.availableData, encoding: .utf8),
                          !resultReturned else {
                        return
                    }
                    
                    output.split(separator: "\n").map {
                        self.formatMsg(String($0))
                    }.forEach {
                        logs.append($0)
                        if $0.contains("External controller listen error:") || $0.contains("External controller serve error:") {
                            returnResult($0)
                        }
                        
                        /*
                        if let range = $0.range(of: "RESTful API listening at: ") {
                            let addr = String($0[range.upperBound..<$0.endIndex])
                            guard addr.split(separator: ":").count == 2,
                                  let port = Int(addr.split(separator: ":")[1]) else {
                                returnResult("Not found RESTful API port.")
                                return
                            }
                            let test = self.testListenPort(port)
                            if test.pid != 0,
                               test.pid == self.proc.processIdentifier,
                               test.addr == addr {
                                serverResult.log = logs.joined(separator: "\n")
                                returnResult(serverResult.jsonString())
                            } else {
                                returnResult("Check RESTful API pid failed.")
                            }
                        }
                         */
                        
                        if $0.contains("Apply all configs finished.") {
                            serverResult.log = logs.joined(separator: "\n")
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
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                    serverResult.log = logs.joined(separator: "\n")
                    returnResult(serverResult.jsonString())
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
            let proc = Process()
            proc.executableURL = .init(fileURLWithPath: "/bin/kill")
            proc.arguments = ["-9", "\(self.proc.processIdentifier)"]
            try? proc.run()
            proc.waitUntilExit()
        }
    }
    
    @objc func test(_ confPath: String, confFilePath: String) -> String? {
        do {
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
        } catch let error {
            return "\(error)"
        }
    }
    
    func killOldProc() {
        let proc = Process()
        proc.executableURL = .init(fileURLWithPath: "/usr/bin/killall")
        proc.arguments = ["com.metacubex.ClashX.ProxyConfigHelper.meta"]
        try? proc.run()
        proc.waitUntilExit()
    }
    
    func testListenPort(_ port: Int) -> (pid: Int32, addr: String) {
        let proc = Process()
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.executableURL = .init(fileURLWithPath: "/bin/bash")
        proc.arguments = ["-c", "lsof -nP -iTCP:\(port) -sTCP:LISTEN | grep LISTEN"]
        try? proc.run()
        proc.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let str = String(data: data, encoding: .utf8),
              str.split(separator: " ").map(String.init).count == 10 else {
            return (0, "")
        }
        
        let re = str.split(separator: " ").map(String.init)
        let pid = re[1]
        let addr = re[8]
        
        return (Int32(pid) ?? 0, addr)
    }
    
    
    func formatMsg(_ msg: String) -> String {
        let msgs = msg.split(separator: " ", maxSplits: 2).map(String.init)
        
        guard msgs.count == 3,
              msgs[1].starts(with: "level"),
              msgs[2].starts(with: "msg") else {
            return msg
        }
        
        let level = msgs[1].replacingOccurrences(of: "level=", with: "")
        var re = msgs[2].replacingOccurrences(of: "msg=\"", with: "")
        
        while re.last == "\"" || re.last == "\n" {
            re.removeLast()
        }
        
        if re.contains("time=") {
            print(re)
        }
        
        return "[\(level)] \(re)"
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
        
        return MetaServer(externalController: String(serverAddr),
                          secret: String(serverSecret))
    }
}
