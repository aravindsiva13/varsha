const router = require("express").Router();
const controller = require("../controllers/po_mapping.controllers");
const multer = require("multer");
const path = require("path");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/pomapping");
  },
  filename: (req, file, cb) => {
    const uniqueName =
      Date.now() +
      "-" +
      Math.round(Math.random() * 1e9) +
      path.extname(file.originalname);
    cb(null, uniqueName);
  },
});

const upload = multer({ storage: storage });

router.post("/create", upload.single("file"), controller.create);
router.post("/list", controller.getList);
router.post("/update", upload.single("file"), controller.update);
router.delete("/delete/:id", controller.delete);
router.get("/download/:id", controller.download);

module.exports = router;