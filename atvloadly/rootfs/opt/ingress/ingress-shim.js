(function () {
  var path = window.location.pathname || "";
  var ingressBase = path.endsWith("/") ? path.slice(0, -1) : path;

  function shouldRewritePath(value) {
    return (
      typeof value === "string" &&
      value.startsWith("/") &&
      !value.startsWith("//") &&
      !value.startsWith(ingressBase + "/")
    );
  }

  function rewritePath(value) {
    if (!shouldRewritePath(value)) {
      return value;
    }
    return ingressBase + value;
  }

  function rewriteAbsoluteUrl(value) {
    if (typeof value !== "string") {
      return value;
    }

    if (shouldRewritePath(value)) {
      return rewritePath(value);
    }

    try {
      var url = new URL(value, window.location.origin);
      if (
        url.host === window.location.host &&
        shouldRewritePath(url.pathname)
      ) {
        url.pathname = rewritePath(url.pathname);
        return url.toString();
      }
    } catch (err) {
      return value;
    }

    return value;
  }

  var originalOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    arguments[1] = rewriteAbsoluteUrl(url);
    return originalOpen.apply(this, arguments);
  };

  if (window.fetch) {
    var originalFetch = window.fetch.bind(window);
    window.fetch = function (input, init) {
      if (typeof input === "string") {
        input = rewriteAbsoluteUrl(input);
      } else if (input instanceof Request) {
        input = new Request(rewriteAbsoluteUrl(input.url), input);
      }
      return originalFetch(input, init);
    };
  }

  if (window.WebSocket) {
    var NativeWebSocket = window.WebSocket;
    var WrappedWebSocket = function (url, protocols) {
      return protocols === undefined
        ? new NativeWebSocket(rewriteAbsoluteUrl(url))
        : new NativeWebSocket(rewriteAbsoluteUrl(url), protocols);
    };
    WrappedWebSocket.prototype = NativeWebSocket.prototype;
    Object.setPrototypeOf(WrappedWebSocket, NativeWebSocket);
    window.WebSocket = WrappedWebSocket;
  }

  var originalSetAttribute = Element.prototype.setAttribute;
  Element.prototype.setAttribute = function (name, value) {
    if (name === "src" || name === "href" || name === "action") {
      value = rewriteAbsoluteUrl(value);
    }
    return originalSetAttribute.call(this, name, value);
  };

  function patchPropertySetter(ctor, property) {
    if (!ctor || !ctor.prototype) {
      return;
    }
    var descriptor = Object.getOwnPropertyDescriptor(ctor.prototype, property);
    if (!descriptor || !descriptor.set || !descriptor.get) {
      return;
    }
    Object.defineProperty(ctor.prototype, property, {
      configurable: descriptor.configurable,
      enumerable: descriptor.enumerable,
      get: descriptor.get,
      set: function (value) {
        return descriptor.set.call(this, rewriteAbsoluteUrl(value));
      },
    });
  }

  patchPropertySetter(window.HTMLImageElement, "src");
  patchPropertySetter(window.HTMLAnchorElement, "href");
  patchPropertySetter(window.HTMLFormElement, "action");
})();
