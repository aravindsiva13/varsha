/**
 * Imports
 */
 
const Sequelize = require("sequelize");
const { master } = require("./dbConfig");
// const onboarding_midModel = require("./models/onboarding_mid.model");

 
// Connection Initialization
 
const sequelize = new Sequelize(
  master.main_db_name,
  master.username,
  master.password,
  master.main_db_options
);
 
// DB Object
 
const db = {
  seqlib: Sequelize,
  seq: sequelize,
  
User: require("./models/user.model")(sequelize, Sequelize),
POMapping:require("./models/po_mapping.model")(sequelize,Sequelize),
CloudAccess:require("./models/cloud_access.model")(sequelize,Sequelize),
UserList:require("./models/user_list.model")(sequelize,Sequelize),
OnboardingMid:require("./models/onboarding_mid.model")(sequelize,Sequelize),
CreditsAdding:require("./models/credits_adding.model")(sequelize,Sequelize),
MachineAccess:require("./models/machine_access.model")(sequelize,Sequelize),
}
module.exports=db