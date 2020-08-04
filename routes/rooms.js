var express = require('express');
var router = express.Router();
var thinkApi = require('./think-api');

router.post('/select', function(req, res, next) {
  console.log('/rooms/select');
  if (req.body.roomId)
  {
    res.cookie('roomId', req.body.roomId, thinkApi.cookieParams);
  }
  res.setHeader('Content-Type', 'text/plain');
  res.send('success');
});

module.exports = router;

