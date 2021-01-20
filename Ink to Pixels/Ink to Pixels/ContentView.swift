//
//  ContentView.swift
//  Ink to Pixels
//
//  Created by Peter Khouly on 23/02/2020.
//  Copyright © 2020 Peter Khouly. All rights reserved.
//

import SwiftUI
import Vision
import VisionKit

struct ContentView: View {
    private let buttonInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
         
        var body: some View {
            VStack() {
                Spacer()
                Text("Ink to Pixels")
                Button(action: openCamera) {
                    Text("Scan").foregroundColor(.white)
                }.padding(buttonInsets)
                    .background(Color.blue)
                    .cornerRadius(3.0)
                ScrollView{
                Text(text).lineLimit(nil)
                }
            }.sheet(isPresented: self.$isShowingScannerSheet) { self.makeScannerView() }
        }
         
        @State private var isShowingScannerSheet = false
        @State private var text: String = ""
         
        private func openCamera() {
            isShowingScannerSheet = true
        }
         
        private func makeScannerView() -> ScannerView {
            ScannerView(completion: { textPerPage in
                if let text = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) {
                    self.text = text
                }
                self.isShowingScannerSheet = false
            })
        }
    }

final class TextRecognizer {
    let cameraScan: VNDocumentCameraScan
     
    init(cameraScan: VNDocumentCameraScan) {
        self.cameraScan = cameraScan
    }
     
    private let queue = DispatchQueue(label: "com.augmentedcode.scan", qos: .default, attributes: [], autoreleaseFrequency: .workItem)
     
    func recognizeText(withCompletionHandler completionHandler: @escaping ([String]) -> Void) {
        queue.async {
            let images = (0..<self.cameraScan.pageCount).compactMap({ self.cameraScan.imageOfPage(at: $0).cgImage })
            let imagesAndRequests = images.map({ (image: $0, request: VNRecognizeTextRequest()) })
            let textPerPage = imagesAndRequests.map { image, request -> String in
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    guard let observations = request.results as? [VNRecognizedTextObservation] else { return "" }
                    return observations.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: "\n")
                }
                catch {
                    print(error)
                    return ""
                }
            }
            DispatchQueue.main.async {
                completionHandler(textPerPage)
            }
        }
    }
}


 struct ScannerView: UIViewControllerRepresentable {
     private let completionHandler: ([String]?) -> Void
      
     init(completion: @escaping ([String]?) -> Void) {
         self.completionHandler = completion
     }
      
     typealias UIViewControllerType = VNDocumentCameraViewController
      
     func makeUIViewController(context: UIViewControllerRepresentableContext<ScannerView>) -> VNDocumentCameraViewController {
         let viewController = VNDocumentCameraViewController()
         viewController.delegate = context.coordinator
         return viewController
     }
      
     func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<ScannerView>) {}
      
     func makeCoordinator() -> Coordinator {
         return Coordinator(completion: completionHandler)
     }
      
     final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
         private let completionHandler: ([String]?) -> Void
          
         init(completion: @escaping ([String]?) -> Void) {
             self.completionHandler = completion
         }
          
         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
             print("Document camera view controller did finish with ", scan)
             let recognizer = TextRecognizer(cameraScan: scan)
             recognizer.recognizeText(withCompletionHandler: completionHandler)
         }
          
         func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
             completionHandler(nil)
         }
          
         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
             print("Document camera view controller did finish with error ", error)
             completionHandler(nil)
         }
     }
 }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
