var express = require("express");
var router = express.Router();
var thinkApi = require("./think-api");

router.get("/", function (req, res, next) {
  if (req.query.homeKey && req.query.homeId) {
    thinkApi.signout(req, function (err) {
      console.log("signout");
      console.log(err);
      res.cookie("accessToken", req.query.homeKey, thinkApi.cookieParams);
      res.cookie("homeId", req.query.homeId, thinkApi.cookieParams);
      res.clearCookie("userId", thinkApi.cookieParams);
      res.clearCookie("userName", thinkApi.cookieParams);
      res.redirect("/");
    });
  } else {
    res.redirect("/");
  }
});

router.get("/keys", function (req, res, next) {
  thinkApi.getHomeKeys(req, req.cookies.homeId, function (err, homeKeysInfo) {
    if (!homeKeysInfo) homeKeysInfo = [];

    res.render("keys", {
      title: homeKeysInfo[0] ? homeKeysInfo[0].homeName + " Home" : "Home Keys",
      cookies: req.cookies,
      homeKeys: homeKeysInfo,
    });
  });
});

/*
router.post('/remove', function(req, res) {
  console.log('/homes/remove');
  thinkApi.delete(req, 'homes', req.body.homeId, function(err)
  {
    res.setHeader('Content-Type', 'text/plain');
    res.clearCookie('homeId');
    res.send('success');
  });
});
*/

module.exports = router;
