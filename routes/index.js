var express = require("express");
var router = express.Router();
var thinkApi = require("./think-api");

/* GET home page. */
router.get("/", function (req, res) {
  if (!req.cookies.acceptCookies) {
    console.log("cookies not accepted");
    res.cookie("acceptCookies", "true", thinkApi.cookieParams);
    res.render("message", {
      cookies: req.cookies,
      title: "Cookies",
      buttonLabel: "OK",
      message:
        "By continuing to use this site you agree to the use of cookies, which are necessary for proper function. Thank you!",
      redirect: "/",
    });
  } else if (req.query && req.query.theme) {
    res.cookie("theme", req.query.theme, thinkApi.cookieParams);
    res.redirect("/");
  } else if (req.query && req.query.homeId) {
    console.log("test: homeId");
    res.cookie("homeId", req.query.homeId, thinkApi.cookieParams);
    if (req.query.roomId)
      res.cookie("roomId", req.query.roomId, thinkApi.cookieParams);
    res.redirect("/");
  } else if (req.query && req.query.edit) {
    if (req.query.edit == "true") {
      res.cookie("edit", "true", { path: "/", maxAge: 10 * 60 * 1000 });
    } else {
      res.clearCookie("edit", thinkApi.cookieParams);
    }

    res.redirect("/");
  } else {
    thinkApi.get(req, "homes", function (err, homesInfo) {
      if (homesInfo.error && homesInfo.error.code == 1600) {
        thinkApi.get(req, "users/terms/token", function (err, termsTokenInfo) {
          res.header(
            "Cache-Control",
            "no-cache, private, no-store, must-revalidate, max-stale=0, post-check=0, pre-check=0"
          );
          res.redirect(
            "http://api.thinkautomatic.io/users/terms?redirect=http://app.thinkautomatic.io&verificationToken=" +
              termsTokenInfo.verificationToken
          );
        });
        //      } else if (req.cookies.homeId && req.cookies.userId) {
      } else if (req.cookies.homeId) {
        thinkApi.getByIdVerbose(req, "homes", req.cookies.homeId, function (
          err,
          homeInfo
        ) {
          if (
            !homeInfo ||
            (homeInfo && homeInfo.error && homeInfo.error.code == 1001)
          ) {
            homeInfo = {};
          }

          res.render("index", {
            title: "Think Home",
            cookies: req.cookies,
            homes: homesInfo,
            home: homeInfo,
          });
        });
      } else if (
        homesInfo.length > 0 &&
        homesInfo[0].homeId &&
        (!req.cookies.homeId || req.cookies.homeId != homesInfo[0].homeId)
      ) {
        console.log("test: homesInfo.length");
        res.cookie("homeId", homesInfo[0].homeId, thinkApi.cookieParams);
        res.redirect("/");
      } else {
        res.render("index", {
          title: "Think Home",
          cookies: req.cookies,
          homes: homesInfo,
          home: {},
        });
      }
    });
  }
});

module.exports = router;
