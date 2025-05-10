//
//  String+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 08.05.2025.
//

import Foundation
import SwiftUI
import RegexBuilder

public extension String
{
    // MARK: - Random string with set letght
    static func random(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var s = ""
        for _ in 0 ..< length {
            s.append(letters.randomElement()!)
        }
        return s
    }
    
    
    // MARK: - Email validation
    var isValidEmail: Bool {
        NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
    
    
    // MARK: - IP address validation
    var isValidIP: Bool {
        NSPredicate(format: "SELF MATCHES %@", "(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})").evaluate(with: self)
    }
    
    
    // MARK: - Calculate text size by font
    func sizeUsingFont(usingFont font: UIFont) -> CGSize {
         let fontAttributes = [NSAttributedString.Key.font: font]
         return self.size(withAttributes: fontAttributes)
     }

    
    // MARK: - HTML -> Markdown
    // https://stackoverflow.com/questions/56892691/how-to-show-html-or-markdown-in-a-swiftui-text
    func htmlToMarkDown() -> String {
        var text = self
        var loop = true
        // Replace HTML comments, in the format <!-- ... comment ... -->
        // Stop looking for comments when none is found
        while loop {
            // Retrieve hyperlink
            let searchComment = Regex {
                Capture {
                    // A comment in HTML starts with:
                    "<!--"
                    ZeroOrMore(.any, .reluctant)
                    // A comment in HTML ends with:
                    "-->"
                }
            }
            if let match = text.firstMatch(of: searchComment) {
                let (_, comment) = match.output
                text = text.replacing(comment, with: "")
            } else {
                loop = false
            }
        }
        // Replace line feeds with nothing, which is how HTML notation is read in the browsers
        text = self.replacing("\n", with: "")
        // Line breaks
        text = text.replacing("<div>", with: "\n")
        text = text.replacing("</div>", with: "")
        text = text.replacing("<p>", with: "\n")
        text = text.replacing("<br>", with: "\n")
        // Text formatting
        text = text.replacing("<strong>", with: "**")
        text = text.replacing("</strong>", with: "**")
        text = text.replacing("<b>", with: "**")
        text = text.replacing("</b>", with: "**")
        text = text.replacing("<em>", with: "*")
        text = text.replacing("</em>", with: "*")
        text = text.replacing("<i>", with: "*")
        text = text.replacing("</i>", with: "*")
        // Replace hyperlinks block
        loop = true
        // Stop looking for hyperlinks when none is found
        while loop {
            // Retrieve hyperlink
            let searchHyperlink = Regex {
                // A hyperlink that is embedded in an HTML tag in this format: <a... href="<hyperlink>"....>
                "<a"
                // There could be other attributes between <a... and href=...
                // .reluctant parameter: to stop matching after the first occurrence
                ZeroOrMore(.any)
                // We could have href="..., href ="..., href= "..., href = "...
                "href"
                ZeroOrMore(.any)
                "="
                ZeroOrMore(.any)
                "\""
                // Here is where the hyperlink (href) is captured
                Capture {
                    ZeroOrMore(.any)
                }
                "\""
                // After href="<hyperlink>", there could be a ">" sign or other attributes
                ZeroOrMore(.any)
                ">"
                // Here is where the linked text is captured
                Capture {
                    ZeroOrMore(.any, .reluctant)
                }
                One("</a>")
            }
            .repetitionBehavior(.reluctant)
            if let match = text.firstMatch(of: searchHyperlink) {
                let (hyperlinkTag, href, content) = match.output
                let markDownLink = "**[" + content + "](" + href + ")**"
                text = text.replacing(hyperlinkTag, with: markDownLink)
            } else {
                loop = false
            }
        }
        return text
    }
}
