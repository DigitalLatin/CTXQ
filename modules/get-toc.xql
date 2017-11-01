xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript";

let $collection := request:get-parameter("collection", "none")
let $document := request:get-parameter("doc", "none")
for $xml in doc(concat("/db/",$collection,"/",$document,".xml"))
    let $divs := $xml//t:div[@type=("textpart","section","bibliography")]
    return <t:list> {
        for $d in $divs[@xml:id and not(@type = "bibliography" and ancestor::t:div[@type="bibliography"])]
            let $id := $d/@xml:id
            let $name := if ($d/t:head) 
                then 
                    string-join($d/t:head//text(), "")
                else
                    $d/@n
            return <t:item id="{$id}">{$name}</t:item>
    }</t:list>
        