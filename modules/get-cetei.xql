xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=html media-type=text/html";

declare function t:make-ceteicean($node as node()) as node() {
    t:make-ceteicean($node, false())
};

declare function t:make-ceteicean($node as node(), $wrap as xs:boolean) as node() {
    typeswitch($node)
        case document-node() return 
            document {
                for $child in $node/node()
                    return t:make-ceteicean($child)
            }
        case element() return
            element {concat("tei-", lower-case(local-name($node)))} {
                attribute data-teiname {lower-case(local-name($node))},
                if ($node/@xml:id) then
                    attribute xml:id {$node/@xml:id}
                else (),
                if ($wrap) then
                    (attribute data-template {"templates:surround"},
                    attribute data-template-with {"templates/page.html"},
                    attribute data-template-at {"content"})
                else (),
                if (not($node/node())) then
                    attribute data-empty {"true"}
                else (),
                for $attr in $node/@*
                return t:make-ceteicean($attr),
                for $child in $node/node()
                return t:make-ceteicean($child)
            }
        case attribute() return
            switch(namespace-uri($node))
                case "http://www.w3.org/XML/1998/namespace" return
                    attribute {local-name($node)} {$node}
                default return 
                    attribute {local-name($node)} {replace($node, '&amp;amp;', "&#36;")}
        default return $node
};

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
let $part := request:get-parameter("id", "none")
let $wrap := request:get-parameter("wrap", false())

let $map := map:merge(for $id in doc(concat("/db/",$collection,"/",$document,".xml"))//*[@xml:id]
    return map:entry($id/@xml:id, string(($id/ancestor::t:div[@type=("section","bibliography","textpart")]/@xml:id)[1]))) 

for $xml in doc(concat("/db/",$collection,"/",$document,".xml"))
let $script := <script type="text/javascript">
    var els = ["{string-join(distinct-values($xml//*/concat('tei:',local-name())), '","')}"];
</script>
let $doc := t:rewrite-links($xml, $map)
let $result := if ($part = "none") then
                    <div>{t:make-ceteicean($doc, $wrap),$script}</div>
                else
                    <div>{t:make-ceteicean($doc//*[@xml:id = $part], $wrap),$script}</div>
return ($result)