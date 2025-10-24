const fs = require("fs");
const path = require("path");
const { raw } = require("mysql2");

exports.create = async (req, res) => {
  console.log("function called");
  console.log(req.body, "body=pomapp");
  let validateDate;

  const {
    clientName,
    portal,
    clientPhoneNumber,
    clientMailId,
    clientAddress,
    branch,
    machineId,
    expiryPoDate
  } = req.body;

  if (expiryPoDate) {
    const [day, month, year] = expiryPoDate.split("/");
    validateDate = `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}`;
  }

  try {
    console.log(req.file, "files");
    let filePath;
    if (req.file) {
      filePath = "uploads/pomapping/" + req.file.filename;
    }

    let data = await req.db.POMapping.create({
      clientName,
      clientPhoneNumber,
      portal,
      clientMailId,
      clientAddress,
      branch,
      machineId,
      expiryPoDate: validateDate,
      uploadFile: filePath
    });

    data = data.get({ plain: true });
    res.send(data);
  } catch (err) {
    console.error("Create error:", err);
    res.status(500).json({ error: "Failed to create PO Mapping.", details: err.message });
  }
};

exports.getList = async (req, res) => {
  console.log("getList is called");
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    const { count, rows } = await req.db.POMapping.findAndCountAll({
      raw: true,
      limit: limit,
      offset: offset,
      order: [["id", "ASC"]],
    });

    const totalPages = Math.ceil(count / limit);

    res.send({
      data: rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: count
      }
    });

  } catch (err) {
    console.error("Get list error:", err);
    res.status(500).send({ error: "Internal server error" });
  }
};

exports.download = async (req, res) => {
  try {
    const { id } = req.params;
    const po = await req.db.POMapping.findByPk(id);
    console.log(po.dataValues.uploadFile,"po");
    if (!po.dataValues.uploadFile) {
      return res.status(404).json({ error: "File not found for this record." });
    }


    const filePath = path.join(po.dataValues.uploadFile);

    console.log("Trying to download file at path:", filePath);

    if (!fs.existsSync(filePath)) {
      console.log("File not found at:", filePath);
      return res.status(404).json({ error: "File not found on server." });
    }

    res.download(filePath, (err) => {
      if (err) {
        console.error("Download failed:", err);
        return res.status(500).json({ error: "Error while sending the file." });
      }
    });

  } catch (err) {
    console.error("Download error:", err);
    res.status(500).json({ error: "Internal server error.", details: err.message });
  }
};
