var _NoRedInk$elm_rails$Native_Rails = function(){
  var csrfTokenNode = document.head.querySelector('meta[name="csrf-token"]');
  var csrfToken =
      (csrfTokenNode === null || (typeof csrfTokenNode.content !== "string"))
          ? { ctor: 'Nothing' }
          : { ctor: 'Just', _0: csrfTokenNode.content };
  return {
    csrfToken: csrfToken
  }
}();
