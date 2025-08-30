module Database

using SQLite
using DBInterface
using UUIDs

export init_database, create_user, get_user, get_all_users, update_user, delete_user, create_post, get_post, get_all_posts, update_post, delete_post

# Initialize the SQLite database and create tables
function init_database(db_path="sqlite.db")
    db = SQLite.DB(db_path)
    
    # Create users table with comprehensive fields
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            age INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Create posts table for additional CRUD operations
    DBInterface.execute(db, """
        CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
    """)
    
    return db
end

# User CRUD operations
function create_user(db, name, email, age=nothing)
    user_id = string(uuid4())
    
    try
        if age === nothing
            DBInterface.execute(db, 
                "INSERT INTO users (id, name, email) VALUES (?, ?, ?)",
                [user_id, name, email])
        else
            DBInterface.execute(db, 
                "INSERT INTO users (id, name, email, age) VALUES (?, ?, ?, ?)",
                [user_id, name, email, age])
        end
        return get_user(db, user_id)
    catch e
        if occursin("UNIQUE constraint failed", string(e))
            throw(ArgumentError("Email already exists"))
        else
            throw(e)
        end
    end
end

function get_user(db, user_id)
    result = DBInterface.execute(db, 
        "SELECT id, name, email, age, created_at, updated_at FROM users WHERE id = ?",
        [user_id])
    
    row = collect(result)
    if isempty(row)
        return nothing
    end
    
    user = row[1]
    return Dict(
        "id" => user[1],
        "name" => user[2],
        "email" => user[3],
        "age" => user[4],
        "created_at" => user[5],
        "updated_at" => user[6]
    )
end

function get_all_users(db; limit=100, offset=0)
    result = DBInterface.execute(db,
        "SELECT id, name, email, age, created_at, updated_at FROM users LIMIT ? OFFSET ?",
        [limit, offset])
    
    users = []
    for row in result
        push!(users, Dict(
            "id" => row[1],
            "name" => row[2],
            "email" => row[3],
            "age" => row[4],
            "created_at" => row[5],
            "updated_at" => row[6]
        ))
    end
    
    return users
end

function update_user(db, user_id, updates)
    # Check if user exists
    existing_user = get_user(db, user_id)
    if existing_user === nothing
        return nothing
    end
    
    # Build dynamic UPDATE query
    set_clauses = []
    params = []
    
    for (key, value) in updates
        if key in ["name", "email", "age"]
            push!(set_clauses, "$key = ?")
            push!(params, value)
        end
    end
    
    if isempty(set_clauses)
        throw(ArgumentError("No valid fields to update"))
    end
    
    push!(set_clauses, "updated_at = CURRENT_TIMESTAMP")
    push!(params, user_id)
    
    query = "UPDATE users SET " * join(set_clauses, ", ") * " WHERE id = ?"
    
    try
        DBInterface.execute(db, query, params)
        return get_user(db, user_id)
    catch e
        if occursin("UNIQUE constraint failed", string(e))
            throw(ArgumentError("Email already exists"))
        else
            throw(e)
        end
    end
end

function delete_user(db, user_id)
    # Check if user exists
    existing_user = get_user(db, user_id)
    if existing_user === nothing
        return false
    end
    
    DBInterface.execute(db, "DELETE FROM users WHERE id = ?", [user_id])
    return true
end

# Post CRUD operations
function create_post(db, user_id, title, content="")
    post_id = string(uuid4())
    
    # Verify user exists
    user = get_user(db, user_id)
    if user === nothing
        throw(ArgumentError("User not found"))
    end
    
    DBInterface.execute(db, 
        "INSERT INTO posts (id, user_id, title, content) VALUES (?, ?, ?, ?)",
        [post_id, user_id, title, content])
    
    return get_post(db, post_id)
end

function get_post(db, post_id)
    result = DBInterface.execute(db, 
        "SELECT id, user_id, title, content, created_at, updated_at FROM posts WHERE id = ?",
        [post_id])
    
    row = collect(result)
    if isempty(row)
        return nothing
    end
    
    post = row[1]
    return Dict(
        "id" => post[1],
        "user_id" => post[2],
        "title" => post[3],
        "content" => post[4],
        "created_at" => post[5],
        "updated_at" => post[6]
    )
end

function get_all_posts(db; limit=100, offset=0)
    result = DBInterface.execute(db,
        "SELECT id, user_id, title, content, created_at, updated_at FROM posts LIMIT ? OFFSET ?",
        [limit, offset])
    
    posts = []
    for row in result
        push!(posts, Dict(
            "id" => row[1],
            "user_id" => row[2],
            "title" => row[3],
            "content" => row[4],
            "created_at" => row[5],
            "updated_at" => row[6]
        ))
    end
    
    return posts
end

function update_post(db, post_id, updates)
    # Check if post exists
    existing_post = get_post(db, post_id)
    if existing_post === nothing
        return nothing
    end
    
    # Build dynamic UPDATE query
    set_clauses = []
    params = []
    
    for (key, value) in updates
        if key in ["title", "content"]
            push!(set_clauses, "$key = ?")
            push!(params, value)
        end
    end
    
    if isempty(set_clauses)
        throw(ArgumentError("No valid fields to update"))
    end
    
    push!(set_clauses, "updated_at = CURRENT_TIMESTAMP")
    push!(params, post_id)
    
    query = "UPDATE posts SET " * join(set_clauses, ", ") * " WHERE id = ?"
    DBInterface.execute(db, query, params)
    
    return get_post(db, post_id)
end

function delete_post(db, post_id)
    # Check if post exists
    existing_post = get_post(db, post_id)
    if existing_post === nothing
        return false
    end
    
    DBInterface.execute(db, "DELETE FROM posts WHERE id = ?", [post_id])
    return true
end

end # module
