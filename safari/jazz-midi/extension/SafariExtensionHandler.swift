import SafariServices

class PageData {
  private static var pages : [(SFSafariPage, PageData)] = []
  private var outputs : [UInt : MidiOut] = [:]
  private var inputs : [UInt : MidiIn] = [:]

  static func find(_ page: SFSafariPage, _ create: Bool = false) -> PageData? {
    if let tpl = pages.first(where: { $0.0 == page }) {
      return tpl.1
    }
    if !create {
      return nil
    }
    let inst = PageData()
    pages.append((page, inst))
    return inst
  }

  static func remove(_ page: SFSafariPage) {
    pages.removeAll(where: { $0.0 == page })
  }
  
  func send(_ slot: UInt, _ data: [UInt8]) {

  }

  func openout(_ slot: UInt, _ name: String) -> String {
    if let str = outputs[slot]?.name() {
      if (str == name) {
        return name;
      }
    }
    if let port = Midi.openMidiOut(name) {
      outputs[slot] = port
    }
    if let str = outputs[slot]?.name() {
      return str;
    }
    else {
      return ""
    }
  }

  func openin(_ slot: UInt, _ name: String) -> String {
    if let str = inputs[slot]?.name() {
      if (str == name) {
        return name;
      }
    }
    if let port = Midi.openMidiIn(name) {
      inputs[slot] = port
    }
    if let str = inputs[slot]?.name() {
      return str;
    }
    else {
      return ""
    }
  }

  func closeout(_ slot: UInt) {
    outputs.removeValue(forKey: slot)
  }

  func closein(_ slot: UInt) {
    inputs.removeValue(forKey: slot)
  }

}

class SafariExtensionHandler: SFSafariExtensionHandler {
  override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
    page.getPropertiesWithCompletionHandler { properties in
        //NSLog("Received: \(messageName) from: \(String(describing: properties?.url)) data: \(userInfo ?? [:])")
      if messageName == "unload" {
        NSLog("Unloading page: \(properties?.url)");
        PageData.remove(page)
      }
      else if messageName == "refresh" {
        page.dispatchMessageToScript(withName: "", userInfo: ["data" : ["refresh", Midi.refresh()]])
      }
      else if var data = userInfo?["data"] as? [Any] {
        let slot = data[0] as! UInt
        data.remove(at: 0)
        NSLog("\(messageName) \(slot) : \(data)")
        if messageName == "play" {
          PageData.find(page)?.send(slot, data.map { $0 as! UInt8 })
        }
        else if messageName == "openout" {
          let name = PageData.find(page, true)!.openout(slot, data[0] as! String)
          page.dispatchMessageToScript(withName: "", userInfo: ["data" : ["openout", slot, name]])
        }
        else if messageName == "openin" {
          let name = PageData.find(page, true)!.openin(slot, data[0] as! String)
          page.dispatchMessageToScript(withName: "", userInfo: ["data" : ["openin", slot, name]])
        }
        else if messageName == "closeout" {
          PageData.find(page)?.closeout(slot)
        }
        else if messageName == "closein" {
          PageData.find(page)?.closein(slot)
        }
      }
    }
  }

}
