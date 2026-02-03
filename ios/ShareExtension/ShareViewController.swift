import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

  let appGroupId = "group.com.mattpidden.recipeapp"
  let sharedKey = "shared_text_or_url"

  private var _didAutoRun = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Run once, immediately, instead of waiting for Post
    guard !_didAutoRun else { return }
    _didAutoRun = true

    handleShareAndBounce()
  }

  
  override func didSelectPost() {
    // Keep Post working too (useful while testing), but it’ll rarely be hit now
    handleShareAndBounce()
  }

  private func handleShareAndBounce() {
    guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let providers = item.attachments else {
        complete()
        return
    }

    // 1) URL attachments first
    if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
        p.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, _) in
        guard let self else { return }
        if let url = item as? URL {
            self.saveAndThenPromptOpen(url.absoluteString)
        } else if let nsurl = item as? NSURL {
            self.saveAndThenPromptOpen((nsurl as URL).absoluteString)
        } else {
            self.fallbackToText(providers)
        }
        }
        return
    }

    // 2) otherwise fallback to plain text
    fallbackToText(providers)
  }

  private func fallbackToText(_ providers: [NSItemProvider]) {
    if let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
        p.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, _) in
        guard let self else { return }
        if let text = item as? String {
            self.saveAndThenPromptOpen(text)
        } else {
            self.complete()
        }
        }
        return
    }

    complete()
  }

  private func saveAndThenPromptOpen(_ value: String) {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(trimmed, forKey: sharedKey)
    defaults?.synchronize()

    let opened = openParentApp()

    complete()
  }



  @discardableResult
  private func openParentApp() -> Bool {
    guard let url = URL(string: "maderecipeapp://share-received") else { return false }

    var responder: UIResponder? = self
    while responder != nil {
        if let application = responder as? UIApplication {
        if #available(iOS 18.0, *) {
            application.open(url, options: [:], completionHandler: nil)
            return true
        } else {
            return application.perform(#selector(UIApplication.openURL(_:)), with: url) != nil
        }
        }
        responder = responder?.next
    }

    return false
  }



 

  private func complete() {
    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  override func isContentValid() -> Bool { true }
  override func configurationItems() -> [Any]! { [] }
}
