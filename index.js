/* Compiled by kdc on Thu Aug 21 2014 00:19:47 GMT+0000 (UTC) */
(function() {
/* KDAPP STARTS */
if (typeof window.appPreview !== "undefined" && window.appPreview !== null) {
  var appView = window.appPreview
}
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/oauth.js */
(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports = {
  oauthd_url: "https://oauth.io",
  oauthd_api: "https://oauth.io/api",
  version: "web-0.2.4",
  options: {}
};

},{}],2:[function(require,module,exports){
"use strict";
var Url, cache, config, cookies, sha1;

config = require("../config");

cookies = require("../tools/cookies");

cache = require("../tools/cache");

Url = require("../tools/url");

sha1 = require("../tools/sha1");

module.exports = function(window, document, jQuery, navigator) {
  var $, client_states, oauth_result, oauthio, parse_urlfragment, providers_api, providers_cb, providers_desc;
  $ = jQuery;
  Url = Url(document);
  cookies.init(config, document);
  cache.init(cookies, config);
  oauthio = {
    request: {}
  };
  providers_desc = {};
  providers_cb = {};
  providers_api = {
    execProvidersCb: function(provider, e, r) {
      var cbs, i;
      if (providers_cb[provider]) {
        cbs = providers_cb[provider];
        delete providers_cb[provider];
        for (i in cbs) {
          cbs[i](e, r);
        }
      }
    },
    getDescription: function(provider, opts, callback) {
      opts = opts || {};
      if (typeof providers_desc[provider] === "object") {
        return callback(null, providers_desc[provider]);
      }
      if (!providers_desc[provider]) {
        providers_api.fetchDescription(provider);
      }
      if (!opts.wait) {
        return callback(null, {});
      }
      providers_cb[provider] = providers_cb[provider] || [];
      providers_cb[provider].push(callback);
    }
  };
  config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];
  client_states = [];
  oauth_result = void 0;
  (parse_urlfragment = function() {
    var cookie_state, results;
    results = /[\\#&]oauthio=([^&]*)/.exec(document.location.hash);
    if (results) {
      document.location.hash = document.location.hash.replace(/&?oauthio=[^&]*/, "");
      oauth_result = decodeURIComponent(results[1].replace(/\+/g, " "));
      cookie_state = cookies.readCookie("oauthio_state");
      if (cookie_state) {
        client_states.push(cookie_state);
        cookies.eraseCookie("oauthio_state");
      }
    }
  })();
  window.location_operations = {
    reload: function() {
      return document.location.reload();
    },
    getHash: function() {
      return document.location.hash;
    },
    setHash: function(newHash) {
      return document.location.hash = newHash;
    },
    changeHref: function(newLocation) {
      return document.location.href = newLocation;
    }
  };
  return function(exports) {
    var delayedFunctions, delayfn, e, _preloadcalls;
    delayedFunctions = function($) {
      oauthio.request = require("./oauthio_requests")($, config, client_states, cache, providers_api);
      providers_api.fetchDescription = function(provider) {
        if (providers_desc[provider]) {
          return;
        }
        providers_desc[provider] = true;
        $.ajax({
          url: config.oauthd_api + "/providers/" + provider,
          data: {
            extend: true
          },
          dataType: "json"
        }).done(function(data) {
          providers_desc[provider] = data.data;
          providers_api.execProvidersCb(provider, null, data.data);
        }).always(function() {
          if (typeof providers_desc[provider] !== "object") {
            delete providers_desc[provider];
            providers_api.execProvidersCb(provider, new Error("Unable to fetch request description"));
          }
        });
      };
    };
    if (exports.OAuth == null) {
      exports.OAuth = {
        initialize: function(public_key, options) {
          var i;
          config.key = public_key;
          if (options) {
            for (i in options) {
              config.options[i] = options[i];
            }
          }
        },
        setOAuthdURL: function(url) {
          config.oauthd_url = url;
          config.oauthd_base = Url.getAbsUrl(config.oauthd_url).match(/^.{2,5}:\/\/[^/]+/)[0];
        },
        getVersion: function() {
          return config.version;
        },
        create: function(provider, tokens, request) {
          var i, make_res, make_res_endpoint, res;
          if (!tokens) {
            return cache.tryCache(exports.OAuth, provider, true);
          }
          if (typeof request !== "object") {
            providers_api.fetchDescription(provider);
          }
          make_res = function(method) {
            return oauthio.request.mkHttp(provider, tokens, request, method);
          };
          make_res_endpoint = function(method, url) {
            return oauthio.request.mkHttpEndpoint(provider, tokens, request, method, url);
          };
          res = {};
          for (i in tokens) {
            res[i] = tokens[i];
          }
          res.get = make_res("GET");
          res.post = make_res("POST");
          res.put = make_res("PUT");
          res.patch = make_res("PATCH");
          res.del = make_res("DELETE");
          res.me = oauthio.request.mkHttpMe(provider, tokens, request, "GET");
          return res;
        },
        popup: function(provider, opts, callback) {
          var defer, frm, getMessage, gotmessage, interval, res, url, wnd, wndTimeout, wnd_options, wnd_settings, _ref;
          gotmessage = false;
          getMessage = function(e) {
            if (e.origin !== config.oauthd_base) {
              return;
            }
            try {
              wnd.close();
            } catch (_error) {}
            opts.data = e.data;
            oauthio.request.sendCallback(opts, defer);
            return gotmessage = true;
          };
          wnd = void 0;
          frm = void 0;
          wndTimeout = void 0;
          defer = (_ref = window.jQuery) != null ? _ref.Deferred() : void 0;
          opts = opts || {};
          if (!config.key) {
            if (defer != null) {
              defer.reject(new Error("OAuth object must be initialized"));
            }
            if (callback == null) {
              return defer.promise();
            } else {
              return callback(new Error("OAuth object must be initialized"));
            }
          }
          if (arguments.length === 2 && typeof opts === 'function') {
            callback = opts;
            opts = {};
          }
          if (cache.cacheEnabled(opts.cache)) {
            res = cache.tryCache(exports.OAuth, provider, opts.cache);
            if (res) {
              if (defer != null) {
                defer.resolve(res);
              }
              if (callback) {
                return callback(null, res);
              } else {
                return defer.promise();
              }
            }
          }
          if (!opts.state) {
            opts.state = sha1.create_hash();
            opts.state_type = "client";
          }
          client_states.push(opts.state);
          url = config.oauthd_url + "/auth/" + provider + "?k=" + config.key;
          url += "&d=" + encodeURIComponent(Url.getAbsUrl("/"));
          if (opts) {
            url += "&opts=" + encodeURIComponent(JSON.stringify(opts));
          }
          if (opts.wnd_settings) {
            wnd_settings = opts.wnd_settings;
            delete opts.wnd_settings;
          } else {
            wnd_settings = {
              width: Math.floor(window.outerWidth * 0.8),
              height: Math.floor(window.outerHeight * 0.5)
            };
          }
          if (wnd_settings.height == null) {
            wnd_settings.height = (wnd_settings.height < 350 ? 350 : void 0);
          }
          if (wnd_settings.width == null) {
            wnd_settings.width = (wnd_settings.width < 800 ? 800 : void 0);
          }
          if (wnd_settings.left == null) {
            wnd_settings.left = window.screenX + (window.outerWidth - wnd_settings.width) / 2;
          }
          if (wnd_settings.top == null) {
            wnd_settings.top = window.screenY + (window.outerHeight - wnd_settings.height) / 8;
          }
          wnd_options = "width=" + wnd_settings.width + ",height=" + wnd_settings.height;
          wnd_options += ",toolbar=0,scrollbars=1,status=1,resizable=1,location=1,menuBar=0";
          wnd_options += ",left=" + wnd_settings.left + ",top=" + wnd_settings.top;
          opts = {
            provider: provider,
            cache: opts.cache
          };
          opts.callback = function(e, r) {
            if (window.removeEventListener) {
              window.removeEventListener("message", getMessage, false);
            } else if (window.detachEvent) {
              window.detachEvent("onmessage", getMessage);
            } else {
              if (document.detachEvent) {
                document.detachEvent("onmessage", getMessage);
              }
            }
            opts.callback = function() {};
            if (wndTimeout) {
              clearTimeout(wndTimeout);
              wndTimeout = undefined;
            }
            if (callback) {
              return callback(e, r);
            } else {
              return undefined;
            }
          };
          if (window.attachEvent) {
            window.attachEvent("onmessage", getMessage);
          } else if (document.attachEvent) {
            document.attachEvent("onmessage", getMessage);
          } else {
            if (window.addEventListener) {
              window.addEventListener("message", getMessage, false);
            }
          }
          if (typeof chrome !== "undefined" && chrome.runtime && chrome.runtime.onMessageExternal) {
            chrome.runtime.onMessageExternal.addListener(function(request, sender, sendResponse) {
              request.origin = sender.url.match(/^.{2,5}:\/\/[^/]+/)[0];
              if (defer != null) {
                defer.resolve();
              }
              return getMessage(request);
            });
          }
          if (!frm && (navigator.userAgent.indexOf("MSIE") !== -1 || navigator.appVersion.indexOf("Trident/") > 0)) {
            frm = document.createElement("iframe");
            frm.src = config.oauthd_url + "/auth/iframe?d=" + encodeURIComponent(Url.getAbsUrl("/"));
            frm.width = 0;
            frm.height = 0;
            frm.frameBorder = 0;
            frm.style.visibility = "hidden";
            document.body.appendChild(frm);
          }
          wndTimeout = setTimeout(function() {
            if (defer != null) {
              defer.reject(new Error("Authorization timed out"));
            }
            if (opts.callback && typeof opts.callback === "function") {
              opts.callback(new Error("Authorization timed out"));
            }
            try {
              wnd.close();
            } catch (_error) {}
          }, 1200 * 1000);
          wnd = window.open(url, "Authorization", wnd_options);
          if (wnd) {
            wnd.focus();
            interval = window.setInterval(function() {
              if (wnd === null || wnd.closed) {
                window.clearInterval(interval);
                if (!gotmessage) {
                  if (defer != null) {
                    defer.reject(new Error("The popup was closed"));
                  }
                  if (opts.callback && typeof opts.callback === "function") {
                    return opts.callback(new Error("The popup was closed"));
                  }
                }
              }
            }, 500);
          } else {
            if (defer != null) {
              defer.reject(new Error("Could not open a popup"));
            }
            if (opts.callback && typeof opts.callback === "function") {
              opts.callback(new Error("Could not open a popup"));
            }
          }
          return defer != null ? defer.promise() : void 0;
        },
        redirect: function(provider, opts, url) {
          var redirect_uri, res;
          if (arguments.length === 2) {
            url = opts;
            opts = {};
          }
          if (cache.cacheEnabled(opts.cache)) {
            res = cache.tryCache(exports.OAuth, provider, opts.cache);
            if (res) {
              url = Url.getAbsUrl(url) + (url.indexOf("#") === -1 ? "#" : "&") + "oauthio=cache";
              window.location_operations.changeHref(url);
              window.location_operations.reload();
              return;
            }
          }
          if (!opts.state) {
            opts.state = sha1.create_hash();
            opts.state_type = "client";
          }
          cookies.createCookie("oauthio_state", opts.state);
          redirect_uri = encodeURIComponent(Url.getAbsUrl(url));
          url = config.oauthd_url + "/auth/" + provider + "?k=" + config.key;
          url += "&redirect_uri=" + redirect_uri;
          if (opts) {
            url += "&opts=" + encodeURIComponent(JSON.stringify(opts));
          }
          window.location_operations.changeHref(url);
        },
        callback: function(provider, opts, callback) {
          var defer, res, _ref;
          defer = (_ref = window.jQuery) != null ? _ref.Deferred() : void 0;
          if (arguments.length === 1 && typeof provider === "function") {
            callback = provider;
            provider = undefined;
            opts = {};
          }
          if (arguments.length === 1 && typeof provider === "string") {
            opts = {};
          }
          if (arguments.length === 2 && typeof opts === "function") {
            callback = opts;
            opts = {};
          }
          if (cache.cacheEnabled(opts.cache) || oauth_result === "cache") {
            res = cache.tryCache(exports.OAuth, provider, opts.cache);
            if (oauth_result === "cache" && (typeof provider !== "string" || !provider)) {
              if (defer != null) {
                defer.reject(new Error("You must set a provider when using the cache"));
              }
              if (callback) {
                return callback(new Error("You must set a provider when using the cache"));
              } else {
                return defer != null ? defer.promise() : void 0;
              }
            }
            if (res) {
              if (callback) {
                if (res) {
                  return callback(null, res);
                }
              } else {
                if (defer != null) {
                  defer.resolve(res);
                }
                return defer != null ? defer.promise() : void 0;
              }
            }
          }
          if (!oauth_result) {
            return;
          }
          oauthio.request.sendCallback({
            data: oauth_result,
            provider: provider,
            cache: opts.cache,
            callback: callback
          }, defer);
          return defer != null ? defer.promise() : void 0;
        },
        clearCache: function(provider) {
          cookies.eraseCookie("oauthio_provider_" + provider);
        },
        http_me: function(opts) {
          if (oauthio.request.http_me) {
            oauthio.request.http_me(opts);
          }
        },
        http: function(opts) {
          if (oauthio.request.http) {
            oauthio.request.http(opts);
          }
        }
      };
      if (typeof window.jQuery === "undefined") {
        _preloadcalls = [];
        delayfn = void 0;
        if (typeof chrome !== "undefined" && chrome.extension) {
          delayfn = function() {
            return function() {
              throw new Error("Please include jQuery before oauth.js");
            };
          };
        } else {
          e = document.createElement("script");
          e.src = "//code.jquery.com/jquery.min.js";
          e.type = "text/javascript";
          e.onload = function() {
            var i;
            delayedFunctions(window.jQuery);
            for (i in _preloadcalls) {
              _preloadcalls[i].fn.apply(null, _preloadcalls[i].args);
            }
          };
          document.getElementsByTagName("head")[0].appendChild(e);
          delayfn = function(f) {
            return function() {
              var arg, args_copy;
              args_copy = [];
              for (arg in arguments) {
                args_copy[arg] = arguments[arg];
              }
              _preloadcalls.push({
                fn: f,
                args: args_copy
              });
            };
          };
        }
        oauthio.request.http = delayfn(function() {
          oauthio.request.http.apply(exports.OAuth, arguments);
        });
        providers_api.fetchDescription = delayfn(function() {
          providers_api.fetchDescription.apply(providers_api, arguments);
        });
        oauthio.request = require("./oauthio_requests")(window.jQuery, config, client_states, cache, providers_api);
      } else {
        delayedFunctions(window.jQuery);
      }
    }
  };
};

},{"../config":1,"../tools/cache":5,"../tools/cookies":6,"../tools/sha1":7,"../tools/url":8,"./oauthio_requests":3}],3:[function(require,module,exports){
var Url,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Url = require('../tools/url')();

module.exports = function($, config, client_states, cache, providers_api) {
  return {
    http: function(opts) {
      var defer, desc_opts, doRequest, i, options;
      doRequest = function() {
        var i, k, qs, request;
        request = options.oauthio.request || {};
        if (!request.cors) {
          options.url = encodeURIComponent(options.url);
          if (options.url[0] !== "/") {
            options.url = "/" + options.url;
          }
          options.url = config.oauthd_url + "/request/" + options.oauthio.provider + options.url;
          options.headers = options.headers || {};
          options.headers.oauthio = "k=" + config.key;
          if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) {
            options.headers.oauthio += "&oauthv=1";
          }
          for (k in options.oauthio.tokens) {
            options.headers.oauthio += "&" + encodeURIComponent(k) + "=" + encodeURIComponent(options.oauthio.tokens[k]);
          }
          delete options.oauthio;
          return $.ajax(options);
        }
        if (options.oauthio.tokens) {
          if (options.oauthio.tokens.access_token) {
            options.oauthio.tokens.token = options.oauthio.tokens.access_token;
          }
          if (!options.url.match(/^[a-z]{2,16}:\/\//)) {
            if (options.url[0] !== "/") {
              options.url = "/" + options.url;
            }
            options.url = request.url + options.url;
          }
          options.url = Url.replaceParam(options.url, options.oauthio.tokens, request.parameters);
          if (request.query) {
            qs = [];
            for (i in request.query) {
              qs.push(encodeURIComponent(i) + "=" + encodeURIComponent(Url.replaceParam(request.query[i], options.oauthio.tokens, request.parameters)));
            }
            if (__indexOf.call(options.url, "?") >= 0) {
              options.url += "&" + qs;
            } else {
              options.url += "?" + qs;
            }
          }
          if (request.headers) {
            options.headers = options.headers || {};
            for (i in request.headers) {
              options.headers[i] = Url.replaceParam(request.headers[i], options.oauthio.tokens, request.parameters);
            }
          }
          delete options.oauthio;
          return $.ajax(options);
        }
      };
      options = {};
      i = void 0;
      for (i in opts) {
        options[i] = opts[i];
      }
      if (!options.oauthio.request || options.oauthio.request === true) {
        desc_opts = {
          wait: !!options.oauthio.request
        };
        defer = $ != null ? $.Deferred() : void 0;
        providers_api.getDescription(options.oauthio.provider, desc_opts, function(e, desc) {
          if (e) {
            return defer != null ? defer.reject(e) : void 0;
          }
          if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) {
            options.oauthio.request = desc.oauth1 && desc.oauth1.request;
          } else {
            options.oauthio.request = desc.oauth2 && desc.oauth2.request;
          }
          if (defer != null) {
            defer.resolve();
          }
        });
        return defer != null ? defer.then(doRequest) : void 0;
      } else {
        return doRequest();
      }
    },
    http_me: function(opts) {
      var defer, desc_opts, doRequest, k, options;
      doRequest = function() {
        var defer, k, promise, request;
        defer = $ != null ? $.Deferred() : void 0;
        request = options.oauthio.request || {};
        options.url = config.oauthd_url + "/auth/" + options.oauthio.provider + "/me";
        options.headers = options.headers || {};
        options.headers.oauthio = "k=" + config.key;
        if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) {
          options.headers.oauthio += "&oauthv=1";
        }
        for (k in options.oauthio.tokens) {
          options.headers.oauthio += "&" + encodeURIComponent(k) + "=" + encodeURIComponent(options.oauthio.tokens[k]);
        }
        delete options.oauthio;
        promise = $.ajax(options);
        $.when(promise).done(function(data) {
          if (defer != null) {
            defer.resolve(data.data);
          }
        }).fail(function(data) {
          if (data.responseJSON) {
            if (defer != null) {
              defer.reject(data.responseJSON.data);
            }
          } else {
            if (defer != null) {
              defer.reject(new Error("An error occured while trying to access the resource"));
            }
          }
        });
        return defer != null ? defer.promise() : void 0;
      };
      options = {};
      for (k in opts) {
        options[k] = opts[k];
      }
      if (!options.oauthio.request || options.oauthio.request === true) {
        desc_opts = {
          wait: !!options.oauthio.request
        };
        defer = $ != null ? $.Deferred() : void 0;
        providers_api.getDescription(options.oauthio.provider, desc_opts, function(e, desc) {
          if (e) {
            return defer != null ? defer.reject(e) : void 0;
          }
          if (options.oauthio.tokens.oauth_token && options.oauthio.tokens.oauth_token_secret) {
            options.oauthio.request = desc.oauth1 && desc.oauth1.request;
          } else {
            options.oauthio.request = desc.oauth2 && desc.oauth2.request;
          }
          if (defer != null) {
            defer.resolve();
          }
        });
        return defer != null ? defer.then(doRequest) : void 0;
      } else {
        return doRequest();
      }
    },
    mkHttp: function(provider, tokens, request, method) {
      var base;
      base = this;
      return function(opts, opts2) {
        var i, options;
        options = {};
        if (typeof opts === "string") {
          if (typeof opts2 === "object") {
            for (i in opts2) {
              options[i] = opts2[i];
            }
          }
          options.url = opts;
        } else if (typeof opts === "object") {
          for (i in opts) {
            options[i] = opts[i];
          }
        }
        options.type = options.type || method;
        options.oauthio = {
          provider: provider,
          tokens: tokens,
          request: request
        };
        return base.http(options);
      };
    },
    mkHttpMe: function(provider, tokens, request, method) {
      var base;
      base = this;
      return function(filter) {
        var options;
        options = {};
        options.type = options.type || method;
        options.oauthio = {
          provider: provider,
          tokens: tokens,
          request: request
        };
        options.data = options.data || {};
        options.data.filter = (filter ? filter.join(",") : undefined);
        return base.http_me(options);
      };
    },
    sendCallback: function(opts, defer) {
      var base, data, e, err, i, k, make_res, request, res, tokens, v;
      base = this;
      data = void 0;
      err = void 0;
      try {
        data = JSON.parse(opts.data);
      } catch (_error) {
        e = _error;
        if (defer != null) {
          defer.reject(new Error("Error while parsing result"));
        }
        return opts.callback(new Error("Error while parsing result"));
      }
      if (!data || !data.provider) {
        return;
      }
      if (opts.provider && data.provider.toLowerCase() !== opts.provider.toLowerCase()) {
        err = new Error("Returned provider name does not match asked provider");
        if (defer != null) {
          defer.reject(err);
        }
        if (opts.callback && typeof opts.callback === "function") {
          return opts.callback(err);
        } else {
          return;
        }
      }
      if (data.status === "error" || data.status === "fail") {
        err = new Error(data.message);
        err.body = data.data;
        if (defer != null) {
          defer.reject(err);
        }
        if (opts.callback && typeof opts.callback === "function") {
          return opts.callback(err);
        } else {
          return;
        }
      }
      if (data.status !== "success" || !data.data) {
        err = new Error();
        err.body = data.data;
        if (defer != null) {
          defer.reject(err);
        }
        if (opts.callback && typeof opts.callback === "function") {
          return opts.callback(err);
        } else {
          return;
        }
      }
      data.state = data.state.replace(/\s+/g, "");
      for (k in client_states) {
        v = client_states[k];
        client_states[k] = v.replace(/\s+/g, "");
      }
      if (!data.state || client_states.indexOf(data.state) === -1) {
        if (defer != null) {
          defer.reject(new Error("State is not matching"));
        }
        if (opts.callback && typeof opts.callback === "function") {
          return opts.callback(new Error("State is not matching"));
        } else {
          return;
        }
      }
      if (!opts.provider) {
        data.data.provider = data.provider;
      }
      res = data.data;
      if (cache.cacheEnabled(opts.cache) && res) {
        cache.storeCache(data.provider, res);
      }
      request = res.request;
      delete res.request;
      tokens = void 0;
      if (res.access_token) {
        tokens = {
          access_token: res.access_token
        };
      } else if (res.oauth_token && res.oauth_token_secret) {
        tokens = {
          oauth_token: res.oauth_token,
          oauth_token_secret: res.oauth_token_secret
        };
      }
      if (!request) {
        if (defer != null) {
          defer.resolve(res);
        }
        if (opts.callback && typeof opts.callback === "function") {
          return opts.callback(null, res);
        } else {
          return;
        }
      }
      if (request.required) {
        for (i in request.required) {
          tokens[request.required[i]] = res[request.required[i]];
        }
      }
      make_res = function(method) {
        return base.mkHttp(data.provider, tokens, request, method);
      };
      res.get = make_res("GET");
      res.post = make_res("POST");
      res.put = make_res("PUT");
      res.patch = make_res("PATCH");
      res.del = make_res("DELETE");
      res.me = base.mkHttpMe(data.provider, tokens, request, "GET");
      if (defer != null) {
        defer.resolve(res);
      }
      if (opts.callback && typeof opts.callback === "function") {
        return opts.callback(null, res);
      } else {

      }
    }
  };
};

},{"../tools/url":8}],4:[function(require,module,exports){
var OAuth_creator, jquery;

if (typeof jQuery !== "undefined" && jQuery !== null) {
  jquery = jQuery;
} else {
  jquery = void 0;
}

OAuth_creator = require('./lib/oauth')(window, document, jquery, navigator);

OAuth_creator(window || this);

},{"./lib/oauth":2}],5:[function(require,module,exports){
module.exports = {
  init: function(cookies_module, config) {
    this.config = config;
    return this.cookies = cookies_module;
  },
  tryCache: function(OAuth, provider, cache) {
    var e, i, res;
    if (this.cacheEnabled(cache)) {
      cache = this.cookies.readCookie("oauthio_provider_" + provider);
      if (!cache) {
        return false;
      }
      cache = decodeURIComponent(cache);
    }
    if (typeof cache === "string") {
      try {
        cache = JSON.parse(cache);
      } catch (_error) {
        e = _error;
        return false;
      }
    }
    if (typeof cache === "object") {
      res = {};
      for (i in cache) {
        if (i !== "request" && typeof cache[i] !== "function") {
          res[i] = cache[i];
        }
      }
      return OAuth.create(provider, res, cache.request);
    }
    return false;
  },
  storeCache: function(provider, cache) {
    this.cookies.createCookie("oauthio_provider_" + provider, encodeURIComponent(JSON.stringify(cache)), cache.expires_in - 10 || 3600);
  },
  cacheEnabled: function(cache) {
    if (typeof cache === "undefined") {
      return this.config.options.cache;
    }
    return cache;
  }
};

},{}],6:[function(require,module,exports){

/* istanbul ignore next */
module.exports = {
  init: function(config, document) {
    this.config = config;
    return this.document = document;
  },
  createCookie: function(name, value, expires) {
    var date;
    this.eraseCookie(name);
    date = new Date();
    date.setTime(date.getTime() + (expires || 1200) * 1000);
    expires = "; expires=" + date.toGMTString();
    this.document.cookie = name + "=" + value + expires + "; path=/";
  },
  readCookie: function(name) {
    var c, ca, i, nameEQ;
    nameEQ = name + "=";
    ca = this.document.cookie.split(";");
    i = 0;
    while (i < ca.length) {
      c = ca[i];
      while (c.charAt(0) === " ") {
        c = c.substring(1, c.length);
      }
      if (c.indexOf(nameEQ) === 0) {
        return c.substring(nameEQ.length, c.length);
      }
      i++;
    }
    return null;
  },
  eraseCookie: function(name) {
    var date;
    date = new Date();
    date.setTime(date.getTime() - 86400000);
    this.document.cookie = name + "=; expires=" + date.toGMTString() + "; path=/";
  }
};

},{}],7:[function(require,module,exports){
var b64pad, hexcase;

hexcase = 0;

b64pad = "";


/* istanbul ignore next */

module.exports = {
  hex_sha1: function(s) {
    return this.rstr2hex(this.rstr_sha1(this.str2rstr_utf8(s)));
  },
  b64_sha1: function(s) {
    return this.rstr2b64(this.rstr_sha1(this.str2rstr_utf8(s)));
  },
  any_sha1: function(s, e) {
    return this.rstr2any(this.rstr_sha1(this.str2rstr_utf8(s)), e);
  },
  hex_hmac_sha1: function(k, d) {
    return this.rstr2hex(this.rstr_hmac_sha1(this.str2rstr_utf8(k), this.str2rstr_utf8(d)));
  },
  b64_hmac_sha1: function(k, d) {
    return this.rstr2b64(this.rstr_hmac_sha1(this.str2rstr_utf8(k), this.str2rstr_utf8(d)));
  },
  any_hmac_sha1: function(k, d, e) {
    return this.rstr2any(this.rstr_hmac_sha1(this.str2rstr_utf8(k), this.str2rstr_utf8(d)), e);
  },
  sha1_vm_test: function() {
    return thishex_sha1("abc").toLowerCase() === "a9993e364706816aba3e25717850c26c9cd0d89d";
  },
  rstr_sha1: function(s) {
    return this.binb2rstr(this.binb_sha1(this.rstr2binb(s), s.length * 8));
  },
  rstr_hmac_sha1: function(key, data) {
    var bkey, hash, i, ipad, opad;
    bkey = this.rstr2binb(key);
    if (bkey.length > 16) {
      bkey = this.binb_sha1(bkey, key.length * 8);
    }
    ipad = Array(16);
    opad = Array(16);
    i = 0;
    while (i < 16) {
      ipad[i] = bkey[i] ^ 0x36363636;
      opad[i] = bkey[i] ^ 0x5C5C5C5C;
      i++;
    }
    hash = this.binb_sha1(ipad.concat(this.rstr2binb(data)), 512 + data.length * 8);
    return this.binb2rstr(this.binb_sha1(opad.concat(hash), 512 + 160));
  },
  rstr2hex: function(input) {
    var e, hex_tab, i, output, x;
    try {
      hexcase;
    } catch (_error) {
      e = _error;
      hexcase = 0;
    }
    hex_tab = (hexcase ? "0123456789ABCDEF" : "0123456789abcdef");
    output = "";
    x = void 0;
    i = 0;
    while (i < input.length) {
      x = input.charCodeAt(i);
      output += hex_tab.charAt((x >>> 4) & 0x0F) + hex_tab.charAt(x & 0x0F);
      i++;
    }
    return output;
  },
  rstr2b64: function(input) {
    var e, i, j, len, output, tab, triplet;
    try {
      b64pad;
    } catch (_error) {
      e = _error;
      b64pad = "";
    }
    tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    output = "";
    len = input.length;
    i = 0;
    while (i < len) {
      triplet = (input.charCodeAt(i) << 16) | (i + 1 < len ? input.charCodeAt(i + 1) << 8 : 0) | (i + 2 < len ? input.charCodeAt(i + 2) : 0);
      j = 0;
      while (j < 4) {
        if (i * 8 + j * 6 > input.length * 8) {
          output += b64pad;
        } else {
          output += tab.charAt((triplet >>> 6 * (3 - j)) & 0x3F);
        }
        j++;
      }
      i += 3;
    }
    return output;
  },
  rstr2any: function(input, encoding) {
    var dividend, divisor, full_length, i, output, q, quotient, remainders, x;
    divisor = encoding.length;
    remainders = Array();
    i = void 0;
    q = void 0;
    x = void 0;
    quotient = void 0;
    dividend = Array(Math.ceil(input.length / 2));
    i = 0;
    while (i < dividend.length) {
      dividend[i] = (input.charCodeAt(i * 2) << 8) | input.charCodeAt(i * 2 + 1);
      i++;
    }
    while (dividend.length > 0) {
      quotient = Array();
      x = 0;
      i = 0;
      while (i < dividend.length) {
        x = (x << 16) + dividend[i];
        q = Math.floor(x / divisor);
        x -= q * divisor;
        if (quotient.length > 0 || q > 0) {
          quotient[quotient.length] = q;
        }
        i++;
      }
      remainders[remainders.length] = x;
      dividend = quotient;
    }
    output = "";
    i = remainders.length - 1;
    while (i >= 0) {
      output += encoding.charAt(remainders[i]);
      i--;
    }
    full_length = Math.ceil(input.length * 8 / (Math.log(encoding.length) / Math.log(2)));
    i = output.length;
    while (i < full_length) {
      output = encoding[0] + output;
      i++;
    }
    return output;
  },
  str2rstr_utf8: function(input) {
    var i, output, x, y;
    output = "";
    i = -1;
    x = void 0;
    y = void 0;
    while (++i < input.length) {
      x = input.charCodeAt(i);
      y = (i + 1 < input.length ? input.charCodeAt(i + 1) : 0);
      if (0xD800 <= x && x <= 0xDBFF && 0xDC00 <= y && y <= 0xDFFF) {
        x = 0x10000 + ((x & 0x03FF) << 10) + (y & 0x03FF);
        i++;
      }
      if (x <= 0x7F) {
        output += String.fromCharCode(x);
      } else if (x <= 0x7FF) {
        output += String.fromCharCode(0xC0 | ((x >>> 6) & 0x1F), 0x80 | (x & 0x3F));
      } else if (x <= 0xFFFF) {
        output += String.fromCharCode(0xE0 | ((x >>> 12) & 0x0F), 0x80 | ((x >>> 6) & 0x3F), 0x80 | (x & 0x3F));
      } else {
        if (x <= 0x1FFFFF) {
          output += String.fromCharCode(0xF0 | ((x >>> 18) & 0x07), 0x80 | ((x >>> 12) & 0x3F), 0x80 | ((x >>> 6) & 0x3F), 0x80 | (x & 0x3F));
        }
      }
    }
    return output;
  },
  str2rstr_utf16le: function(input) {
    var i, output;
    output = "";
    i = 0;
    while (i < input.length) {
      output += String.fromCharCode(input.charCodeAt(i) & 0xFF, (input.charCodeAt(i) >>> 8) & 0xFF);
      i++;
    }
    return output;
  },
  str2rstr_utf16be: function(input) {
    var i, output;
    output = "";
    i = 0;
    while (i < input.length) {
      output += String.fromCharCode((input.charCodeAt(i) >>> 8) & 0xFF, input.charCodeAt(i) & 0xFF);
      i++;
    }
    return output;
  },
  rstr2binb: function(input) {
    var i, output;
    output = Array(input.length >> 2);
    i = 0;
    while (i < output.length) {
      output[i] = 0;
      i++;
    }
    i = 0;
    while (i < input.length * 8) {
      output[i >> 5] |= (input.charCodeAt(i / 8) & 0xFF) << (24 - i % 32);
      i += 8;
    }
    return output;
  },
  binb2rstr: function(input) {
    var i, output;
    output = "";
    i = 0;
    while (i < input.length * 32) {
      output += String.fromCharCode((input[i >> 5] >>> (24 - i % 32)) & 0xFF);
      i += 8;
    }
    return output;
  },
  binb_sha1: function(x, len) {
    var a, b, c, d, e, i, j, olda, oldb, oldc, oldd, olde, t, w;
    x[len >> 5] |= 0x80 << (24 - len % 32);
    x[((len + 64 >> 9) << 4) + 15] = len;
    w = Array(80);
    a = 1732584193;
    b = -271733879;
    c = -1732584194;
    d = 271733878;
    e = -1009589776;
    i = 0;
    while (i < x.length) {
      olda = a;
      oldb = b;
      oldc = c;
      oldd = d;
      olde = e;
      j = 0;
      while (j < 80) {
        if (j < 16) {
          w[j] = x[i + j];
        } else {
          w[j] = this.bit_rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
        }
        t = this.safe_add(this.safe_add(this.bit_rol(a, 5), this.sha1_ft(j, b, c, d)), this.safe_add(this.safe_add(e, w[j]), this.sha1_kt(j)));
        e = d;
        d = c;
        c = this.bit_rol(b, 30);
        b = a;
        a = t;
        j++;
      }
      a = this.safe_add(a, olda);
      b = this.safe_add(b, oldb);
      c = this.safe_add(c, oldc);
      d = this.safe_add(d, oldd);
      e = this.safe_add(e, olde);
      i += 16;
    }
    return Array(a, b, c, d, e);
  },
  sha1_ft: function(t, b, c, d) {
    if (t < 20) {
      return (b & c) | ((~b) & d);
    }
    if (t < 40) {
      return b ^ c ^ d;
    }
    if (t < 60) {
      return (b & c) | (b & d) | (c & d);
    }
    return b ^ c ^ d;
  },
  sha1_kt: function(t) {
    if (t < 20) {
      return 1518500249;
    } else {
      if (t < 40) {
        return 1859775393;
      } else {
        if (t < 60) {
          return -1894007588;
        } else {
          return -899497514;
        }
      }
    }
  },
  safe_add: function(x, y) {
    var lsw, msw;
    lsw = (x & 0xFFFF) + (y & 0xFFFF);
    msw = (x >> 16) + (y >> 16) + (lsw >> 16);
    return (msw << 16) | (lsw & 0xFFFF);
  },
  bit_rol: function(num, cnt) {
    return (num << cnt) | (num >>> (32 - cnt));
  },
  create_hash: function() {
    var hash;
    hash = this.b64_sha1((new Date()).getTime() + ":" + Math.floor(Math.random() * 9999999));
    return hash.replace(/\+/g, "-").replace(/\//g, "_").replace(/\=+$/, "");
  }
};

},{}],8:[function(require,module,exports){
module.exports = function(document) {
  return {
    getAbsUrl: function(url) {
      var base_url;
      if (url.match(/^.{2,5}:\/\//)) {
        return url;
      }
      if (url[0] === "/") {
        return document.location.protocol + "//" + document.location.host + url;
      }
      base_url = document.location.protocol + "//" + document.location.host + document.location.pathname;
      if (base_url[base_url.length - 1] !== "/" && url[0] !== "#") {
        return base_url + "/" + url;
      }
      return base_url + url;
    },
    replaceParam: function(param, rep, rep2) {
      param = param.replace(/\{\{(.*?)\}\}/g, function(m, v) {
        return rep[v] || "";
      });
      if (rep2) {
        param = param.replace(/\{(.*?)\}/g, function(m, v) {
          return rep2[v] || "";
        });
      }
      return param;
    }
  };
};

},{}]},{},[4])/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/config.coffee */
var maxSymbolsInDescription, reposInTrending, reposPerTopic, searchKeywords, searchResultCount, userInfo;

