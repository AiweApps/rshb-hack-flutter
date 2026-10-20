// Injected at document start into the retailer page (main frame, page world).
// WKWebView cannot read request headers the way Android shouldInterceptRequest does,
// so the site's own fetch/XHR calls are observed here instead. The captured values stay
// in page memory: native code only receives {ready: true}, never the header values.
(() => {
  if (location.origin !== 'https://www.perekrestok.ru' || window.__retailProbeSession) return;

  const API_PREFIX = '/api/customer/';
  const WANTED = new Set(['auth', 'x-device-id']);
  const captured = {};
  const nativeFetch = window.fetch.bind(window);
  let announced = false;

  const isCustomerApi = (url) => {
    try {
      const parsed = new URL(url, location.href);
      return parsed.origin === location.origin && parsed.pathname.startsWith(API_PREFIX);
    } catch (_) {
      return false;
    }
  };

  const announce = () => {
    if (announced || !captured.auth) return;
    announced = true;
    try { window.webkit.messageHandlers.retailSession.postMessage({ ready: true }); } catch (_) {}
  };

  const remember = (name, value) => {
    const key = String(name).toLowerCase();
    if (!WANTED.has(key) || typeof value !== 'string' || value.length === 0 || value.length > 4096) return;
    captured[key] = value;
    announce();
  };

  window.fetch = function (input, init) {
    try {
      const url = typeof input === 'string' ? input : (input && input.url) || String(input);
      if (isCustomerApi(url)) {
        if (input instanceof Request) input.headers.forEach((value, key) => remember(key, value));
        if (init && init.headers) new Headers(init.headers).forEach((value, key) => remember(key, value));
      }
    } catch (_) {}
    return nativeFetch.apply(this, arguments);
  };

  const open = XMLHttpRequest.prototype.open;
  const setRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__retailProbeApi = isCustomerApi(url);
    return open.apply(this, arguments);
  };
  XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
    if (this.__retailProbeApi) remember(name, value);
    return setRequestHeader.apply(this, arguments);
  };

  Object.defineProperty(window, '__retailProbeSession', {
    value: Object.freeze({
      ready: () => Boolean(captured.auth),
      headers: () => ({ ...captured }),
      fetch: nativeFetch,
      jobs: {},
    }),
    enumerable: false,
  });
})();
