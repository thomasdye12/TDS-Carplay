//
//  HTTPServer.swift
//  TDS Video
//
//  Created by Thomas Dye on 16/04/2025.
//

import Swifter
import UIKit



//<div id="controls">
//    <label>Rotate: <input type="range" min="0" max="360" value="0" id="rotateRange" /></label>
//    <label style="margin-left: 20px;">Scale: <input type="range" min="0.1" max="2" step="0.1" value="1" id="scaleRange" /></label>
//    <button id="fitToggle">Toggle Fit/Fill</button>
//</div>
class HTTPServer {
    
    static var shared = HTTPServer()
    var isRunning = false
    
    let server = HttpServer()
    
    init () {
  
    }
    
    let html = """
    <html>
    <head>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            background: black;
            height: 100%;
            overflow: hidden;
        }
        #canvas {
            display: block;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: black;
        }
        #controls {
            position: fixed;
            top: 10px;
            left: 10px;
            z-index: 10;
            background: rgba(0,0,0,0.6);
            padding: 10px;
            color: white;
            font-family: sans-serif;
            border-radius: 8px;
        }
    </style>
    </head>
    <body>
        <canvas id="canvas"></canvas>

        <script>
            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');
            const img = new Image();

            let rotation = 0; // 0, 90, 180, 270 only
            let scale = 1;
            let fitMode = "fill"; // default to fill, can toggle later

            const rotateButton = document.createElement('button');
            rotateButton.textContent = "Rotate";
            rotateButton.onclick = () => {
                rotation = (rotation + 90) % 360;
            };

       img.onload = () => {
           const screenWidth = window.innerWidth;
           const screenHeight = window.innerHeight;

           const imgW = img.width;
           const imgH = img.height;

           const isRotated = rotation % 180 !== 0;

           // Swap screen dimensions if rotated
           const displayWidth = isRotated ? screenHeight : screenWidth;
           const displayHeight = isRotated ? screenWidth : screenHeight;

           // Calculate scale to fit (contain behavior)
           const scale = Math.min(displayWidth / imgW, displayHeight / imgH);

           const drawWidth = imgW * scale;
           const drawHeight = imgH * scale;

           // Resize canvas to final drawn dimensions
           canvas.width = drawWidth;
           canvas.height = drawHeight;

           ctx.save();
           ctx.clearRect(0, 0, canvas.width, canvas.height);

           ctx.translate(drawWidth / 2, drawHeight / 2);
           ctx.rotate(rotation * Math.PI / 180);

           // drawImage with swapped dimensions if rotated
           if (isRotated) {
               ctx.drawImage(img, -imgH / 2 * scale, -imgW / 2 * scale, imgH * scale, imgW * scale);
           } else {
               ctx.drawImage(img, -imgW / 2 * scale, -imgH / 2 * scale, imgW * scale, imgH * scale);
           }

           ctx.restore();

           requestNextFrame();
       };


            function requestNextFrame() {
                fetch('/frame?cache=' + Date.now())
                    .then(res => res.blob())
                    .then(blob => {
                        img.src = URL.createObjectURL(blob);
                    })
                    .catch(err => {
                        console.error('Frame error', err);
                        setTimeout(requestNextFrame, 500);
                    });
            }

            requestNextFrame();
        </script>

    </body>
    </html>
    """

    
    
    func Start(){
        server["/"] = { _ in
            return HttpResponse.ok(.html(self.html))
        }

        
        server["/frame"] = { request in
            guard let image = self.currentFrame else {
                return HttpResponse.notFound
            }

            let uiImage = UIImage(cgImage: image)
            guard let imageData = uiImage.jpegData(compressionQuality: 0.3) else {
                return HttpResponse.internalServerError
            }

            return HttpResponse.raw(200, "OK", ["Content-Type": "image/jpeg"]) { writer in
                try writer.write(imageData)
            }
        }

        
        server["/mjpeg"] = { [weak self] request in
            return HttpResponse.raw(200, "OK", [
                "Content-Type": "multipart/x-mixed-replace; boundary=frame",
                "Cache-Control": "no-cache",
                "Connection": "close"
            ]) { writer in
                guard let self = self else { return }

                while self.isRunning {
                    if let image = self.currentFrame {
                        let uiImage = UIImage(cgImage: image)
                        if let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                            let part = """
                            --frame\r
                            Content-Type: image/jpeg\r
                            Content-Length: \(jpegData.count)\r
                            \r
                            """.data(using: .utf8)!

                            try writer.write(part)
                            try writer.write(jpegData)
                            try writer.write("\r\n".data(using: .utf8)!)
                        }
                    }

                    Thread.sleep(forTimeInterval: 0.033) // ~30 FPS (adjust as needed)
                }
            }
        }
        
        
        do {
            isRunning = true
            try server.start(8080, forceIPv4: true)
            print("Server running at :8080")
            print(getAllIPAddresses())
        } catch {
            isRunning = false
            print("Server failed to start: \(error)")
        }
        
    }
    
    func Stop(){
        server.stop()
        isRunning = false
    }
    
    func getAllIPAddresses() -> [String] {
        var addresses: [String] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family

                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name != "lo0" {
                        var addr = interface.ifa_addr.pointee
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

                        if getnameinfo(&addr,
                                       socklen_t(interface.ifa_addr.pointee.sa_len),
                                       &hostname,
                                       socklen_t(hostname.count),
                                       nil,
                                       socklen_t(0),
                                       NI_NUMERICHOST) == 0 {
                            let ip = String(cString: hostname)
                            addresses.append("\(name): \(ip)")
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return addresses
    }


    
    var currentFrame: CGImage?

    func send(image: CGImage) {
        currentFrame = image
    }

 
}
