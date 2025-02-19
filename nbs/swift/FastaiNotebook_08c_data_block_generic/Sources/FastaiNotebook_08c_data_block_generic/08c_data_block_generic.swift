/*
THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
file to edit: 08c_data_block_generic.ipynb

*/



import Path
import TensorFlow
#if canImport(PythonKit)
    import PythonKit
#else
    import Python
#endif


public let dataPath = Path.home/".fastai"/"data"

public func downloadImagenette(path: Path = dataPath, sz:String="-320") -> Path {
    let url = "https://s3.amazonaws.com/fast-ai-imageclas/imagenette\(sz).tgz"
    let fname = "imagenette\(sz)"
    let file = path/fname
    try! path.mkdir(.p)
    if !file.exists {
        downloadFile(url, dest:(path/"\(fname).tgz").string)
        _ = "/bin/tar".shell("-xzf", (path/"\(fname).tgz").string, "-C", path.string)
    }
    return file
}

public func collectFiles(under path: Path, recurse: Bool = false, filtering extensions: [String]? = nil) -> [Path] {
    var res: [Path] = []
    for p in try! path.ls(){
        if p.kind == .directory && recurse { 
            res += collectFiles(under: p.path, recurse: recurse, filtering: extensions)
        } else if extensions == nil || extensions!.contains(p.path.extension.lowercased()) {
            res.append(p.path)
        }
    }
    return res
}

public protocol DatasetConfig {
    associatedtype Item
    associatedtype Label
    
    static func download() -> Path
    static func getItems(_ path: Path) -> [Item]
    static func isTraining(_ item: Item) -> Bool
    static func labelOf(_ item: Item) -> Label
}

public enum ImageNette: DatasetConfig {
    
    public static func download() -> Path { return downloadImagenette() }
    
    public static func getItems(_ path: Path) -> [Path] {
        return collectFiles(under: path, recurse: true, filtering: ["jpeg", "jpg"])
    }
    
    public static func isTraining(_ p:Path) -> Bool {
        return p.parent.parent.basename() == "train"
    }
    
    public static func labelOf(_ p:Path) -> String { return p.parent.basename() }
}


public func describeSample<C>(_ item: C.Item, config: C.Type) where C: DatasetConfig {
    let isTraining = C.isTraining(item)
    let label = C.labelOf(item)
    print("""
          item: \(item)
          training?:  \(isTraining)
          label: \(label)
          """)
}

public func partitionIntoTrainVal<T>(_ items:[T],isTrain:((T)->Bool)) -> (train:[T],valid:[T]){
    return (train: items.filter(isTrain), valid: items.filter { !isTrain($0) })
}

public protocol Processor {
    associatedtype Input
    associatedtype Output
    
    mutating func initState(_ items: [Input])
    func process  (_ item: Input)  -> Output
    func deprocess(_ item: Output) -> Input
}

public struct CategoryProcessor: Processor {
    private(set) public var intToLabel: [String] = []
    private(set) public var labelToInt: [String:Int] = [:]
    
    public init() {}
    
    public mutating func initState(_ items: [String]) {
        intToLabel = Array(Set(items)).sorted()
        labelToInt = Dictionary(uniqueKeysWithValues:
            intToLabel.enumerated().map{ ($0.element, $0.offset) })
    }
    
    public func process(_ item: String) -> Int { return labelToInt[item]! }
    public func deprocess(_ item: Int) -> String { return intToLabel[item] }
}

public func >| <A, B, C>(_ f: @escaping (A) -> B,
                   _ g: @escaping (B) -> C) -> (A) -> C {
    return { g(f($0)) }
}

public struct SplitLabeledData<Item,Label> {
    public var train: [(x: Item, y: Label)]
    public var valid: [(x: Item, y: Label)]
    
    public init(train: [(x: Item, y: Label)], valid: [(x: Item, y: Label)]) {
        (self.train,self.valid) = (train,valid)
    }
}

public func makeSLD<C, P>(config: C.Type, procL: inout P) -> SplitLabeledData<C.Item, P.Output> 
where C: DatasetConfig, P: Processor, P.Input == C.Label{
    let path = C.download()
    let items = C.getItems(path)
    let samples = partitionIntoTrainVal(items, isTrain:C.isTraining)
    let trainLabels = samples.train.map(C.labelOf)
    procL.initState(trainLabels)
    let itemToProcessedLabel = C.labelOf >| procL.process
    return SplitLabeledData(train: samples.train.map { ($0, itemToProcessedLabel($0)) },
                            valid: samples.valid.map { ($0, itemToProcessedLabel($0)) })
}

import Foundation
import SwiftCV

public func openImage(_ fn: Path) -> Mat {
    return imdecode(try! Data(contentsOf: fn.url))
}

public func showCVImage(_ img: Mat) {
    let tensImg = Tensor<UInt8>(cvMat: img)!
    let numpyImg = tensImg.makeNumpyArray()
    plt.imshow(numpyImg) 
    plt.axis("off")
    plt.show()
}
