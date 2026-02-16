//
//  main.swift
//  tcpMon
//
//  Created by Louis Milne on 2/5/26.
//

import Foundation
import RegexBuilder
import Compression

///Description: this table converts from the character representation of a digit to the numerical representation of the digit.
let hexDigitToNumber: [Character : UInt8] = [
    "0" : 0,
    "1" : 1,
    "2" : 2,
    "3" : 3,
    "4" : 4,
    "5" : 5,
    "6" : 6,
    "7" : 7,
    "8" : 8,
    "9" : 9,
    "a" : 0xa,
    "b" : 0xb,
    "c" : 0xc,
    "d" : 0xd,
    "e" : 0xe,
    "f" : 0xf,
]

///This option shows an expected set of arguments provided to tcpdump before calling this program.
let SampleTcpDumpOptions = "tcpdump -i en0 -x 'port 853 or port 443' -nn"


if CommandLine.arguments.count > 1 {
    parseArguments(CommandLine.arguments)
}

readDataFromFile()

///Description: This function continually reads from standard input / file to interpret new packet data.
///Expects the -X flag, which gives a hex representation of the packet contents.
func readDataFromFile() {
    var packetCaptureAggregation: [String : [UInt8]] = [:]
    var currentLine = readLine(strippingNewline: true)
    
    while ((currentLine != nil) && !currentLine!.isEmpty) {
        var packetData: [UInt8] = []
        //first element is timestamp, second element is IP designation, third is the source IP + port info, fourth shows traffic direction in one character, fifth is destination IP + port info
        
        let currentLineParts = currentLine!.split(separator: " ")
        var individualConnection : String
        
        if currentLineParts[2] < currentLineParts[4] {
            individualConnection = currentLineParts[2] + " " + currentLineParts[4]
        } else {
            individualConnection = currentLineParts[2] + " " + currentLineParts[4]
        }
        
        while (true) {
            let strOptional = readLine(strippingNewline: true)
            if strOptional == nil {
                break
            }
            let str = strOptional!
            if str.isEmpty || (str[str.startIndex] != "\t") {
                currentLine = str
                break
            }
            
            let colonIndex = str.firstIndex(of: ":")!
            let firstIndexOfHexDigit = str.index(colonIndex, offsetBy: 3)
            let hexDigitView = str[firstIndexOfHexDigit...]

            //Changes the character representation of digits into numbers:
            var i = hexDigitView.startIndex
            while (true) {
                let hexDigit1 : Character = hexDigitView[i]
                let hexDigit2 : Character = hexDigitView[hexDigitView.index(i, offsetBy: 1)]
                
                let byteValue = getByteFromTwoHexDigit(hexDigit1: hexDigit1, hexDigit2: hexDigit2)
                // add to packetData
                packetData.append(byteValue)
                
                i = hexDigitView.index(i, offsetBy: 2)
                if i == hexDigitView.endIndex {
                    break
                }
                if hexDigitView[i] == " " {
                    i = hexDigitView.index(i, offsetBy: 1)
                }
            }
        }
        
        if packetCaptureAggregation[individualConnection] == nil {
            packetCaptureAggregation.updateValue(packetData, forKey: individualConnection)
        } else {
            packetCaptureAggregation[individualConnection]!.append(contentsOf: packetData)
        }
        
        if packetCaptureAggregation[individualConnection]!.count > 1000 {
            let compressionRatio = getCompressionRatio(data: packetCaptureAggregation[individualConnection]!)
            print(individualConnection)
            print("Compression ratio is:\u{001B}[36m \(compressionRatio.rounded())%\u{001B}[0m") //Cyan output text
            
            /*print dictionary contents:
             for (name, path) in packetCaptureAggregation {
                    print("Connection to '\(name)' is '\(path)'.")
            }*/
        }
       
            


    }
}
/// - Parameters:
/// - packetData - UInt8 array of the packetdata contents
func printContents(_ packetData: [UInt8]) {
    //ToDo
}

/// Description: parses command line arguments provided to tcpmon
///-v Verbose: Print packet header and data
/// - Parameters:
/// - arguments: the command line arguments provided to the program at runtime.
func parseArguments(_ arguments: [String]){

    let arguments = CommandLine.arguments
    for i in arguments {
        print(i)
    }
    
    print("Got here")
}

///Description: Calls gzip to compress the packet data, returns an
///- Parameters:
/// - packetData - UInt8 array of the packetdata contents
/// - Returns:
/// - Integer error or sucess code depending on operation.
func callGZipExecutable(_ packetData: [UInt8]) -> Int {
    let process = Process()
    let pipeOut = Pipe()
    let pipeIn = Pipe()
    
    process.standardOutput = pipeOut
    process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
    process.arguments = ["-c", "-9", "-q"]
    process.standardInput = pipeIn
    //gzip args args: "-1, -q, -c ") //-1: fast compression, -q: quiet to suppress stderr, -c output will go to stdout
    // can also use -f to get the compressed data to the terminal, otherwise it will expect to dump output to a file.

    
    do {
        let standardInputWritingStream = pipeIn.fileHandleForWriting
        try standardInputWritingStream.write(contentsOf: packetData)
        try standardInputWritingStream.close()

        try process.run()
        process.waitUntilExit()

        let gzipOutputStream = pipeOut.fileHandleForReading;
        if let gzipOutputRawData = try gzipOutputStream.readToEnd() {
            
            /*//return gzipOutputRawData.count
            for i in gzipOutputRawData.startIndex ... gzipOutputRawData.endIndex - 1 {
                print(gzipOutputRawData[i], terminator: " ")
            }
            print("")*/
            
            //print(Data(gzipOutputRawData).base64EncodedString())
            
            return gzipOutputRawData.count
        }
    } catch {
        // TODO: Deal with errors.
    }
    return -1
}

///Description: Returns a compression ratio of the compressed size verses the uncompressed size.
func getCompressionRatio(data: [UInt8]) -> Float {
    let compressedSize = callGZipExecutable(data)
    let uncompressedSize = data.count
    
    return (Float(compressedSize) / Float(uncompressedSize)) * 100
}


///Description: This function converts from a character representation of the packet contents to a numerical representation.
func getByteFromTwoHexDigit(hexDigit1: Character, hexDigit2: Character) -> UInt8 {
    let number1 = hexDigitToNumber[hexDigit1]!
    let number2 = hexDigitToNumber[hexDigit2]!
    return(number1 * 16 + number2)
}


