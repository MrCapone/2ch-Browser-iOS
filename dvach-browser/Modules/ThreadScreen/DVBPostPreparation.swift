//
//  DVBPostPreparation.swift
//  dvach-browser
//
//  Created by Dmitry Lukianov on 21.10.2020.
//  Copyright © 2020 MrCapone. All rights reserved.
//

import Foundation
import UIKit

class DVBPostPreparation: NSObject {
    ///  Array of posts that have been REPLIED BY current post
    var repliesTo: [String] = []
    // need to know to generate replies
    private var boardId: String?
    // need to know to generate replies
    private var threadId: String?
    private var bodyFontDescriptor: UIFontDescriptor?
    
    ///  Init method with board and thread infos
    ///
    ///  - Parameters:
    ///   - boardId:  short code of the board
    ///    - threadId: number of the op post of the thread
    ///
    ///  - Returns: Preparation object
    init(boardId: String?, andThreadId threadId: String?) {
        super.init()
        
        self.boardId = boardId
        self.threadId = threadId
        
        bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
    }
    
    convenience override init() {
        NSException(name: NSExceptionName("Not enough params"), reason: "Use +[DVBPostPreparation initWithBoardId: andThreadId: instead]", userInfo: nil).raise()
        fatalError()
    }
    
    ///  Add 2ch markup to the comment (based on HTML markup
    ///
    ///  - Parameter comment: plain string with comment
    ///
    ///  - Returns: attributed string with 2ch markup
    func commentWithMarkdown(withComments comment: String?) -> NSAttributedString? {
        guard  var comment = comment else {
            return nil
        }
        
        let bodyFontSize = bodyFontDescriptor?.pointSize
        
        // чистка исходника и посильная замена хтмл-литералов
        comment = comment.replacingOccurrences(of: "\n", with: "")
        //comment = comment?.replacingOccurrences(of: "\r\n", with: "\n")
        comment = comment.replacingOccurrences(of: "<br />", with: "\n")
        comment = comment.replacingOccurrences(of: "<br/>", with: "\n")
        comment = comment.replacingOccurrences(of: "<br>", with: "\n")
        comment = comment.replacingOccurrences(of: "&#39;", with: "'")
        comment = comment.replacingOccurrences(of: "&#44;", with: ",")
        comment = comment.replacingOccurrences(of: "&#47;", with: "/")
        comment = comment.replacingOccurrences(of: "&#92;", with: "\\")
        
        let range = NSRange(location: 0, length: comment.count)
        
        let maComment = NSMutableAttributedString(string: comment)
        maComment.addAttribute(.font, value: UIFont(name: "HelveticaNeue", size: bodyFontSize!)!, range: range)
        
        let commentStyle = NSMutableParagraphStyle()
        
        maComment.addAttribute(.paragraphStyle, value: commentStyle, range: range)
        
        // dark theme
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            maComment.addAttribute(.foregroundColor, value: CELL_TEXT_COLOR, range: range)
        }
        
