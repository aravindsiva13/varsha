const router = require("express").Router();
const controller = require("../controllers/download_template.controller");

 router.get("/download",controller.download);
 
module.exports=router;

