const { raw } = require("mysql2");

exports.create = async (req, res) => {
console.log("function called");
 console.log(req.body,"body=creditsadding");
  const {clientName,clientId,portal,creditsResetInterval,addInitialBalance,creditsType,credits} = req.body;
      
  try {
     console.log(req.file,"files");
     let filePath
     if(req.file){
      filePath = "uploads/creditsadding/" + req.file.filename;
    }

//    const filePath = "uploads/creditsadding/" + req.file.filename;

    let data = await req.db.CreditsAdding.create(
      {
      clientName,clientId,portal,creditsResetInterval,addInitialBalance,creditsType,credits,
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
  try {
    // Get page and limit from query parameters, with defaults
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    // Fetch only the requested page
     const { count, rows } = await req.db.CreditsAdding.findAndCountAll({
      raw: true,
      limit: limit,
      offset: offset,
      order: [['id', 'ASC']],
    });
    const totalPages = Math.ceil(count / limit);


      // Send proper response format
    res.send({
      data: rows,
      pagination: {
        currentPage: page,
        totalPages: totalPages,
        totalItems: count
      }
    });

  } catch (err) {
    console.log(err);
    res.status(500).send({ error: "Internal server error" });
  }
};