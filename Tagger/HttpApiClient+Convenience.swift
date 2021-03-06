/**
 * Copyright (c) 2016 Ivan Magda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import UIKit.UIImage

// MARK: Typealias

typealias ImageDownloadingCompletionHandler = (image: UIImage) -> Void
typealias RequestFailCompletionHandler = (error: NSError) -> Void

// MARK: - HttpApiClient (Convenience)

extension HttpApiClient {
    
    // MARK: Methods
    
    func downloadImageWithURL(url: NSURL, successBlock success: ImageDownloadingCompletionHandler, failBlock fail: RequestFailCompletionHandler) {
        fetchRawDataForRequest(NSURLRequest(URL: url)) { result in
            func sendError(error: String) {
                self.debugLog("Error: \(error)")
                let error = NSError(
                    domain: FlickrApiClient.Constants.Error.LoadImageErrorDomain,
                    code: FlickrApiClient.Constants.Error.LoadImageErrorCode,
                    userInfo: [NSLocalizedDescriptionKey : error]
                )
                fail(error: error)
            }
            
            switch result {
            case .Error(let error):
                sendError(error.localizedDescription)
            case .RawData(let data):
                performOnBackgroud {
                    guard let image = UIImage(data: data) else {
                        performOnMain {
                            sendError("Could not initialize the image from the specified data.")
                        }
                        return
                    }
                    performOnMain {
                        success(image: image)
                    }
                }
            default:
                sendError(result.defaultErrorMessage()!)
            }
        }
    }
    
}
