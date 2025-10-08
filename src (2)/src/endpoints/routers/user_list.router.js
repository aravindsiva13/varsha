const router = require("express").Router();
const controller = require("../controllers/user_list.controllers");
const multer = require("multer");
const path = require("path");

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/userlist"); // folder to store files
  },
  filename: (req, file, cb) => {
    const uniqueName =
      Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname);
    cb(null, uniqueName);
  }
});

const upload = multer({ storage: storage });
 router.post("/create",upload.single("file"),controller.create);
 router.post("/list",controller.getList);
 router.post("/download/:id",controller.download);
module.exports=router;

