var request = require("request");
var express = require("express");
var router = express.Router();

var urlToThinkAutomatic = "https://api.thinkautomatic.io/";
//var urlToThinkAutomatic = "http://localhost:8443/";

const COOKIE_MAX_AGE = 30 * 24 * 60 * 60 * 1000;

var trimTrailingChars = function (s, charToTrim) {
  var regExp = new RegExp(charToTrim + "+$");
  var result = s.replace(regExp, "");

  return result;
};

var getIpAddress = function (req) {
  return (
    req.headers["x-real-ip"] ||
    req.headers["x-forwarded-for"] ||
    req.connection.remoteAddress ||
    req.socket.remoteAddress ||
    req.connection.socket.remoteAddress
  );
};

var apiGet = function (req, path, filter, cb) {
  if (!filter) {
    filter = {};
  }
  //  var params = {};

  request.get(
    {
      url: urlToThinkAutomatic + path,
      headers: {
        "x-real-ip": getIpAddress(req),
        access_token: req.cookies.accessToken,
        "content-type": "application/json",
      },
      qs: filter,
    },
    function (err, httpResponse, body) {
      try {
        if (typeof body === "string") body = JSON.parse(body);
      } catch (e) {}
      cb(err, body);
    }
  );
};

var apiPost = function (req, path, jsonParams, cb) {
  if (typeof jsonParams === "string") jsonParams = JSON.parse(jsonParams);
  request.post(
    {
      url: urlToThinkAutomatic + path,
      headers: {
        "x-real-ip": getIpAddress(req),
        access_token: req.cookies.accessToken,
        "content-type": "application/json",
      },
      json: jsonParams,
    },
    function (err, httpResponse, body) {
      console.log(body);
      cb(err, body);
    }
  );
};

var apiPatch = function (req, path, jsonParams, cb) {
  if (typeof jsonParams === "string") jsonParams = JSON.parse(jsonParams);
  request.patch(
    {
      url: urlToThinkAutomatic + path,
      headers: {
        "x-real-ip": getIpAddress(req),
        access_token: req.cookies.accessToken,
        "content-type": "application/json",
      },
      json: jsonParams,
    },
    function (err, httpResponse, body) {
      cb(err, body);
    }
  );
};

var apiDelete = function (req, path, cb) {
  console.log("apiDelete " + path);
  request.del(
    {
      url: urlToThinkAutomatic + path,
      headers: {
        "x-real-ip": getIpAddress(req),
        access_token: req.cookies.accessToken,
        "content-type": "application/json",
      },
    },
    function (err, httpResponse, body) {
      cb(err, body);
    }
  );
};

var trimPrefix = function (path) {
  return path.substring("/api/".length);
};

router.get("/*", function (req, res, next) {
  console.log('router.get("/*")');
  console.log(req.originalUrl);
  console.log(req.params);
  apiGet(req, trimPrefix(req.originalUrl), req.params, function (err, data) {
    console.log(err);
    console.log(data);
    res.send(data);
  });
});

router.post("/*", function (req, res, next) {
  console.log('router.post("/*")');
  console.log(req.body);
  apiPost(req, trimPrefix(req.originalUrl), req.body, function (err, data) {
    console.log("err: ");
    console.log(err);
    console.log("data: ");
    console.log(data);
    if (data && data.error && data.error.details) {
      console.log(data.error.details);
    }
    res.send(data);
  });
});

router.patch("/*", function (req, res, next) {
  console.log('router.patch("/*")');
  console.log(req.body);
  apiPatch(req, trimPrefix(req.originalUrl), req.body, function (err, data) {
    console.log(err);
    res.send(data);
  });
});

router.delete("/*", function (req, res, next) {
  console.log('router.delete("/*")');
  apiDelete(req, trimPrefix(req.originalUrl), function (err, data) {
    console.log(err);
    res.send(data);
  });
});

module.exports = {
  cookieParams: { path: "/", maxAge: COOKIE_MAX_AGE },
  router: router,
  trimTrailingChars: trimTrailingChars,

  get: function (req, path, cb) {
    apiGet(req, path, null, cb);
  },
  getWithFilter: function (req, path, filter, cb) {
    apiGet(req, path, filter, cb);
  },
  post: function (req, path, properties, cb) {
    apiPost(req, path, properties, cb);
  },
  patch: function (req, path, objectId, properties, cb) {
    apiPatch(req, path + "/" + objectId.toString(), properties, cb);
  },
  postById: function (req, path, objectId, properties, cb) {
    apiPost(req, path + "/" + objectId.toString(), properties, cb);
  },
  delete: function (req, path, cb) {
    apiDelete(req, path, cb);
  },
  getById: function (req, path, objectId, cb) {
    apiGet(req, path + "/" + objectId.toString(), null, cb);
  },
  getByIdVerbose: function (req, path, objectId, cb) {
    apiGet(req, path + "/" + objectId.toString() + "/verbose", null, cb);
  },
  getHomeKeys: function (req, homeId, cb) {
    console.log("homeId:");
    console.log(homeId.toString());
    apiGet(req, "homes/" + homeId.toString() + "/homeKeys", null, cb);
  },

  signup: function (req, credentials, cb) {
    console.log("test");
    apiPost(req, "users/signup", credentials, cb);
  },
  signin: function (req, credentials, cb) {
    apiPost(req, "users/signin", credentials, cb);
  },
  signout: function (req, cb) {
    apiPost(req, "users/signout", {}, cb);
  },

  //  associateDevice: function(req, deviceId, homeKey, cb) { apiPost(req, 'devices/' + deviceId.toString() + '/associate', homeKey, cb); }
};
