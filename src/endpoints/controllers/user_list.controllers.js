const {raw} = require("mysql2");

exports.create = async (req, res) => {
console.log("function called");
 console.log(req.body,"body=userlist");
  const {portal,clientName,clientId,replace} = req.body;
      
  try {
      console.log(req.file,"files");
      
 let filePath
    if(req.file){
      filePath = "uploads/userlist/" + req.file.filename;

    }
      // const filePath = "uploads/userlist/" + req.file.filename;

    let data = await req.db.UserList.create(
      {
      portal,clientName,clientId,replace,uploadFile:filePath
},
     
    );
 
    data = data.get({ plain: true });
   res.send(data)
 
    // req.db.success(res, data, "Successfully Created", 200);
  } catch (err) {
    console.log(err)
    res.send(err)
    // console.log(err);
 
    // let errorType = await req.db.errorValidator(err);
 
    // await t.rollback();
 
    // req.db.failure(
    //   res,
    //   errorType?.displayMsg ? errorType.displayMsg : errorType.msg,
    //   500,
    //   err
    // );
  }
};
 
exports.getList = async (req, res) => {
  console.log("getlist");
  
  try {
    // Get page and limit from query parameters, with defaults
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Fetch only the requested page
    let data = await req.db.UserList.findAll({
      raw: true,
      limit: limit,
      offset: offset,
      order: [['id', 'ASC']], // optional: sort by id
    });

    res.send(data);
    console.log("Response:",res);

  } catch (err) {
    console.log(err);
    res.status(500).send({ error: "Internal server error" });
  }
};