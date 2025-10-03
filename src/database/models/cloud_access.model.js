module.exports = (sequelize, dataTypes) => {
  const CloudAccess = sequelize.define(
    "cloud_access",
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
        roleAction: {
        field:"roleAction",
         type: dataTypes.ENUM(
          "Create",
          "Update",
        ),
      },

      createRoleName: {
        field: "createRoleName",
        type: dataTypes.STRING,
        allowNull: false,
      },
       
       description: {
        field: "description",
        type: dataTypes.STRING(2000),
        allowNull: false,
      },
    }
  );
  return CloudAccess;
};