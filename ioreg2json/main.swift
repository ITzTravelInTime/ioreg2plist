//
//  main.swift
//  ioreg2json
//
//  Created by ITzTravelInTime on 14/02/22.
//

import Foundation
import TINUIORegistry
import TINUSerialization

extension Dictionary: FastEncodable where Key == String, Value == Any {
    
}

extension Dictionary: GenericEncodable where Key == String, Value == Any{
    
}

let toolVersion = "1.0.0"
let toolName = "ioreg2plist"
let toolAuthor = "ITzTravelInTime (Pietro Caruso)"
let toolCopyright = "Copyright (c) 2022 Pietro Caruso (ITzTravelInTime)"

let args = CommandLine.arguments
let acount = CommandLine.arguments.count
let path = FileManager.default.currentDirectoryPath

func main() -> Int32{
    
    enum OutputFormat{
        case json
        case plist
    }
    
    var format: OutputFormat = .json
    var endlessArgs: [String]? = nil
    var jumpArg: Bool = false
    var file: URL? = nil
    
    if acount <= 1{
        printHelp()
        return 0
    }
    
    for i in 1..<acount{
        
        let arg = args[i]
        let narg: String? = (i < acount - 1) ? args[i + 1] : nil
        
        if endlessArgs != nil{
            endlessArgs?.append(arg)
            continue
        }
        
        if jumpArg{
            jumpArg.toggle()
            continue
        }
        
        
        if acount == 2{
            switch arg{
            case "-i", "-info", "--info":
                print(toolName + " version " + toolVersion)
                print("Made by: " + toolAuthor)
                print("Copyright: " + toolCopyright)
                return 0
            case "-v", "-version", "--version":
                print(toolVersion)
                return 0
            case "-h", "-help", "--help":
                printHelp()
                return 0
            default:
                print("Invalid arg: \(arg)!!")
                return 1
            }
        }
        
        switch arg{
        case "-plist", "-p":
            format = .plist
            continue
        case "-d", "-device":
            endlessArgs = []
            continue
        case "-f":
            jumpArg.toggle()
            
            if narg == nil || (narg?.isEmpty ?? true){
                print("Invalid file path!")
                return 1
            }
            
            var farg = narg!
            
            if farg.starts(with: "\""){
                farg = String(farg.dropFirst())
            }
            
            if farg.last == "\""{
                farg = String(farg.dropLast())
            }
            
            if !(farg.starts(with: "~") || farg.starts(with: ".")) && !farg.contains("/"){
                farg = path + "/" + farg
            }
            
            file = URL(fileURLWithPath: farg, isDirectory: false)
            
            if file!.path == path{
                print("Invalid path specified!")
                return 1
            }
            
            continue
        default:
            print("Invalid arg: \(arg)!!")
            return 1
        }
        
    }
    
    if endlessArgs == nil || endlessArgs == []{
        print("No ioregistry objects specified")
    }
    
    let iterator = IORecursiveIterator()
    var res = [String: Any]()
    
    while iterator.next(){
        guard let entry = iterator.entry else{
            continue
        }
        
        guard let name = entry.getName() else{
            continue
        }
        
        if !endlessArgs!.contains(name) {
            continue
        }
        
        guard var val = entry.getPropertyTable() else{
            continue
        }
        
        /*
        check: for i in val{
            guard let dat = i.value as? NSData else{
                continue check
            }
            
            val[i.key] = Data(dat).base64EncodedString(options: .init())
        }
        */
         
        res[name] = val
    }
    
    print(res.plist())
    
    return 0
}

func printHelp(){
    print("Usage: ioreg2json [-plist] [-f [file name]] [-d [device names]]")
    print("Example usage: ioreg2json -d RTC TMR PNP0B00")
    print("Do ioreg2json -h to print this messange")
}

exit(main())
