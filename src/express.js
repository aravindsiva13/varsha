const express = require('express');
const cors = require('cors');
const db = require("./database/db");
require("dotenv").config(); 
const fs = require('fs');

const app = express();

if (!fs.existsSync("logs")) {
 fs.mkdirSync("logs", {recursive:true})
}

if (!fs.existsSync("uploads")) {
 fs.mkdirSync("uploads", {recursive:true})
}

if (!fs.existsSync("uploads/creditsadding")) {
 fs.mkdirSync("uploads/creditsadding", {recursive:true})
}

if (!fs.existsSync("uploads/pomapping")) {
 fs.mkdirSync("uploads/pomapping", {recursive:true})
}

if (!fs.existsSync("uploads/userlist")) {
 fs.mkdirSync("uploads/userlist", {recursive:true})
}

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
app.use('/downloadTemplate',require("./endpoints/routers/download_template.router"));


db.seq.sync().then(async () => {
  console.log(process.env.HTTP_PORT,'port');
  
  let isUserExist=await checkForUser(db)
  if(!isUserExist){
    await initialUser(db)
  }
  app.listen(process.env.HTTP_PORT || 3009, () => {
    console.log(`Server running at @ ${process.env.HTTP_PORT}`);
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