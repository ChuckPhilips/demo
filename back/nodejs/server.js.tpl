const express = require('express');
const app = express();
import { Users } from "./users.js";
const cors = require('cors');
import axios from "axios";

app.use(cors());

app.get("/", (req, res) => {
  const { q } = req.query;

  const keys = ["first_name", "last_name", "email"];

  const search = (data) => {
    return data.filter((item) =>
      keys.some((key) => item[key].toLowerCase().includes(q))
    );
  };

  q ? res.json(search(Users).slice(0, 10)) : res.json(Users.slice(0, 10));
});

app.listen(${APP_PORT}, () => console.log("API is working!"));
