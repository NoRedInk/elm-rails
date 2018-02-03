# Convenience functions for working with Elm in Rails

If you see lots of `401` responses on requests other than `GET` requests, it's likely because `elm-rails` doesn't know about the CSRF token Rails includes in the header in a `<meta>` tag. For a drop-in fix, include [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) on all pages which use `elm-rails`. (Alternatively, you can pass the token into your Elm program through a flag, store it in your `Model`, and add the header to all requests manually. Needless to say, including [`csrf-xhr`](https://www.npmjs.com/package/csrf-xhr) on the page is much easier!)

---
[![NoRedInk](https://cloud.githubusercontent.com/assets/1094080/9069346/99522418-3a9d-11e5-8175-1c2bfd7a2ffe.png)](http://noredink.com/about/team)

