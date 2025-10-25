
module.exports = (sequelize, dataTypes) => {
  const UserList = sequelize.define(
    "user_list",
    {
      id: {
        field: "id",
        type: dataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
       portal: {
        field:"portal",
         type: dataTypes.ENUM(
          "iCloud",
          "eCloud",
        ),
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
        replace: {
          field:"replace",
           type: dataTypes.ENUM(
            "Yes",
            "No",
           ),
        },
        uploadFile:{
        field: "uploadFile",
        type: dataTypes.STRING,
        allowNull: true,
      }
    }
  );
  return UserList;
};