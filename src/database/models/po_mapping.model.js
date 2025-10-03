module.exports = (sequelize, dataTypes) => {
  const PoMapping = sequelize.define(
    "po_mapping",
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
       clientPhoneNumber: {
        field: "clientPhoneNumber",
        type: dataTypes.BIGINT(10),
        allowNull: false,
      },
       clientMailId: {
        field: "clientMailId",
        type: dataTypes.STRING,
        allowNull: false,
      },
       clientAddress: {
        field: "clientAddress",
        type: dataTypes.STRING,
        allowNull: false,
      },
       branch: {
        field: "branch",
        type: dataTypes.STRING,
        allowNull: false,
      },
       machineId: {
        field: "machineId",
        type: dataTypes.INTEGER,
        allowNull: false,
      },
      expiryPoDate:{
        field: "expiryPoDate",
        type: dataTypes.DATE,
        allowNull: false,
      },
      uploadFile:{
        field: "uploadFile",
        type: dataTypes.STRING,
        allowNull: true,
      
      }

    }
  );
  return PoMapping;
};