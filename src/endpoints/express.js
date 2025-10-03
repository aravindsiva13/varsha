const express = require('express');
const cors = require('cors');
const db = require("../database/db");

const app = express();
const port = 3000;


// app.use(cors());
app.use(cors({ origin: "*" }));

app.use(express.json());

app.use((req, res, next) => {
  req.db = db;
  next();
});

// routers
app.use('/poMapping', require("./routers/po_mapping.router"));
app.use('/cloudAccess', require("./routers/cloud_access.router"));
app.use('/UserList', require("./routers/user_list.router"));
app.use('/OnboardingMid',require("./routers/onboarding_mid.router"));
app.use('/CreditsAdding',require("./routers/credits_adding.router"));
app.use('/MachineAccess',require("./routers/machine_access.router"));

db.seq.sync().then(() => {
  app.listen(port, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${port}`);
  });
});