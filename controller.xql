xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
    
else if (starts-with($exist:path, "/toc/")) then
    let $path := substring-after($exist:path, "/toc/")
    let $collection := substring-before($path, "/d/")
    let $doc := substring-before(substring-after($path, "/d/"), "/")
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/get-toc.xql">
            <add-parameter name="collection" value="{$collection}"/>
            <add-parameter name="doc" value="{$doc}"/>
        </forward>
    </dispatch>
else if (starts-with($exist:path, "/ce/")) then
    (: URL like /apps/CTXQ/ce/<collection>/d/<document_id>/i/<node_id> :)
    let $path := substring-after($exist:path, "/ce/")
    let $collection := substring-before($path, "/d/")
    let $doc := substring-before(substring-after($path, "/d/"), "/")
    let $id := substring-after($path, "/i/")
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/get-cetei.xql">
            <add-parameter name="collection" value="{$collection}"/>
            <add-parameter name="doc" value="{$doc}"/>
            <add-parameter name="id" value="{$id}"/>
        </forward>
    </dispatch>
else if (contains($exist:path, "/$resources/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/$resources/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else if (starts-with($exist:path, "/html/")) then
    (:URL like /apps/CTXQ/html/<collection>/d/<document_id>/i/<node_id>:)
    let $path := substring-after($exist:path, "/html/")
    let $collection := substring-before($path, "/d/")
    let $doc := substring-before(substring-after($path, "/d/"), "/")
    let $id := substring-after($path, "/i/")
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/get-cetei.xql">
            <add-parameter name="collection" value="{$collection}"/>
            <add-parameter name="doc" value="{$doc}"/>
            <add-parameter name="id" value="{$id}"/>
            <add-parameter name="wrap" value="{true()}"/>
        </forward>
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
