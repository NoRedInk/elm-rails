Elm.Native = Elm.Native || {};
Elm.Native.Rails = {};
Elm.Native.Rails.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Rails = localRuntime.Native.Rails || {};
    if (localRuntime.Native.Rails.values)
    {
        return localRuntime.Native.Rails.values;
    }

    var $Maybe = Elm.Maybe.make(localRuntime);

    var csrfTokenName = "csrf-token"
    var csrfToken = $Maybe.Nothing;
    var potentialMetaNodes = document.head.childNodes;

    // Use this instead of document.querySelector() for pre-ES5 compatibility.
    for (var index in potentialMetaNodes) {
        var potentialMetaNode = potentialMetaNodes[index];

        if (potentialMetaNode.tagName === "META"
            && potentialMetaNode.name === csrfTokenName
            && (typeof potentialMetaNode.content) === "string")
        {
            csrfToken = $Maybe.Just(potentialMetaNode.content);;
            break;
        }
    }

    return localRuntime.Native.Rails.values = {
        csrfToken : csrfToken
    };
}
