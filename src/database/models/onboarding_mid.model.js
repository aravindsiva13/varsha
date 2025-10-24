module.exports = (sequelize, dataTypes) => {
  const OnboardingMid = sequelize.define(
    "onboarding_mid",
    {
      id: {
        field: "id",
        type: dataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false,
      },
      
      displayName: {
        field: "displayName",
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
       MID: {
        field: "MID",
        type: dataTypes.INTEGER,
        allowNull: false,
       },
    }
  );
  return OnboardingMid;
};