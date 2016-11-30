var _NoRedInk$elm_rails$Native_Rails = function(){
  var getCsrfToken = function() {
    // when we aren't in an actual dom, short curcuit
    // we can't always trust this test because mocking
    if (typeof window === "undefined"){
      return { ctor: 'Err', _0: "Could not read <meta name=\"csrf-token\"> because window was undefined." };
    }

    var csrfTokenNode = null;

    try {
      csrfTokenNode = document.head.querySelector('meta[name="csrf-token"]');
    } catch (e){
      // ignore document-based errors
    }

    if ((csrfTokenNode !== null) && (typeof csrfTokenNode.content === "string")) {
      return { ctor: 'Ok', _0: csrfTokenNode.content };
    } else {
      return { ctor: 'Err', _0: "<meta name=\"csrf-token\"> was not found in document.head." };
    }
  };

  return {
    get csrfToken () {
      return getCsrfToken();
    }
  }
}();
