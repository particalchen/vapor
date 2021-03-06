import XCTest
@testable import Vapor
import HTTP
import Core

class DropletTests: XCTestCase {
    static let allTests = [
        ("testMediaType", testMediaType),
        ("testTLSConfig", testTLSConfig),
        ("testRunDefaults", testRunDefaults),
        ("testRunConfig", testRunConfig),
        ("testRunManual", testRunManual),
    ]

    /**
        Ensures requests to files like CSS
        files have appropriate "Content-Type"
        headers returned.
    */
    func testMediaType() throws {
        let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
        let workDir = "/\(parent)/../../Sources/Development/"

        let drop = Droplet(workDir: workDir)

        drop.middleware = [
            FileMiddleware(workDir: drop.workDir)
        ]

        let request = try Request(method: .get, uri: "/styles/app.css")

        guard let response = try? drop.respond(to: request) else {
            XCTFail("drop could not respond")
            return
        }

        var found = false
        for header in response.headers {
            guard header.key == "Content-Type" else { continue }
            guard header.value == "text/css" else { continue }
            found = true
        }

        XCTAssert(found, "CSS Content Type not found")
    }

    func testTLSConfig() throws {
        let config = Config([
            "servers": [
                "secure": [
                    "host": "vapor.codes",
                    "port": 443,
                    "securityLayer": "tls",
                    "tls": [
                        "certificates": "ca",
                        "signature": "selfSigned"
                    ]
                ]
            ]
        ])

        _ = Droplet(config: config)
    }

    func testRunDefaults() throws {
        let drop = Droplet(arguments: ["vapor", "serve"])

        drop.get("foo") { req in
            return "bar"
        }

        try background {
            drop.run()
        }

        drop.console.wait(seconds: 2)

        let res = try drop.client.get("http://0.0.0.0:8080/foo")
        XCTAssertEqual(try res.bodyString(), "bar")
    }

    func testRunConfig() throws {
        let config = Config([
            "servers": [
                "my-server": [
                    "host": "0.0.0.0",
                    "port": 8337,
                    "securityLayer": "none"
                ]
            ]
        ])
        let drop = Droplet(arguments: ["vapor", "serve"], config: config)

        drop.get("foo") { req in
            return "bar"
        }

        try background {
            drop.run()
        }

        drop.console.wait(seconds: 2)

        let res = try drop.client.get("http://0.0.0.0:8337/foo")
        XCTAssertEqual(try res.bodyString(), "bar")
    }

    func testRunManual() throws {
        let drop = Droplet(arguments: ["vapor", "serve"])

        drop.get("foo") { req in
            return "bar"
        }

        try background {
            drop.run(servers: [
                "my-server": ("0.0.0.0", 8424, .none)
            ])
        }

        drop.console.wait(seconds: 2)

        let res = try drop.client.get("http://0.0.0.0:8424/foo")
        XCTAssertEqual(try res.bodyString(), "bar")
    }
}
