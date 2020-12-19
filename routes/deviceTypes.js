var express = require("express");
var router = express.Router();
var thinkApi = require("./think-api");

router.get("/", function (req, res, next) {
  var filter = "";
  var draftDeviceType = {};

  if (req.query && req.query.filter) {
    filter = req.query.filter;
  } else if (!(req.query && req.query.showAll)) {
    if (req.cookies && req.cookies.dtFilter) filter = req.cookies.dtFilter;
    //    else if (req.cookies && req.cookies.userName && !(req.query && req.query.showAll))
    //      filter = req.cookies.userName;
  }

  res.cookie("dtFilter", filter, thinkApi.cookieParams);

  thinkApi.getWithFilter(
    req,
    "deviceTypes/search",
    { filter: filter },
    function (err, deviceTypesInfo) {
      thinkApi.get(
        req,
        "deviceTypes/drafts",
        function (err, draftDeviceTypesInfo) {
          if (
            draftDeviceTypesInfo.error &&
            draftDeviceTypesInfo.error.code == 1600
          ) {
            res.redirect(
              "https://api.thinkautomatic.io/terms?access_token=" +
                req.cookies.accessToken +
                "&userId=" +
                req.cookies.userId.toString()
            );
          } else {
            res.render("devicetypes", {
              cookies: req.cookies,
              title: "Device Type Builder",
              deviceTypesInfo: deviceTypesInfo,
              draftDeviceTypesInfo: draftDeviceTypesInfo,
              filter: filter,
            });
          }
        }
      );
    }
  );
});

/*
router.post('/edit', function(req, res, next) {
  console.log('POST: /edit');
  if (req.body) {
    if (req.body.draft && req.body.draft == 'true') {
      if (req.body.deviceType) {
        res.cookie('draftDeviceType', req.body.deviceType, thinkApi.cookieParams);
      }
      else {
        res.clearCookie('draftDeviceType', thinkApi.cookieParams);
      }
    }

    if (req.body.deviceType) {
      console.log(req.body.deviceType.toString());
      res.cookie('deviceType', req.body.deviceType.toString(), thinkApi.cookieParams);
    }
  }

  res.end();
});
*/

router.get("/edit", function (req, res, next) {
  if (req.query.deviceTypeDraftId) {
    res.clearCookie("deviceTypeUuid", thinkApi.cookieParams);
    res.cookie(
      "deviceTypeDraftId",
      req.query.deviceTypeDraftId,
      thinkApi.cookieParams
    );
    res.redirect("/deviceTypes/edit");
  } else if (req.query.deviceTypeUuid) {
    res.cookie(
      "deviceTypeUuid",
      req.query.deviceTypeUuid,
      thinkApi.cookieParams
    );
    res.clearCookie("deviceTypeDraftId", thinkApi.cookieParams);
    res.redirect("/deviceTypes/edit");
  } else {
    var path;

    if (req.cookies.deviceTypeDraftId) {
      console.log(req.cookies);
      path =
        "deviceTypes/" + req.cookies.deviceTypeDraftId.toString() + "/draft";
    } else if (req.cookies.deviceTypeUuid) {
      path = "deviceTypes/" + req.cookies.deviceTypeUuid.toString();
    } else {
      res.redirect("/deviceTypes");
      return;
    }

    thinkApi.get(req, path, function (err, deviceTypeInfo) {
      res.render("editdevicetype", {
        cookies: req.cookies,
        title: "Device Type Editor",
        deviceTypeInfo: deviceTypeInfo,
      });
    });
  }
});

module.exports = router;
