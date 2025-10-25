const router = require("express").Router();
const controller = require("../controllers/onboarding_mid.controllers");

router.post("/create", controller.create);
router.post("/list", controller.getList);
router.post("/update", controller.update);
router.delete("/delete/:id", controller.delete);

module.exports = router;