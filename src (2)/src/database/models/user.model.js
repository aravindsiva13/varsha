module.exports = (sequelize, dataTypes) => {
  const User = sequelize.define(
    "users",
    {
      id: {
        field: "id",
        type: dataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      email: {
        field: "email",
        type: dataTypes.STRING,
        allowNull: false,
        unique: true,
      },
      password: {
        field: "password",
        type: dataTypes.STRING,
        allowNull: false,
      },
      name: {
        field: "name",
        type: dataTypes.STRING,
        allowNull: true,
      },
      isActive: {
        field: "is_active",
        type: dataTypes.BOOLEAN,
        defaultValue: true,
      },
    },
    {
      timestamps: true,
      underscored: true,
    }
  );
  return User;
};