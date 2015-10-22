Elm.Native = Elm.Native || {};
Elm.Native.Rails = {};
Elm.Native.Rails.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.Rails = localRuntime.Native.Rails || {};
    if (localRuntime.Native.Rails.values)
    {
        return localRuntime.Native.Rails.values;
    }

    var NS = Elm.Native.Signal.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    var metaNode = document.querySelector('meta[name="csrf-token"]');

    var authToken = (function() {
        if (metaNode === null){
            return "";
        }
        return metaNode.content;
    })();

    return localRuntime.Native.Rails.values = {
        authToken : authToken
    };
}
