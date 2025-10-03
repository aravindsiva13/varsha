module.exports = (sequelize, dataTypes) => {
  const MachineAccess = sequelize.define(
    "MachineAccess",
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
      machineId: {
        field: "machineId",
        type: dataTypes.INTEGER,
        allowNull: false,
      },
       userRole: {
        field: "userRole",
        type: dataTypes.INTEGER,
        allowNull: false,
      },
    }
  );
  return MachineAccess;
};