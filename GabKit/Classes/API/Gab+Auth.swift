//
//  Gab+Auth.swift
//  GabKit
//
//  Created by Tomoya Hirano on 2018/10/10.
//

import SafariServices

extension Gab {
  public func authorize(withPresentingFrom presenting: UIViewController,
                        success: Success? = nil, failure: Failure? = nil) {
    NotificationCenter.default.addObserver(forName: .gabCallback, object: nil, queue: .main) { (notification) in
      NotificationCenter.default.removeObserver(self)
      presenting.presentedViewController?.dismiss(animated: true, completion: nil)
      guard let url = notification.userInfo?[CallbackNotification.optionsURLKey] as? URL else { return }
      let urlComponents = URLComponents(string: url.absoluteString)
      guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else { return }
      self.fetchToken(code: code, success: success, failure: failure)
    }
    
    var urlComponents = URLComponents(string: "https://api.gab.com/oauth/authorize")!
    let responseType = URLQueryItem(name: "response_type", value: "code")
    let clientID = URLQueryItem(name: "client_id", value: self.clientID)
    let scopeValue = self.scopes.map({ $0.rawValue }).joined(separator: " ")
    let scope = URLQueryItem(name: "scope", value: scopeValue)
    urlComponents.queryItems = [responseType, clientID, scope]
    
    let vc = SFSafariViewController(url: urlComponents.url!)
    presenting.present(vc, animated: true, completion: nil)
  }
  
  public static func handleURL(_ url: URL) {
    let notification = Foundation.Notification(name: .gabCallback, object: nil, userInfo: [CallbackNotification.optionsURLKey: url])
    NotificationCenter.default.post(notification)
  }
  
  internal func fetchToken(code: String, success: Success? = nil, failure: Failure? = nil) {
    let params: [String : Any] = [
      "grant_type" : "authorization_code",
      "code" : code,
      "client_id" : clientID,
      "client_secret" : clientSecret
    ]
    post(path: "token", baseURL: .outh, params: params) { [weak self] (credential: Credential?, _, error) in
      self?.credential = credential
      if let error = error {
        failure?(error)
      } else {
        success?()
      }
    }
  }
  
  internal func refreshAccessToken(refreshToken: String) {
    let scopeValue = self.scopes.map({ $0.rawValue }).joined(separator: " ")
    let params: [String : Any] = [
      "grant_type" : "refresh_token",
      "refresh_token" : refreshToken,
      "client_id" : clientID,
      "client_secret" : clientSecret,
      "scope" : scopeValue
    ]
    post(path: "token", baseURL: .outh, params: params) { (credential: Credential?, _, _) in
      
    }
  }
}
