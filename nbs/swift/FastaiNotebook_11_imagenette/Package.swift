// swift-tools-version:4.2
import PackageDescription

let package = Package(
name: "FastaiNotebook_11_imagenette",
products: [
.library(name: "FastaiNotebook_11_imagenette", targets: ["FastaiNotebook_11_imagenette"]),

],
dependencies: [
.package(path: "../FastaiNotebook_09_optimizer")
],
targets: [
.target(name: "FastaiNotebook_11_imagenette", dependencies: ["FastaiNotebook_09_optimizer"]),

]
)