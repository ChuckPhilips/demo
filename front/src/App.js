import { useState } from "react";
import { Users } from "./users";
import "./App.css";

//////////////////////BASIC SEARCH

function App() {
  const [query, setQuery] = useState("");
  return (
    <div className="app">
      <input
        className="search"
        placeholder="Search..."
        onChange={(e) => setQuery(e.target.value.toLowerCase())}
      />
      <ul className="list">
        {Users.filter((asd) =>
          asd.first_name.toLowerCase().includes(query)
        ).map((user) => (
          <li className="listItem" key={user.id}>
            {user.first_name}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
