const { raw } = require("mysql2");

exports.create = async (req, res) => {
console.log("function called");
 console.log(req.body,"body=pomapp");
 let validateDate
  const {clientName,portal,clientPhoneNumber,clientMailId,clientAddress,branch,machineId,expiryPoDate } = req.body;
    if (expiryPoDate) {
      const [day, month, year] = expiryPoDate.split('/'); 
      validateDate = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
    }
  try {
    console.log(req.file,"files");
    let filePath
    if(req.file){
      filePath = "uploads/pomapping/" + req.file.filename;

    }
    
    let data = await req.db.POMapping.create(
      {
       clientName,clientPhoneNumber,portal,clientMailId,clientAddress,branch,machineId,
expiryPoDate:validateDate,
uploadFile:filePath
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
  console.log("getList is called");
  try {
    // Get page and limit from query parameters, with defaults
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Fetch only the requested page
    let data = await req.db.POMapping.findAll({
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