searchKeywords = ["3D Modeling", "Data Visualization", "Game Engines", "Software Development tools", "Design Essentials", "Package Manager", "CSS Preprocessors"];

searchResultCount = 50;

reposInTrending = 50;

reposPerTopic = 20;

maxSymbolsInDescription = 100;

userInfo = null;
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/utils/utils.coffee */
var bubbleSort, flatten;

flatten = function(matrix) {
  var array, element, res, _i, _j, _len, _len1;
  res = [];
  for (_i = 0, _len = matrix.length; _i < _len; _i++) {
    array = matrix[_i];
    for (_j = 0, _len1 = array.length; _j < _len1; _j++) {
      element = array[_j];
      res.push(element);
    }
  }
  return res;
};

bubbleSort = function(array) {
  var i, j, modified, _i, _j, _ref, _ref1, _ref2;
  modified = array.slice();
  for (i = _i = 0, _ref = modified.length - 1; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
    for (j = _j = 0, _ref1 = modified.length - 1 - i; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
      if (modified[j].options.stars < modified[j + 1].options.stars) {
        _ref2 = [modified[j + 1], modified[j]], modified[j] = _ref2[0], modified[j + 1] = _ref2[1];
      }
    }
  }
  return modified;
};
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/views/repoview.coffee */
var RepoView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

