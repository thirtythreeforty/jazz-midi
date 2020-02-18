import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
  override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
          NSLog("Received: \(messageName) from: \(String(describing: properties?.url)) data: \(userInfo ?? [:])")
          page.dispatchMessageToScript(withName: "", userInfo: ["data" : ["refresh", ""]])
        }
    }
}
