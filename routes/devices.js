var express = require("express");
var router = express.Router();
var thinkApi = require("./think-api");

/* GET discover device page */
router.get("/discover", function (req, res, next) {
  thinkApi.get(req, "devices/discover", function (err, devicesInfo) {
    console.log(JSON.stringify(devicesInfo));

    if (req.cookies.homeId) {
      thinkApi.getByIdVerbose(req, "homes", req.cookies.homeId, function (
        err,
        homeInfo
      ) {
        if (!homeInfo) homeInfo = {};

        res.render("discover", {
          cookies: req.cookies,
          title: "Discover hubs/devices",
          devicesInfo: devicesInfo,
          home: homeInfo,
        });
      });
    } else {
      res.render("discover", {
        cookies: req.cookies,
        title: "Discover hubs/devices",
        devicesInfo: devicesInfo,
        home: {},
      });
    }
  });
});

/* GET add device page */
router.get("/link", function (req, res, next) {
  var path;

  if (req.query.roomId) {
    path = "rooms/" + req.query.roomId.toString();
  } else {
    path = "homes/" + req.cookies.homeId.toString();
  }

  if (req.query.directUrl) {
    path += "/linkToken";

    console.log(path);

    thinkApi.post(req, path, {}, function (err, linkTokenInfo) {
      console.log(JSON.stringify(linkTokenInfo));
      res.redirect(
        thinkApi.trimTrailingChars(req.query.directUrl, "/") +
          "/link?linkToken=" +
          linkTokenInfo.linkToken +
          "&successRedirect=https://app.thinkautomatic.io/"
      );
    });
  } else {
    path += "/link";

    thinkApi.post(req, path, {}, function (err, response) {
      console.log(JSON.stringify(response));
      res.redirect("https://app.thinkautomatic.io");
    });
  }
});

/* GET add device page */
/*
router.get('/', function(req, res, next) {
  thinkApi.get(req, 'devices/' + req.query.deviceId.toString(), function(err, deviceInfo)
  {
    console.log(JSON.stringify(deviceInfo));
    thinkApi.get(req, 'devices/' + req.query.deviceId.toString() + '/deviceType', function(err, deviceTypeInfo)
    {
      console.log(JSON.stringify(deviceTypeInfo));
      res.render('device', { cookies: req.cookies, title: 'Device', deviceInfo: deviceInfo, deviceTypeInfo: deviceTypeInfo });
    });
  });
});
*/

/*
router.post('/remove', function(req, res) {
  console.log('/devices/remove');
  thinkApi.delete(req, 'devices', req.body.deviceId, function(err)
  {
    res.setHeader('Content-Type', 'text/plain');
    res.send('success');
  });
});
*/

module.exports = router;
