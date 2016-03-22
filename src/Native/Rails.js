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

    var csrfTokenNode = document.head.querySelector('meta[name="csrf-token"]');
    var csrfToken =
        (csrfTokenNode === null || (typeof csrfTokenNode.content !== "string"))
            ? $Maybe.Nothing
            : $Maybe.Just(csrfTokenNode.content);

    return localRuntime.Native.Rails.values = {
        csrfToken : csrfToken
    };
}
