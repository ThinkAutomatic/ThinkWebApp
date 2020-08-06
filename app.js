var express = require("express");
var path = require("path");
var favicon = require("serve-favicon");
var logger = require("morgan");
var cookieParser = require("cookie-parser");
var bodyParser = require("body-parser");
//var http = require("http");

var api = require("./routes/think-api");

var index = require("./routes/index");
var users = require("./routes/users");
var homes = require("./routes/homes");
var rooms = require("./routes/rooms");
//var objects = require("./routes/objects");
var scenes = require("./routes/scenes");
var devices = require("./routes/devices");
var devicetypes = require("./routes/deviceTypes");

var app_http = express();
var app = express();
app.locals.pretty = true;

// view engine setup
app.set("views", path.join(__dirname, "views"));
app.set("view engine", "jade");

//app_http.set('views', path.join(__dirname, 'views'));
//app_http.set('view engine', 'jade');

// uncomment after placing your favicon in /public
//app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger("dev"));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

/*
//app_http.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app_http.use(logger('dev'));
app_http.use(bodyParser.json());
app_http.use(bodyParser.urlencoded({ extended: false }));
app_http.use(cookieParser());
app_http.use(express.static(path.join(__dirname, 'public')));
*/

app.use("/", index);
app.use("/api", api.router);
app.use("/users", users);
app.use("/homes", homes);
app.use("/rooms", rooms);
//app.use("/objects", objects);
app.use("/scenes", scenes);
app.use("/devices", devices);
app.use("/deviceTypes", devicetypes);

app.get("/health", function (req, res) {
  console.log("health check");
  res.send("ok");
});

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  var err = new Error("Not Found");
  err.status = 404;
  next(err);
});

// error handlers

// development error handler
// will print stacktrace
if (app.get("env") === "development") {
  app.use(function (err, req, res, next) {
    res.status(err.status || 500);
    res.render("error", {
      message: err.message,
      error: err,
    });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function (err, req, res, next) {
  res.status(err.status || 500);
  res.render("error", {
    message: err.message,
    error: {},
  });
});

module.exports = app;

//app_http.get('/*', function(req,res) {
//  res.redirect('https://app.thinkautomatic.io/');
//});

// Configure our HTTP server
//var http_server = http.createServer(app_http).listen(9080);
//var http_server = http.createServer(app).listen(9080);
