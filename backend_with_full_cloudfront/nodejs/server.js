const express = require('express')
const app = express()

app.get('/api/', (req, res) => {
  res.send('API!')
})

app.get('/', (req, res) => {
  res.send('Root!')
})

app.listen(8080, () => {
  console.log(`Example app listening on port 8080`)
})
