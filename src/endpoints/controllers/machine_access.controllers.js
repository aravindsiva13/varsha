const { raw } = require("mysql2");

exports.create = async (req, res) => {
console.log("function called");
 console.log(req.body,"body=machineaccess");
  const {clientName,machineId,portal,userRole} = req.body;
      
  try {
    let data = await req.db.MachineAccess.create(
      {
      clientName,machineId,portal,userRole
    }, 
    );
 
    data = data.get({ plain: true });
   res.send(data)

  } catch (err) {
    console.log(err)
    res.send(err)
 
  }
};

exports.getList = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    let data = await req.db.MachineAccess.findAll({
      raw: true,
      limit: limit,
      offset: offset,
      order: [['id', 'ASC']], 
    });

    res.send(data);

  } catch (err) {
    console.log(err);
    res.status(500).send({ error: "Internal server error" });
  }
};