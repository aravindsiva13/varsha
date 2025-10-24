const router = require("express").Router();
const controller = require("../controllers/onboarding_mid.controllers");
 router.post("/create",controller.create);
 router.post("/list",controller.getList);
 
module.exports=router;