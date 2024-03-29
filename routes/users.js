var express = require("express");
var router = express.Router();
var thinkApi = require("./think-api");

router.get("/signup", function (req, res, next) {
  res.render("signup", { cookies: req.cookies });
});

router.post("/signup", function (req, res, next) {
  res.cookie("userName", req.body.userName, thinkApi.cookieParams);
  res.cookie("emailAddress", req.body.emailAddress, thinkApi.cookieParams);

  thinkApi.signup(req, req.body, function (err, userInfo) {
    res.send(userInfo);
  });
});

router.get("/registered", function (req, res, next) {
  res.render("message", {
    cookies: req.cookies,
    title: "New User Registered",
    message:
      "Please click on link sent to " +
      req.cookies.emailAddress +
      " to continue.",
    redirect: "/",
  });
});

router.get("/signin", function (req, res, next) {
  res.render("signin", {
    cookies: req.cookies,
    query: req.query,
    title: "Think Automatic Sign-in",
  });
});

router.post("/signin", function (req, res, next) {
  thinkApi.signin(req, req.body, function (err, accessToken) {
    if (accessToken.accessToken) {
      res.cookie("accessToken", accessToken.accessToken, thinkApi.cookieParams);
      res.cookie("userId", accessToken.userId, thinkApi.cookieParams);
      res.cookie("userName", accessToken.userName, thinkApi.cookieParams);
    }
    res.send(accessToken);
  });
});

router.post("/o2/auth", function (req, res, next) {
  thinkApi.o2auth(req, req.body, function (err, authResponse) {
    res.send(authResponse);
  });
});

/* GET signout page. */
router.get("/signout", function (req, res, next) {
  thinkApi.signout(req, function (err) {
    res.clearCookie("accessToken", thinkApi.cookieParams);
    res.clearCookie("userId", thinkApi.cookieParams);
    res.clearCookie("userName", thinkApi.cookieParams);
    res.redirect("/");
  });
});

var handleConfirm = function (req, res, signIn) {
  const params = { verificationToken: req.query.verificationToken };
  thinkApi.post(req, "/users/confirm", params, function (err, response) {
    if (response && response.error) {
      res.render("message", {
        cookies: req.cookies,
        title: response.error.message,
        message: response.error.description,
        redirect: "/users/signin",
      });
    } else {
      res.cookie("accessToken", response.accessToken, thinkApi.cookieParams);
      res.cookie("userId", response.userId, thinkApi.cookieParams);
      res.cookie("userName", response.userName, thinkApi.cookieParams);
      res.render("message", {
        title: "Email confirmed",
        message:
          (signIn ? "" : "Thank you for confirming your email. ") +
          "You are now signed in.",
        redirect: "/",
      });
    }
  });
};

router.get("/confirm", function (req, res, next) {
  handleConfirm(req, res, false);
});

router.get("/confirm/signin", function (req, res, next) {
  handleConfirm(req, res, true);
});

router.post("/settings", function (req, res, next) {
  if (req.cookies && req.cookies.userId) {
    thinkApi.postById(
      req,
      "users",
      req.cookies.userId,
      req.body,
      function (err, response) {
        if (response && response.error) {
          res.send(response);
        } else {
          thinkApi.get(req, "users/whoAmI", function (err, userInfo) {
            if (userInfo.userId)
              res.cookie("userId", userInfo.userId, thinkApi.cookieParams);
            if (userInfo.userName)
              res.cookie("userName", userInfo.userName, thinkApi.cookieParams);
            if (userInfo.emailAddress)
              res.cookie(
                "emailAddress",
                userInfo.emailAddress,
                thinkApi.cookieParams
              );
            res.send(userInfo);
          });
        }
      }
    );
  }
});

router.get("/settings", function (req, res, next) {
  if (req.query && req.query.accessToken) {
    res.cookie("accessToken", req.query.accessToken, thinkApi.cookieParams);
    res.cookie("userId", req.query.userId, thinkApi.cookieParams);
    res.cookie("userName", req.query.username, thinkApi.cookieParams);
    res.redirect("/users/settings");
  } else {
    thinkApi.get(req, "users/whoAmI", function (err, userInfo) {
      if (userInfo && userInfo.error) err = userInfo;

      if (err) {
        res.render("message", {
          cookies: req.cookies,
          title: "Error",
          message: err.error.message,
          redirect: "/users/settings",
        });
      } else {
        if (userInfo) userInfo.userId = userInfo.id;

        res.render("settings", {
          cookies: req.cookies,
          title: userInfo.userName + " Account Settings",
          user: userInfo,
        });
      }
    });
  }
});

module.exports = router;
