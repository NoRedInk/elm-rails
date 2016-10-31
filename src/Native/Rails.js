var _NoRedInk$elm_rails$Native_Rails = function(){
  var getCsrfToken = function() {
    // when we aren't in an actual dom, short curcuit
    // we can't always trust this test because mocking
    if (typeof window === "undefined"){
      return { ctor : 'Nothing' };
    }

    var csrfToken = { ctor: 'Nothing' };
    var csrfTokenNode = null;

    try {
      csrfTokenNode = document.head.querySelector('meta[name="csrf-token"]');
    } catch (e){
      // ignore document-based errors
    }

    if ((csrfTokenNode !== null) && (typeof csrfTokenNode.content === "string")){
      csrfToken = { ctor: 'Just', _0: csrfTokenNode.content };
    }

    return csrfToken;
  };

  return {
    get csrfToken () {
      return getCsrfToken();
    }
  }
}();
