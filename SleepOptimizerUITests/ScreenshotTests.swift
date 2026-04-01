import XCTest

final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func test_captureAllScreenshots() {
        sleep(2)
        captureScreenshot(name: "01_main")

        let tabBar = app.tabBars
        if tabBar.buttons.count > 1 {
            tabBar.buttons.element(boundBy: 1).tap()
            sleep(1)
            captureScreenshot(name: "02_tab2")
        }
        if tabBar.buttons.count > 2 {
            tabBar.buttons.element(boundBy: 2).tap()
            sleep(1)
            captureScreenshot(name: "03_tab3")
        }
        if tabBar.buttons.count > 3 {
            tabBar.buttons.element(boundBy: 3).tap()
            sleep(1)
            captureScreenshot(name: "04_tab4")
        }
    }

    private func captureScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