RepoView = (function(_super) {
  __extends(RepoView, _super);

  function RepoView(options, data) {
    if (options == null) {
      options = {};
    }
    this.cloneToMachine = __bind(this.cloneToMachine, this);
    options.name || (options.name = "Dummy Name");
    options.user || (options.user = "user");
    options.description || (options.description = "Description goes here");
    options.authorGravatarUrl || (options.authorGravatarUrl = "");
    options.cloneUrl || (options.cloneUrl = null);
    options.stars || (options.stars = 0);
    options.language || (options.language = "Language");
    options.cssClass = KD.utils.curry("repoview-container", options.cssClass);
    options.url || (options.url = "");
    if (options.description.length > maxSymbolsInDescription) {
      options.description = options.description.substring(0, maxSymbolsInDescription) + "...";
    } else {
      options.description;
    }
    RepoView.__super__.constructor.call(this, options, data);
  }

  RepoView.prototype.viewAppended = function() {
    var authorGravatarUrl, description, language, name, stars, user, _ref;
    _ref = this.getOptions(), user = _ref.user, name = _ref.name, description = _ref.description, authorGravatarUrl = _ref.authorGravatarUrl, stars = _ref.stars, language = _ref.language;
    this.addSubView(new KDCustomHTMLView({
      tagName: "img",
      cssClass: "gravatar",
      size: {
        width: 40,
        height: 40
      },
      attributes: {
        src: authorGravatarUrl
      }
    }));
    this.addSubView(new KDLabelView({
      title: "" + user + "/" + name,
      cssClass: "name"
    }));
    this.addSubView(new KDLabelView({
      title: stars,
      cssClass: "starsLabel"
    }));
    this.addSubView(new KDLabelView({
      title: language,
      cssClass: "languageLabel"
    }));
    this.addSubView(new KDCustomHTMLView({
      tagName: "div",
      cssClass: "description",
      partial: description
    }));
    return this.addSubView(new KDButtonView({
      title: "Clone",
      callback: this.cloneToMachine,
      cssClass: "cupid-green clone-button"
    }));
  };

  RepoView.prototype.cloneToMachine = function() {
    return console.log("Cloned");
  };

  RepoView.prototype.click = function(event) {
    var url;
    url = this.getOptions().url;
    return window.open(url, "_blank");
  };

  return RepoView;

})(KDListItemView);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/views/boxedlistview.coffee */
var BoxedListView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BoxedListView = (function(_super) {
  __extends(BoxedListView, _super);

  function BoxedListView(options, data) {
    if (options == null) {
      options = {};
    }
    options.header || (options.header = "Dummy Header");
    options.seeMoreCallback || (options.seeMoreCallback = void 0);
    options.cssClass = KD.utils.curry("boxedlist-container", options.cssClass);
    BoxedListView.__super__.constructor.call(this, options, data);
  }

  BoxedListView.prototype.viewAppended = function() {
    var header, seeMoreCallback, _ref;
    _ref = this.getOptions(), header = _ref.header, seeMoreCallback = _ref.seeMoreCallback;
    this.addSubView(new KDHeaderView({
      title: header,
      type: "big",
      cssClass: "box-header"
    }));
    this.addSubView(this.list = new KDListView({
      cssClass: "list"
    }));
    return this.addSubView(this.seeMoreButton = new KDButtonView({
      title: "See more",
      callback: seeMoreCallback,
      cssClass: "seemore-button"
    }));
  };

  BoxedListView.prototype.addRepo = function(repoView) {
    return this.list.addItemView(repoView);
  };

  return BoxedListView;

})(KDView);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/controller/repodatacontroller.coffee */
var RepoDataController,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

