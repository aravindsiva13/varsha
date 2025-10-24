const fs = require("fs");
const path = require("path");
exports.create = async (req, res) => {
  console.log("function called");
  console.log(req.body, "body=userlist");

  const { portal, clientName, clientId, replace } = req.body;

  try {
    let filePath = null;
    if (req.file) {
      filePath = "uploads/userlist/" + req.file.filename;
      console.log("File uploaded:", filePath);
    } else {
      console.log("No file uploaded");
    }

    let data = await req.db.UserList.create({
      portal,
      clientName,
      clientId,
      replace,
      uploadFile: filePath,
    });

    data = data.get({ plain: true });
    console.log("User created successfully:", data);
    
    res.status(200).send(data);
  } catch (err) {
    console.error("Error creating userlist:", err);
    res.status(500).json({ 
      error: "Internal server error",
      details: err.message 
    });
  }
};

exports.getList = async (req, res) => {
  console.log("getlist called");

  try {
    const page = parseInt(req.query.page) || parseInt(req.body.page) || 1;
    const limit = parseInt(req.query.limit) || parseInt(req.body.limit) || 5;
    const offset = (page - 1) * limit;

    console.log(`Fetching page ${page}, limit ${limit}, offset ${offset}`);
    const { count, rows } = await req.db.UserList.findAndCountAll({
      raw: true,
      limit,
      offset,
      order: [["id", "DESC"]],
    });

    const totalPages = Math.ceil(count / limit);
    console.log(`Found ${count} total records, returning ${rows.length} records`);

    res.status(200).json({
      data: rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: count,
      },
    });
  } catch (err) {
    console.error("Get list error:", err);
    res.status(500).json({ 
      error: "Internal server error",
      details: err.message 
    });
  }
};

exports.download = async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`Download requested for user ID: ${id}`);
    
    const userlist = await req.db.UserList.findByPk(id);
    
    if (!userlist) {
      console.log("User not found");
      return res.status(404).json({ error: "User not found." });
    }

    console.log("User found:", userlist.dataValues);

    if (!userlist.dataValues.uploadFile) {
      console.log("No file attached to this user");
      return res.status(404).json({ error: "File not found for this record." });
    }

    const filePath = path.join(userlist.dataValues.uploadFile);
    console.log("Trying to download file at path:", filePath);

    if (!fs.existsSync(filePath)) {
      console.log("File not found at:", filePath);
      return res.status(404).json({ error: "File not found on server." });
    }

    console.log("Sending file...");
    res.download(filePath, (err) => {
      if (err) {
        console.error("Download failed:", err);
        return res.status(500).json({ error: "Error while sending the file." });
      }
      console.log("File sent successfully");
    });

  } catch (err) {
    console.error("Download error:", err);
    res.status(500).json({ 
      error: "Internal server error", 
      details: err.message 
    });
  }
};