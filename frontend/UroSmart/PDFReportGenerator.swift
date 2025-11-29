import Foundation
import UIKit

final class PDFReportGenerator {
    func generate(caseNumber: String,
                  date: Date,
                  images: [UIImage],
                  analysis: AnalysisResult,
                  saveURL: URL) throws {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 @72dpi
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
            let margin: CGFloat = 24
            let title = "Urine Microscopy Report"

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22)
            ]
            let titleSize = (title as NSString).size(withAttributes: titleAttrs)
            (title as NSString).draw(at: CGPoint(x: margin, y: margin), withAttributes: titleAttrs)

            // Meta
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let meta = "Case: \(caseNumber)\nDate: \(formatter.string(from: date))"
            let metaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            (meta as NSString).draw(in: CGRect(x: margin, y: margin + titleSize.height + 8, width: pageRect.width - margin*2, height: 60), withAttributes: metaAttrs)

            // Analysis Summary - Detailed per-object results
            let summaryY = margin + titleSize.height + 72
            let summaryTitle = "Analysis Results:"
            (summaryTitle as NSString).draw(at: CGPoint(x: margin, y: summaryY), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 16)
            ])
            
            let detections = [
                ("Yeast", analysis.yeast),
                ("Triple Phosphate", analysis.triplePhosphate),
                ("Calcium Oxalate", analysis.calciumOxalate),
                ("Squamous Cells", analysis.squamousCells),
                ("Uric Acid", analysis.uricAcid)
            ]
            
            var yOffset = summaryY + 24
            for (name, detection) in detections {
                let status = detection.present ? "Present" : "Absent"
                let statusColor = detection.present ? UIColor.systemRed : UIColor.systemGreen
                let line = "• \(name): \(status)"
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: statusColor
                ]
                (line as NSString).draw(at: CGPoint(x: margin + 8, y: yOffset), withAttributes: attrs)
                yOffset += 22
            }
            
            // Overall summary
            let overallY = yOffset + 10
            let overall = analysis.present ? "Overall: Objects Detected" : "Overall: No Objects Detected"
            let overallColor = analysis.present ? UIColor.systemRed : UIColor.systemGreen
            (overall as NSString).draw(at: CGPoint(x: margin, y: overallY), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: overallColor
            ])

            // Images grid (up to 2)
            let imageY = margin + titleSize.height + 220
            let imageWidth = (pageRect.width - margin*3) / 2
            let imageHeight = imageWidth
            for (index, img) in images.prefix(2).enumerated() {
                let x = margin + CGFloat(index) * (imageWidth + margin)
                let rect = CGRect(x: x, y: imageY, width: imageWidth, height: imageHeight)
                img.draw(in: rect)
                
                // Draw bounding boxes
                let detections = [
                    analysis.yeast,
                    analysis.triplePhosphate,
                    analysis.calciumOxalate,
                    analysis.squamousCells,
                    analysis.uricAcid
                ]
                
                for detection in detections {
                    guard let boxes = detection.boundingBoxes else { continue }
                    
                    for box in boxes {
                        // box is [x1, y1, x2, y2] normalized (0-1)
                        guard box.count == 4 else { continue }
                        
                        let x1 = CGFloat(box[0])
                        let y1 = CGFloat(box[1])
                        let x2 = CGFloat(box[2])
                        let y2 = CGFloat(box[3])
                        
                        let boxRect = CGRect(
                            x: rect.minX + x1 * rect.width,
                            y: rect.minY + y1 * rect.height,
                            width: (x2 - x1) * rect.width,
                            height: (y2 - y1) * rect.height
                        )
                        
                        // Draw box
                        ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                        ctx.cgContext.setLineWidth(2.0)
                        ctx.cgContext.stroke(boxRect)
                        
                        // Draw label background
                        let label = detection.name
                        let labelAttrs: [NSAttributedString.Key: Any] = [
                            .font: UIFont.boldSystemFont(ofSize: 8),
                            .foregroundColor: UIColor.white,
                            .backgroundColor: UIColor.red
                        ]
                        let labelSize = (label as NSString).size(withAttributes: labelAttrs)
                        let labelRect = CGRect(
                            x: boxRect.minX,
                            y: boxRect.minY - labelSize.height,
                            width: labelSize.width + 4,
                            height: labelSize.height
                        )
                        
                        ctx.cgContext.setFillColor(UIColor.red.cgColor)
                        ctx.cgContext.fill(labelRect)
                        
                        (label as NSString).draw(at: CGPoint(x: labelRect.minX + 2, y: labelRect.minY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 8), .foregroundColor: UIColor.white])
                    }
                }
            }

            // Footer
            let foot = "Generated offline on-device"
            let footSize = (foot as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            (foot as NSString).draw(at: CGPoint(x: pageRect.width - margin - footSize.width, y: pageRect.height - margin - footSize.height), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
        }
        
        print("📄 Generated PDF data size: \(data.count) bytes")
        try data.write(to: saveURL)
    }
}
