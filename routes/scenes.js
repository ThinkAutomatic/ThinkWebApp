var express = require('express');
var router = express.Router();
var thinkApi = require('./think-api');

router.post('/remove', function(req, res, next) {
  thinkApi.delete(req, 'scenes', req.body.sceneId, function(err)
  {
    res.setHeader('Content-Type', 'text/plain');
    res.send('success');
  });
});


module.exports = router;

