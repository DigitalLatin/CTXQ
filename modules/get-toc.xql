xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript";

declare function t:make-toc($node as node(), $xml) as node() {
    typeswitch($node)
        case element()
            return if (local-name($node) = "ref") then
                element {name($node)} {
                    attribute target {$node/@target}, 
                    attribute n {$xml//t:div[@xml:id=substring-after($node/@target,'#')]/@type},
                    for $child in $node/node()
                        return t:make-toc($child, $xml) }
            else
                element {name($node)} {
                    for $att in $node/@*
                        return t:make-toc($att, $xml),
                    for $child in $node/node()
                        return t:make-toc($child, $xml)
                }
        default return $node
};

let $collection := request:get-parameter("collection", "none")
let $document := request:get-parameter("doc", "none")
for $xml in doc(concat("/db/",$collection,"/",$document,".xml"))
    return if ($xml//t:div[@subtype="toc"]) then 
         t:make-toc($xml//t:div[@subtype="toc"]/t:list, $xml)
    else
        let $divs := $xml//t:div[@type=("textpart","section","bibliography")]
        return <t:list> {
            for $d in $divs[@xml:id and not(@type = "bibliography" and ancestor::t:div[@type="bibliography"])]
                let $id := $d/@xml:id
                let $name := if ($d/t:head) 
                    then 
                        string-join($d/t:head//text(), "")
                    else
                        $d/@n
                return <t:item><t:ref target="{$id}" n="{$d/@type}">{$name}</t:ref></t:item>
        }</t:list>
        