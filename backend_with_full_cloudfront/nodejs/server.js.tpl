const express = require('express')
const app = express()

app.get('/api/', (req, res) => {
  res.send('API!')
})

app.get('/', (req, res) => {
  res.send('Root location')
})

app.listen(${APP_PORT}, () => {
  console.log(`Example app listening on port 8080`)
})
