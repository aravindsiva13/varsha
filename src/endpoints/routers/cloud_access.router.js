const router = require("express").Router();
const controller = require("../controllers/cloud_access.controllers");

router.post("/create", controller.create);
router.post("/list", controller.getList);
router.post("/update", controller.update);
router.delete("/delete/:id", controller.delete);

module.exports = router;