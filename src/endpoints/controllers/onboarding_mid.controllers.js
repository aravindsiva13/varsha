const { raw } = require("mysql2");

exports.create = async (req, res) => {
console.log("function called");
  const {displayName,clientPhoneNumber,clientMailId,MID} = req.body;

 console.log(req.body,"body=onboardingmid");

  try {
    let data = await req.db.OnboardingMid.create(
      {
       displayName,clientPhoneNumber,clientMailId,MID,
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
  console.log("getlist");
  
  try {
   
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 5;
    const offset = (page - 1) * limit;

    let data = await req.db.OnboardingMid.findAll({
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