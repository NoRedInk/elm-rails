var _NoRedInk$elm_rails$Native_Rails = function(){
  var csrfTokenNode = document.head.querySelector('meta[name="csrf-token"]');
  var csrfToken =
      (csrfTokenNode === null || (typeof csrfTokenNode.content !== "string"))
          ? _elm_lang$core$Maybe$Nothing
          : _elm_lang$core$Maybe$Just(csrfTokenNode.content);
  return {
    csrfToken: csrfToken
  }
}();