        // em
        let emFont = UIFont(name: "HelveticaNeue-Italic", size: bodyFontSize!)
        var emRangeArray: [NSValue] = []
        var em: NSRegularExpression? = nil
        do {
            em = try NSRegularExpression(pattern: "<em[^>]*>(.*?)</em>", options: [])
        } catch {
        }
        em?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range1 = result?.range {
                maComment.addAttribute(.font, value: emFont!, range: range1)
            }
            var value: NSValue? = nil
            if let range1 = result?.range {
                value = NSValue(range: range1)
            }
            if let value = value {
                emRangeArray.append(value)
            }
        })
        
        // strong
        let strongFont = UIFont(name: "HelveticaNeue-Bold", size: bodyFontSize!)
        var strongRangeArray: [AnyHashable] = []
        var strong: NSRegularExpression? = nil
        do {
            strong = try NSRegularExpression(pattern: "<strong[^>]*>(.*?)</strong>", options: [])
        } catch {
        }
        strong?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range = result?.range {
                maComment.addAttribute(.font, value: strongFont!, range: range)
            }
            var value: NSValue? = nil
            if let range = result?.range {
                value = NSValue(range: range)
            }
            if let value = value {
                strongRangeArray.append(value)
            }
        })
        
        // emstrong
        let emStrongFont = UIFont(name: "HelveticaNeue-BoldItalic", size: bodyFontSize!)
        for emRangeValue in emRangeArray {
            //value to range
            let emRange = emRangeValue.rangeValue
            for strongRangeValue in strongRangeArray {
                guard let strongRangeValue = strongRangeValue as? NSValue else {
                    continue
                }
                let strongRange = strongRangeValue.rangeValue
                let emStrongRange = NSIntersectionRange(emRange, strongRange)
                if emStrongRange.length != 0 {
                    maComment.addAttribute(.font, value: emStrongFont!, range: emStrongRange)
                }
            }
        }
        
        // underline
        var underline: NSRegularExpression? = nil
        do {
            underline = try NSRegularExpression(pattern: "<span class=\"u\">(.*?)</span>", options: [])
        } catch {
        }
        underline?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range = result?.range {
                maComment.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
        })
        
        // strike
        //не будет работать с tttattributedlabel, нужно переделывать ссылки и все такое
        var strike: NSRegularExpression? = nil
        do {
            strike = try NSRegularExpression(pattern: "<span class=\"s\">(.*?)</span>", options: [])
        } catch {
        }
        strike?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range = result?.range {
                maComment.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
        })
        
        // spoiler
        var spoilerColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        if UserDefaults.standard.bool(forKey: SETTING_ENABLE_DARK_THEME) {
            spoilerColor = CELL_TEXT_SPOILER_COLOR
        }
        var spoiler: NSRegularExpression? = nil
        do {
            spoiler = try NSRegularExpression(pattern: "<span class=\"spoiler\">(.*?)</span>", options: [])
        } catch {
        }
        spoiler?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range = result?.range {
                maComment.addAttribute(.foregroundColor, value: spoilerColor, range: range)
            }
        })
        
        // quote
        let quoteColor = UIColor(red: 17 / 255.0, green: 139 / 255.0, blue: 116 / 255.0, alpha: 1.0)
        var quote: NSRegularExpression? = nil
        do {
            quote = try NSRegularExpression(pattern: "<span class=\"unkfunc\">(.*?)</span>", options: [])
        } catch {
        }
        quote?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            if let range = result?.range {
                maComment.addAttribute(.foregroundColor, value: quoteColor, range: range)
            }
        })
        
        // link
        let linkColor = UIColor(red: 255 / 255.0, green: 102 / 255.0, blue: 0 / 255.0, alpha: 1.0)
        var link: NSRegularExpression? = nil
        do {
            link = try NSRegularExpression(pattern: "<a[^>]*>(.*?)</a>", options: [])
        } catch {
        }
        var linkLink: NSRegularExpression? = nil
        do {
            linkLink = try NSRegularExpression(pattern: "href=\"(.*?)\"", options: [])
        } catch {
        }
        var linkLinkTwo: NSRegularExpression? = nil
        do {
            linkLinkTwo = try NSRegularExpression(pattern: "href='(.*?)'", options: [])
        } catch {
        }
        
        guard let threadId = threadId, let boardId = boardId else {
            NSException(name: NSExceptionName("Not enough params"), reason: "Specify threadId and boardId params please", userInfo: nil).raise()
            fatalError()
        }
        
        link?.enumerateMatches(
            in: comment,
            options: [],
            range: range,
            using: { result, flags, stop in
                var fullLink: String? = nil
                if let range = result?.range {
                    fullLink = (comment as NSString).substring(with: range) as String
                }
                let linkLinkResult = linkLink?.firstMatch(in: fullLink ?? "", options: [], range: NSRange(location: 0, length: fullLink?.count ?? 0))
                let linkLinkTwoResult = linkLinkTwo?.firstMatch(in: fullLink ?? "", options: [], range: NSRange(location: 0, length: fullLink?.count ?? 0))
                
                var urlRange = NSRange(location: 0, length: 0)
                
                if linkLinkResult?.numberOfRanges != 0 {
                    urlRange = NSRange(location: (linkLinkResult?.range.location ?? 0) + 6, length: (linkLinkResult?.range.length ?? 0) - 7)
                } else if linkLinkResult?.numberOfRanges != 0 {
                    urlRange = NSRange(location: (linkLinkTwoResult?.range.location ?? 0) + 6, length: (linkLinkTwoResult?.range.length ?? 0) - 7)
                }
                
                if urlRange.length != 0 {
                    var urlString = (fullLink! as NSString).substring(with: urlRange) as String
                    urlString = urlString.replacingOccurrences(of: "&amp;", with: "&")
                    let url = URL(string: urlString)
                    if let url = url {
                        let un = UrlNinja.un(withUrl: url)
                        
                        if (un.boardId == boardId) && (un.threadId == threadId) && un.type == linkType.boardThreadPostLink {
                            if let postId = un.postId {
                                if !repliesTo.contains(postId) {
                                    repliesTo.append(postId)
                                }
                            }
                        }
                        
                        maComment.addAttribute(.link, value: url, range: result!.range)
                        maComment.addAttribute(.foregroundColor, value: linkColor, range: result!.range)
                        maComment.addAttribute(.underlineStyle, value: NSNumber(value: 0), range: result!.range)
                        let underlineColor = DVBBoardStyler.threadCellInsideBackgroundColor()
                        maComment.addAttribute(.underlineColor, value: underlineColor, range: result!.range)
                    }
                }
            })
        
        // находим все теги и сохраняем в массив
        var tagArray: [AnyHashable] = []
        var tag: NSRegularExpression? = nil
        do {
            tag = try NSRegularExpression(pattern: "<[^>]*>", options: [])
        } catch {
        }
        tag?.enumerateMatches(in: comment, options: [], range: range, using: { result, flags, stop in
            var value: NSValue? = nil
            if let range = result?.range {
                value = NSValue(range: range)
            }
            if let value = value {
                tagArray.append(value)
            }
        })
        
        // вырезательный цикл
        var shift = 0
        for rangeValue in tagArray {
            guard let rangeValue = rangeValue as? NSValue else {
                continue
            }
            var cutRange = rangeValue.rangeValue
            cutRange.location -= shift
            maComment.deleteCharacters(in: cutRange)
            shift += cutRange.length
        }
        
        // чистим переводы строк в начале и конце
        var whitespaceStart: NSRegularExpression? = nil
        do {
            whitespaceStart = try NSRegularExpression(pattern: "^\\s\\s*", options: [])
        } catch {
        }
        let wsResult = whitespaceStart?.firstMatch(in: maComment.string, options: [], range: NSRange(location: 0, length: maComment.length))
        if let range = wsResult?.range {
            maComment.deleteCharacters(in: range)
        }
        
        var whitespaceEnd: NSRegularExpression? = nil
        do {
            whitespaceEnd = try NSRegularExpression(pattern: "\\s\\s*$", options: [])
        } catch {
        }
        let weResult = whitespaceEnd?.firstMatch(in: maComment.string, options: [], range: NSRange(location: 0, length: maComment.length))
        if let range = weResult?.range {
            maComment.deleteCharacters(in: range)
        }
        
        // и пробелы в начале каждой строки
        var whitespaceLineStartArray: [NSValue] = []
        var whitespaceLineStart: NSRegularExpression? = nil
        do {
            whitespaceLineStart = try NSRegularExpression(pattern: "^[\\t\\f\\p{Z}]+", options: .anchorsMatchLines)
        } catch {
        }
        whitespaceLineStart?.enumerateMatches(in: maComment.string, options: [], range: NSRange(location: 0, length: maComment.length), using: { result, flags, stop in
            var value: NSValue? = nil
            if let range = result?.range {
                value = NSValue(range: range)
            }
            if let value = value {
                whitespaceLineStartArray.append(value)
            }
        })
        
        var whitespaceLineStartShift = 0
        for rangeValue in whitespaceLineStartArray {
            var cutRange = rangeValue.rangeValue
            cutRange.location -= whitespaceLineStartShift
            maComment.deleteCharacters(in: cutRange)
            whitespaceLineStartShift += cutRange.length
        }
        
        // и двойные переводы
        var whitespaceDoubleArray: [AnyHashable] = []
        var whitespaceDouble: NSRegularExpression? = nil
        do {
            whitespaceDouble = try NSRegularExpression(pattern: "[\\n\\r]{3,}", options: [])
        } catch {
        }
        whitespaceDouble?.enumerateMatches(in: maComment.string, options: [], range: NSRange(location: 0, length: maComment.length), using: { result, flags, stop in
            var value: NSValue? = nil
            if let range = result?.range {
                value = NSValue(range: range)
            }
            if let value = value {
                whitespaceDoubleArray.append(value)
            }
        })
        
        var whitespaceDoubleShift = 0
        for rangeValue in whitespaceDoubleArray {
            guard let rangeValue = rangeValue as? NSValue else {
                continue
            }
            var cutRange = rangeValue.rangeValue
            cutRange.location -= whitespaceDoubleShift
            maComment.deleteCharacters(in: cutRange)
            maComment.insert(NSAttributedString(string: "\n\n", attributes: nil), at: cutRange.location)
            whitespaceDoubleShift += cutRange.length - 2
        }
        
        // Заменить хтмл-литералы на нормальные символы (раньше этого делать нельзя, сломается парсинг).
        maComment.mutableString.replaceOccurrences(of: "&gt;", with: ">", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: maComment.string.count))
        maComment.mutableString.replaceOccurrences(of: "&lt;", with: "<", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: maComment.string.count))
        maComment.mutableString.replaceOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: maComment.string.count))
        maComment.mutableString.replaceOccurrences(of: "&amp;", with: "&", options: NSString.CompareOptions.caseInsensitive, range: NSRange(location: 0, length: maComment.string.count))
        
        return maComment
    }
}