RepoDataController = (function(_super) {
  __extends(RepoDataController, _super);

  function RepoDataController() {
    this.getSearchedRepos = __bind(this.getSearchedRepos, this);
    this.getTrendingRepos = __bind(this.getTrendingRepos, this);
    return RepoDataController.__super__.constructor.apply(this, arguments);
  }

  RepoDataController.prototype.contructor = function(options, data) {
    var trendingPageController;
    if (options == null) {
      options = {};
    }
    trendingPageController = KD.singletons.trendingPageController;
    if (trendingPageController) {
      return trendingPageController;
    }
    RepoDataController.__super__.contructor.call(this, options, data);
    return this.registerSingleton("trendingPageController", this, true);
  };

  RepoDataController.prototype.getTrendingRepos = function(callback) {
    return Promise.all(searchKeywords.map((function(_this) {
      return function(topic) {
        var link;
        link = encodeURI("https://api.github.com/search/repositories?q=" + topic + "&sort=stars");
        return $.getJSON(link).then(function(json) {
          var i, _i, _results;
          _results = [];
          for (i = _i = 0; 0 <= reposPerTopic ? _i < reposPerTopic : _i > reposPerTopic; i = 0 <= reposPerTopic ? ++_i : --_i) {
            if (json.items[i] != null) {
              _results.push(_this.repoViewFromJson(json.items[i]));
            }
          }
          return _results;
        });
      };
    })(this))).then((function(_this) {
      return function(results) {
        var repo, repos, _i, _len, _results;
        repos = flatten(results);
        repos = bubbleSort(repos);
        console.log(repos);
        if (repos.length > reposInTrending) {
          repos = repos.slice(0, reposInTrending);
        }
        _results = [];
        for (_i = 0, _len = repos.length; _i < _len; _i++) {
          repo = repos[_i];
          _results.push(callback(repo));
        }
        return _results;
      };
    })(this))["catch"](function(err) {
      return console.log(err);
    });
  };

  RepoDataController.prototype.getSearchedRepos = function(callback, topic) {
    var link;
    link = encodeURI("https://api.github.com/search/repositories?q=" + topic + "&sort=stars");
    return $.getJSON(link).then((function(_this) {
      return function(json) {
        var i, _i, _results;
        _results = [];
        for (i = _i = 0; 0 <= searchResultCount ? _i < searchResultCount : _i > searchResultCount; i = 0 <= searchResultCount ? ++_i : --_i) {
          if (json.items[i] != null) {
            _results.push(callback(_this.repoViewFromJson(json.items[i])));
          }
        }
        return _results;
      };
    })(this));
  };

  RepoDataController.prototype.getMyRepos = function(callback, authToken) {
    var repoViewFromJson;
    repoViewFromJson = this.repoViewFromJson;
    return authToken.get("/user/repos").done(function(response) {
      var repo, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = response.length; _i < _len; _i++) {
        repo = response[_i];
        _results.push(callback(repoViewFromJson(repo)));
      }
      return _results;
    }).fail(function(err) {
      return console.log(err);
    });
  };

  RepoDataController.prototype.repoViewFromJson = function(json) {
    return new RepoView({
      name: json.name,
      user: json.owner.login,
      authorGravatarUrl: json.owner.avatar_url,
      cloneUrl: json.clone_url,
      description: json.description,
      stars: json.stargazers_count,
      language: json.language,
      url: json.html_url
    });
  };

  return RepoDataController;

})(KDController);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/views/trendingpageview.coffee */
var GitDashboardTrendingPageView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GitDashboardTrendingPageView = (function(_super) {
  __extends(GitDashboardTrendingPageView, _super);

  function GitDashboardTrendingPageView(options, data) {
    if (options == null) {
      options = {};
    }
    this.repoReceived = __bind(this.repoReceived, this);
    this.controller = new RepoDataController;
    options.cssClass = 'Gitdashboard';
    GitDashboardTrendingPageView.__super__.constructor.call(this, options, data);
  }

  GitDashboardTrendingPageView.prototype.viewAppended = function() {
    this.container = new KDListView({
      cssClass: "container"
    });
    this.addSubView(this.searchBox = new KDInputView({
      cssClass: "searchBox",
      placeholder: "Search..."
    }));
    this.searchBox.on('keydown', (function(_this) {
      return function(e) {
        if (e.keyCode === 13) {
          _this.container.empty();
          _this.controller.getSearchedRepos(_this.repoReceived, _this.searchBox.getValue());
          return $(".returnToTrendingPageButton").animate({
            opacity: 1
          });
        }
      };
    })(this));
    this.addSubView(this.returnToTrendingPageButton = new KDButtonView({
      title: "Return to Trending Page",
      cssClass: "returnToTrendingPageButton clean-gray",
      callback: (function(_this) {
        return function() {
          $(".returnToTrendingPageButton").animate({
            opacity: 0
          });
          _this.container.empty();
          return _this.controller.getTrendingRepos(_this.repoReceived);
        };
      })(this)
    }));
    this.addSubView(this.container);
    return this.controller.getTrendingRepos(this.repoReceived);
  };

  GitDashboardTrendingPageView.prototype.repoReceived = function(repoView) {
    return this.container.addItemView(repoView);
  };

  return GitDashboardTrendingPageView;

})(KDView);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/views/myrepospageview.coffee */
var GitDashboardMyReposPageView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GitDashboardMyReposPageView = (function(_super) {
  __extends(GitDashboardMyReposPageView, _super);

  function GitDashboardMyReposPageView(options, data) {
    if (options == null) {
      options = {};
    }
    this.repoReceived = __bind(this.repoReceived, this);
    this.controller = new RepoDataController;
    this.authToken = options.authToken;
    if (this.authToken == null) {
      throw new Error("No authentication token provided");
    }
    options.cssClass = 'Gitdashboard';
    GitDashboardMyReposPageView.__super__.constructor.call(this, options, data);
  }

  GitDashboardMyReposPageView.prototype.viewAppended = function() {
    this.addSubView(this.container = new KDListView({
      cssClass: "container"
    }));
    return this.controller.getMyRepos(this.repoReceived, this.authToken);
  };

  GitDashboardMyReposPageView.prototype.repoReceived = function(repoView) {
    return this.container.addSubView(repoView);
  };

  return GitDashboardMyReposPageView;

})(KDView);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/views/mainview.coffee */
var GitDashboardMainView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GitDashboardMainView = (function(_super) {
  __extends(GitDashboardMainView, _super);

  function GitDashboardMainView(options, data) {
    if (options == null) {
      options = {};
    }
    this.initPersonal = __bind(this.initPersonal, this);
    this.oauthAuthentication = __bind(this.oauthAuthentication, this);
    options.cssClass = 'GitDashboard';
    GitDashboardMainView.__super__.constructor.call(this, options, data);
  }

  GitDashboardMainView.prototype.viewAppended = function() {
    var handle, _i, _len, _ref;
    this.addSubView(this.loginButton = new KDButtonView({
      cssClass: "login-button",
      title: "Connect with GitHub",
      callback: this.oauthAuthentication
    }));
    this.addSubView(this.tabView = new KDTabView({
      cssClass: "tab-view"
    }));
    this.tabView.getTabHandleContainer().setClass("handle-container");
    this.tabView.addPane(this.trendingPagePane = new KDTabPaneView({
      title: "Trending"
    }));
    this.trendingPagePane.setMainView(new GitDashboardTrendingPageView);
    _ref = this.tabView.handles;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      handle = _ref[_i];
      handle.setClass("handle");
    }
    if (OAuth.create("github") === !false) {
      return this.initPersonal();
    }
  };

  GitDashboardMainView.prototype.oauthAuthentication = function() {
    var callback, options;
    callback = this.initPersonal;
    return OAuth.popup("github", options = {
      cache: true
    }).done(function(result) {
      return callback();
    }).fail(function(err) {
      return console.log(err);
    });
  };

  GitDashboardMainView.prototype.initPersonal = function() {
    this.tabView.addPane(this.myReposPagePane = new KDTabPaneView({
      title: "My Repos"
    }));
    this.myReposPagePane.setMainView(new GitDashboardMyReposPageView({
      authToken: OAuth.create("github")
    }));
    return this.loginButton.hide();
  };

  return GitDashboardMainView;

})(KDView);
/* BLOCK STARTS: /home/glang/Applications/Gitdashboard.kdapp/index.coffee */
var GitDashboardController,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

GitDashboardController = (function(_super) {
  __extends(GitDashboardController, _super);

  function GitDashboardController(options, data) {
    if (options == null) {
      options = {};
    }
    options.view = new GitDashboardMainView;
    options.appInfo = {
      name: "Git Dashboard",
      type: "application"
    };
    GitDashboardController.__super__.constructor.call(this, options, data);
  }

  return GitDashboardController;

})(AppController);

(function() {
  var view;
  OAuth.initialize("D6R6uhEmh7kmXCVT9YzSwvHP-tk");
  if (typeof appView !== "undefined" && appView !== null) {
    view = new GitDashboardMainView;
    return appView.addSubView(view);
  } else {
    return KD.registerAppClass(GitDashboardController, {
      name: "Gitdashboard",
      routes: {
        "/:name?/Gitdashboard": null,
        "/:name?/alexchistyakov/Apps/Gitdashboard": null
      },
      dockPath: "/alexchistyakov/Apps/Gitdashboard",
      behavior: "application"
    });
  }
})();

/* KDAPP ENDS */
}).call();