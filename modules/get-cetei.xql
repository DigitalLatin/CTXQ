xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=html media-type=text/html";

declare function t:make-ceteicean($node as node()) as node() {
    t:make-ceteicean($node, false())
};

declare function t:make-ceteicean($node as node(), $wrap as xs:boolean) as node() {
    typeswitch($node)
        case document-node() return 
            for $child in $node/node()
            return t:make-ceteicean($child)
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

let $collection := request:get-parameter("collection", "none")
let $document := request:get-parameter("doc", "none")
let $part := request:get-parameter("id", "none")
let $wrap := request:get-parameter("wrap", false())

for $xml in doc(concat("/db/",$collection,"/",$document,".xml"))
let $script := <script type="text/javascript">
    var els = ["{string-join(distinct-values($xml//*/local-name()), '","')}"];
</script>
let $result := if ($part = "none") then
                    <div>{t:make-ceteicean($xml, $wrap),$script}</div>
                else
                    <div>{t:make-ceteicean($xml//id($part), $wrap),$script}</div>
return ($result)