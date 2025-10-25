module.exports = (sequelize, dataTypes) => {
  const CreditsAdding = sequelize.define(
    "CreditsAdding",
    {
      id: {
        field: "id",
        type: dataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
       clientName: {
        field: "clientName",
        type: dataTypes.STRING,
        allowNull: false,
      },
        clientId: {
        field: "clientId",
        type: dataTypes.INTEGER,
        allowNull: false,
      },
       portal: {
        field:"portal",
         type: dataTypes.ENUM(
          "iCloud",
          "eCloud",
        ),
      },
       creditsResetInterval: {
        field:"creditsresetinterval",
         type: dataTypes.ENUM(
          "Monthly",
          "Daily",
          "Quarterly",
          "Yearly",
        ),
      },
       addInitialBalance: {
         field:"addinitialbalance",
         type: dataTypes.ENUM(
          "Yes",
          "No",
        ),
      },
        BalanceNow: {
         field:"balancenow",
         type: dataTypes.BIGINT(10),
         allowNull: true,
      },
      creditsType: {
          field: "creditstype",
          type: dataTypes.STRING,
          allowNull: false,
      }, 
      credits: {
        field: "credits",
        type: dataTypes.STRING,
        allowNull: false,
      }, 
      uploadFile:{
        field: "uploadFile",
        type: dataTypes.STRING,
        allowNull: true,
      
      }
    }
  );
  return CreditsAdding;
};