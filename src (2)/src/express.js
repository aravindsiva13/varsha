const express = require('express');
const cors = require('cors');
const db = require("./database/db");

const app = express();
const port = 3008;


// app.use(cors());
app.use(cors({ origin: "*" }));

app.use(express.json());

app.use((req, res, next) => {
  req.db = db;
  next();
});

// routers
app.use('/auth', require("./endpoints/routers/auth.router"));
app.use('/poMapping', require("./endpoints/routers/po_mapping.router"));
app.use('/cloudAccess', require("./endpoints/routers/cloud_access.router"));
app.use('/UserList', require("./endpoints/routers/user_list.router"));
app.use('/OnboardingMid',require("./endpoints/routers/onboarding_mid.router"));
app.use('/CreditsAdding',require("./endpoints/routers/credits_adding.router"));
app.use('/MachineAccess',require("./endpoints/routers/machine_access.router"));

db.seq.sync().then(async () => {
  let isUserExist=await checkForUser(db)
  if(!isUserExist){
    await initialUser(db)
  }
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${port}`);
  });
});
let usersList=[
  {
    name:'Senthil',
    email:'senthilkumar@riota.in',
    password:'riota@123',
isActive:true
  },
   {
    name:'Bhavya Shree',
    email:'bhavyashree@riota.in',
    password:'riota@123',
isActive:true
  }
]

async function initialUser(db){
 try {
    let user = await db.User.bulkCreate(usersList);
    console.log(user,"user");
    
   return true
  } catch (e) {
    console.log(e);
    return false;
  }
}

async function checkForUser(db) {
  try {
    let user = await db.User.findAll({
      raw: true,
    });
    console.log(user,"checkUser");
    
    return user != null && user.length != 0;
  } catch (e) {
    console.log(e);
    return false;
  }
}