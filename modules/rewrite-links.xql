xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";

declare function t:rewrite-links($node as node(), $map) as node() {
    typeswitch($node)
        case document-node() return 
            document {
            for $child in $node/node()
            return t:rewrite-links($child, $map)
            }
        case element() return
            switch(local-name($node))
                case "ref"
                case "ptr" return
                    element {name($node)} {
                        for $attr in $node/@*
                            return t:rewrite-links($attr, $map),
                        for $child in $node/node()
                            return t:rewrite-links($child, $map)
                    }
                default return
                    element {name($node)} {
                        for $attr in $node/@*
                            return $attr,
                        for $child in $node/node()
                            return t:rewrite-links($child, $map)
                        
                    }
        case attribute() return
            switch(local-name($node))
                case "target" return
                    attribute {"target"} {
                    string-join(
                    for $t in tokenize($node, " +")
                    let $target := if (starts-with($t, "#")) then
                            concat(map:get($map, substring-after($t, "#")), $t)
                        else
                            $t
                    return $target
                    , " ")}
                default return $node
        default return $node
};

let $collection := request:get-parameter("collection", "none")
let $document := request:get-parameter("doc", "none")

let $map := map:merge(for $id in doc(concat("/db/",$collection,"/",$document,".xml"))//*[@xml:id]
    return map:entry($id/@xml:id, string(($id/ancestor::t:div[@type=("section","bibliography","textpart")]/@xml:id)[1]))
    ) 

for $xml in doc(concat("/db/",$collection,"/",$document,".xml"))
return t:rewrite-links($xml, $map)
