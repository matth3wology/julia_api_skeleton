# Julia HTTP API Server

A robust RESTful API server built with Julia, featuring CRUD operations and SQLite database integration.

## Features

- **HTTP Server**: Built with HTTP.jl for high performance
- **SQLite Database**: Local database with automatic schema initialization  
- **CRUD Operations**: Complete Create, Read, Update, Delete functionality
- **Two Resources**: Users and Posts with relationships
- **JSON API**: All endpoints accept and return JSON
- **Error Handling**: Comprehensive error handling and validation
- **Query Parameters**: Support for pagination with limit/offset
- **CORS Support**: Cross-origin resource sharing enabled

## Quick Start

1. **Install Julia** (version 1.6 or higher)

2. **Install Dependencies**:
   ```bash
   julia --project=. -e "using Pkg; Pkg.instantiate()"
   ```

3. **Run the Server**:
   ```bash
   julia main.jl
   ```

The server will start on `http://127.0.0.1:8080` by default.

## Configuration

Environment variables:
- `HOST`: Server host (default: `127.0.0.1`)
- `PORT`: Server port (default: `8080`)
- `DB_PATH`: SQLite database path (default: `sqlite.db`)

## API Endpoints

### Health Check
- `GET /health` - Server health status

### Users
- `GET /users` - List all users (supports `?limit=N&offset=N`)
- `POST /users` - Create a new user
- `GET /users/{id}` - Get user by ID
- `PUT /users/{id}` - Update user by ID
- `DELETE /users/{id}` - Delete user by ID

### Posts
- `GET /posts` - List all posts (supports `?limit=N&offset=N`)
- `POST /posts` - Create a new post
- `GET /posts/{id}` - Get post by ID
- `PUT /posts/{id}` - Update post by ID
- `DELETE /posts/{id}` - Delete post by ID

## API Examples

### Create a User
```bash
curl -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com", "age": 30}'
```

### Get All Users
```bash
curl http://localhost:8080/users
```

### Get User by ID
```bash
curl http://localhost:8080/users/{user-id}
```

### Update User
```bash
curl -X PUT http://localhost:8080/users/{user-id} \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "age": 25}'
```

### Delete User
```bash
curl -X DELETE http://localhost:8080/users/{user-id}
```

### Create a Post
```bash
curl -X POST http://localhost:8080/posts \
  -H "Content-Type: application/json" \
  -d '{"user_id": "{user-id}", "title": "My First Post", "content": "Hello World!"}'
```

### Get All Posts with Pagination
```bash
curl "http://localhost:8080/posts?limit=10&offset=0"
```

## Database Schema

### Users Table
- `id`: TEXT (UUID, Primary Key)
- `name`: TEXT (Required)
- `email`: TEXT (Required, Unique)
- `age`: INTEGER (Optional)
- `created_at`: DATETIME
- `updated_at`: DATETIME

### Posts Table
- `id`: TEXT (UUID, Primary Key)
- `user_id`: TEXT (Foreign Key to users.id)
- `title`: TEXT (Required)
- `content`: TEXT (Optional)
- `created_at`: DATETIME
- `updated_at`: DATETIME

## Error Handling

The API returns appropriate HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request (validation errors)
- `404`: Not Found
- `405`: Method Not Allowed
- `500`: Internal Server Error

Error responses include a JSON object with an `error` field describing the issue.

## Project Structure

```
julia_server/
├── Project.toml          # Julia project dependencies
├── main.jl              # Application entry point
├── src/
│   ├── database.jl      # Database operations
│   └── server.jl        # HTTP server and routing
├── sqlite.db            # SQLite database (created automatically)
└── README.md           # This file
```

## Development

To extend the API:
1. Add new database functions in `src/database.jl`
2. Add new route handlers in `src/server.jl`
3. Update the router function to handle new endpoints

## Dependencies

- **HTTP.jl**: HTTP server functionality
- **JSON3.jl**: JSON serialization/deserialization
- **SQLite.jl**: SQLite database interface
- **DBInterface.jl**: Database abstraction layer
- **UUIDs.jl**: UUID generation for primary keys
