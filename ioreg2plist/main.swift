//
//  main.swift
//  ioreg2json
//
//  Created by ITzTravelInTime on 14/02/22.
//

import Foundation
import TINUIORegistry

let toolVersion = "1.0.0"
let toolName = "ioreg2plist"
let toolAuthor = "ITzTravelInTime (Pietro Caruso) with the help of dreamwhite"
let toolCopyright = "Copyright (c) 2022 Pietro Caruso (ITzTravelInTime)"

let args = CommandLine.arguments
let acount = CommandLine.arguments.count
let path = FileManager.default.currentDirectoryPath

func main() -> Int32{
    var endlessArgs: [String: Bool]? = nil
    var jumpArg: Bool = false
    var file: URL? = nil
    var matchType: MatchType = .all
    
    if acount <= 1{
        printHelp()
        return 0
    }
    
    for i in 1..<acount{
        
        let arg = args[i]
        let narg: String? = (i < acount - 1) ? args[i + 1] : nil
        
        if endlessArgs != nil{
            endlessArgs![arg] = false
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
        case "-n", "-nameonly", "--nameonly":
            if matchType != .all{
                print("Match type already specified. If you want to get metches for both the name property and the entry name, delete all type specification args. Otherwise just remove the duplicate specification argument.")
                return 1
            }
            
            matchType = .nodeNameOnly
            continue
        case "-p", "-namepropertyonly", "--namepropertyonly":
            if matchType != .all{
                print("Match type already specified. If you want to get metches for both the name property and the entry name, delete all type specification args. Otherwise just remove the duplicate specification argument.")
                return 1
            }
            
            matchType = .namePropertyOnly
            continue
        case "-d", "-device", "-devices", "-entries", "-entry", "--device", "--devices", "--entries", "--entry":
            endlessArgs = [:]
            continue
        case "-f", "-file", "-path":
            
            if file != nil{
                print("File path specified more than one time!!")
                return 1
            }
            
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
            
            if farg.starts(with: "./"){
                farg.removeFirst(2)
                farg = path + "/" + farg
            }else if !(farg.starts(with: "~") || farg.starts(with: ".")) && !farg.contains("/"){
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
    
    if endlessArgs == nil{
        print("No ioregistry objects specified")
        return 1
    }
    
    guard let result = iokitScan(forProperties: endlessArgs!, matchType: matchType) else{
        return 1
    }
    
    guard let plist = result.plist() else{
        print("Impossible to get a plist conversion of the obtained data")
        return 1
    }
    
    print(plist)
    
    if let f = file{
        do{
            try plist.write(toFile: f.path, atomically: true, encoding: .utf8)
        }catch let err{
            print("Error writing data to file: \(err.localizedDescription)")
            return 1
        }
    }
    
    return 0
}

func printHelp(){
    print("Usage: ioreg2plist [-f [file name]] [-d [device names]]")
    print("Example usage: ioreg2plist -d PNP0B00")
    print("Do ioreg2plist -h to print this messange")
}

func iokitScan(forProperties oproperties: [String: Bool], matchType: MatchType) -> [ReturnType]?{
    
    var properties = oproperties
    
    if properties.isEmpty{
        print("No properties specified!")
        return nil
    }
    
    let iterator = IORecursiveIterator()
    var res = [ReturnType]()
    
    while iterator.next(){
        guard let entry = iterator.entry else{
            continue
        }
        
        guard let name = entry.getEntryName() else{
            continue
        }
        
        if properties[name] != nil && matchType.checkEntryName{
           properties[name] = true
        }else if let dname = entry.getNameProperty(), matchType.checkNameProperty{
            if properties[dname] == nil{
                continue
            }
            
            properties[dname] = true
        }else{
            continue
        }
        
        guard let val = entry.getPropertyTable() else{
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
        
        let ret: [String: Any] = [name: val]
         
        res.append(ret)
    }
    
    var notFound: [String] = []
    
    for i in properties{
        if !i.value{
            notFound.append(i.key)
        }
    }
    
    if !notFound.isEmpty && notFound.count != properties.count{
        print("No matches found for the following entries: \(notFound)")
        return nil
    }else if res.isEmpty{
        print("No matches found for all the specified entries")
        return nil
    }
    
    return res
}

exit(main())
