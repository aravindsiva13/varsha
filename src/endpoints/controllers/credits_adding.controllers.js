const fs = require("fs");
const path = require("path");

exports.create = async (req, res) => {
  console.log("Function called");
  console.log(req.body, "body=creditsadding");

  if (req.file) {
    console.log("Uploaded file:", req.file);
  } else {
    console.log("No file uploaded");
  }

  const {
    clientName,
    clientId,
    portal,
    creditsResetInterval,
    addInitialBalance,
    creditsType,
    credits,
    initialBalance
  } = req.body;

  try {
    let filePath = null;
    if (req.file) {
      filePath = "uploads/creditsadding/" + req.file.filename;
    }

    let data = await req.db.CreditsAdding.create({
      clientName,
      clientId: parseInt(clientId),
      portal,
      creditsResetInterval,
      addInitialBalance,
      creditsType,
      credits: parseInt(credits),
      uploadFile: filePath,
      BalanceNow: initialBalance ? parseInt(initialBalance) : 0
    });

    data = data.get({ plain: true });
    res.status(200).json(data);
  } catch (err) {
    console.error("Create error:", err);
    res.status(500).json({ 
      error: "Failed to create Credits Adding entry", 
      details: err.message 
    });
  }
};

exports.getList = async (req, res) => {
  try {
    const page = parseInt(req.query.page || req.body.page) || 1;
    const limit = parseInt(req.query.limit || req.body.limit) || 5;
    const offset = (page - 1) * limit;

    const { count, rows } = await req.db.CreditsAdding.findAndCountAll({
      raw: true,
      limit: limit,
      offset: offset,
      order: [['id', 'ASC']],
    });
    
    const totalPages = Math.ceil(count / limit);

    res.json({
      data: rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: count
      }
    });
  } catch (err) {
    console.log(err);
    res.status(500).json({ error: "Internal server error" });
  }
};

exports.download = async (req, res) => {
  try {
    const { id } = req.params;
    const credits = await req.db.CreditsAdding.findByPk(id);
    
    if (!credits.dataValues.uploadFile) {
      return res.status(404).json({ error: "File not found" });
    }

    const filePath = path.join(credits.dataValues.uploadFile);
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: "File not found on server" });
    }

    res.download(filePath, (err) => {
      if (err) {
        console.error("Download failed:", err);
        return res.status(500).json({ error: "Error downloading file" });
      }
    });
  } catch (err) {
    console.error("Download error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};