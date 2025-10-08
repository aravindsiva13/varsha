// const {raw} = require("mysql2");
// const path =require("path");

// exports.create = async (req, res) => {
// console.log("function called");
//  console.log(req.body,"body=userlist");
//   const {portal,
//     clientName,
//     clientId,
//     replace
//   } = req.body;
      
//   try {
//       console.log(req.file,"files");
      
//  let filePath
//     if(req.file){
//       filePath = "uploads/userlist/" + req.file.filename;

//     }

//     let data = await req.db.UserList.create(
//       {
//       portal,
//       clientName,
//       clientId,
//       replace,
//       uploadFile:filePath
//       },  
//     );
 
//     data = data.get({ plain: true });
//    res.send(data)
//    } catch (err) {
//     console.log(err)
//     res.send(err)
//     // console.log(err);
 
//     // let errorType = await req.db.errorValidator(err);
 
//     // await t.rollback();
 
//     // req.db.failure(
//     //   res,
//     //   errorType?.displayMsg ? errorType.displayMsg : errorType.msg,
//     //   500,
//     //   err
//     // );
//   }
// };
 
// exports.getList = async (req, res) => {
//   console.log("getlist");
  
//   try {
//     // Get page and limit from query parameters, with defaults
//     const page = parseInt(req.query.page) || 1;
//     const limit = parseInt(req.query.limit) || 5;
//     const offset = (page - 1) * limit;

//     // Fetch only the requested page
//    const { count, rows } = await req.db.POMapping.findAndCountAll({
//       raw: true,
//       limit: limit,
//       offset: offset,
//       order: [["id", "ASC"]],
//     });

//     const totalPages = Math.ceil(count / limit);

//     res.send({
//       data: rows,
//       pagination: {
//         currentPage: page,
//         totalPages: totalPages,
//         totalItems: count
//       }
//     });
//   } catch (err) {
//     console.error("Get list error:", err);
//     res.status(500).send({ error: "Internal server error" });
//   }
//   }
//       exports.download = async (req, res) => {
//       try {
//         const { id } = req.params;
//         const userlist= await req.db.UserList.findByPk(id);
//         console.log(userlist.dataValues.uploadFile,"userlist");
//         if (!userlist.dataValues.uploadFile) {
//           return res.status(404).json({ error: "File not found for this record." });
//         }
    
//         // 🔧 Correct file path (include backend folder level)
//         const filePath = path.join(userlist.dataValues.uploadFile);
    
//         console.log("🧩 Trying to download file at path:", filePath);
    
//         // Check if file exists
//         if (!fs.existsSync(filePath)) {
//           console.log("❌ File not found at:", filePath);
//           return res.status(404).json({ error: "File not found on server." });
//         }
    
//         // ✅ Attempt to send the file
//         res.download(filePath, (err) => {
//           if (err) {
//             console.error("Download failed:", err);
//             return res.status(500).json({ error: "Error while sending the file." });
//           }
//         });
    
//       } catch (err) {
//         console.error("Download error:", err);
//         res.status(500).json({ error: "Internal server error.", details: err.message });
//       }
//     };
    
  const fs = require("fs");
const path = require("path");

// ---------------------- CREATE ----------------------
exports.create = async (req, res) => {
  console.log("function called");
  console.log(req.body, "body=userlist");

  const { portal, clientName, clientId, replace } = req.body;

  try {
    let filePath;
    if (req.file) {
      filePath = "uploads/userlist/" + req.file.filename;
    }

    let data = await req.db.UserList.create({
      portal,
      clientName,
      clientId,
      replace,
      uploadFile: filePath,
    });

    data = data.get({ plain: true });
    res.send(data);
  } catch (err) {
    console.log("Error creating userlist:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

// ---------------------- GET LIST (with pagination) ----------------------
exports.getList = async (req, res) => {
  console.log("getlist");

  try {
    // Use body (Flutter sends POST with body, not query)
    const page = parseInt(req.body.page) || 1;
    const limit = parseInt(req.body.limit) || 5;
    const offset = (page - 1) * limit;

    // Fetch from correct table -> UserList ✅
    const { count, rows } = await req.db.UserList.findAndCountAll({
      raw: true,
      limit,
      offset,
      order: [["id", "ASC"]],
    });

    const totalPages = Math.ceil(count / limit);

    res.send(200).json({
      data: rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: count,
      },
    });
  } catch (err) {
    console.error("Get list error:", err);
    res.status(500).send({ error: "Internal server error" });
  }
};

// ---------------------- DOWNLOAD ----------------------
exports.download = async (req, res) => {
  try {
    const { id } = req.params;
    const userlist = await req.db.UserList.findByPk(id);
    console.log(userlist.dataValues.uploadFile,"userlist");

    if (!userlist.dataValues.uploadFile) {
      return res.status(404).json({ error: "File not found for this record." });
    }

    const filePath = path.join(userlist.dataValues.uploadFile);
    console.log("🧩 Trying to download file at path:", filePath);

    if (!fs.existsSync(filePath)) {
      console.log("❌ File not found at:", filePath);
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
    res.status(500).json({ error: "Internal server error", details: err.message });
  }
};
