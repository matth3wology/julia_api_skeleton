module Server

using HTTP
using JSON3
using UUIDs
using Dates
using SQLite
include("database.jl")
using .Database

export start_server

# Global database connection
const DB = Ref{SQLite.DB}()

# Utility functions
function json_response(data, status=200)
    return HTTP.Response(status, ["Content-Type" => "application/json"], JSON3.write(data))
end

function error_response(message, status=400)
    return json_response(Dict("error" => message), status)
end

function parse_json_body(req)
    try
        if isempty(req.body)
            return Dict()
        end
        return JSON3.read(String(req.body), Dict)
    catch e
        throw(ArgumentError("Invalid JSON in request body"))
    end
end

function validate_required_fields(data, required_fields)
    missing_fields = []
    for field in required_fields
        if !haskey(data, field) || isempty(string(data[field]))
            push!(missing_fields, field)
        end
    end
    
    if !isempty(missing_fields)
        throw(ArgumentError("Missing required fields: $(join(missing_fields, ", "))"))
    end
end

# Route handlers

# Health check endpoint
function health_check(req::HTTP.Request)
    return json_response(Dict("status" => "healthy", "timestamp" => string(now())))
end

# User endpoints
function create_user_handler(req::HTTP.Request)
    try
        data = parse_json_body(req)
        validate_required_fields(data, ["name", "email"])
        
        age = get(data, "age", nothing)
        if age !== nothing
            age = Int(age)
        end
        
        user = Database.create_user(DB[], data["name"], data["email"], age)
        return json_response(user, 201)
        
    catch e
        if isa(e, ArgumentError)
            return error_response(e.msg, 400)
        else
            println("Error creating user: $e")
            return error_response("Internal server error", 500)
        end
    end
end

function get_user_handler(req::HTTP.Request)
    # Extract user ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("User ID required", 400)
    end
    
    user_id = path_parts[3]
    
    try
        user = Database.get_user(DB[], user_id)
        if user === nothing
            return error_response("User not found", 404)
        end
        return json_response(user)
        
    catch e
        println("Error getting user: $e")
        return error_response("Internal server error", 500)
    end
end

function get_all_users_handler(req::HTTP.Request)
    try
        # Parse query parameters
        uri = HTTP.URI(req.target)
        query_params = HTTP.queryparams(uri)
        
        limit = get(query_params, "limit", "100") |> x -> parse(Int, x)
        offset = get(query_params, "offset", "0") |> x -> parse(Int, x)
        
        users = Database.get_all_users(DB[]; limit=limit, offset=offset)
        return json_response(Dict("users" => users, "count" => length(users)))
        
    catch e
        println("Error getting users: $e")
        return error_response("Internal server error", 500)
    end
end

function update_user_handler(req::HTTP.Request)
    # Extract user ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("User ID required", 400)
    end
    
    user_id = path_parts[3]
    
    try
        data = parse_json_body(req)
        
        user = Database.update_user(DB[], user_id, data)
        if user === nothing
            return error_response("User not found", 404)
        end
        return json_response(user)
        
    catch e
        if isa(e, ArgumentError)
            return error_response(e.msg, 400)
        else
            println("Error updating user: $e")
            return error_response("Internal server error", 500)
        end
    end
end

function delete_user_handler(req::HTTP.Request)
    # Extract user ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("User ID required", 400)
    end
    
    user_id = path_parts[3]
    
    try
        success = Database.delete_user(DB[], user_id)
        if !success
            return error_response("User not found", 404)
        end
        return json_response(Dict("message" => "User deleted successfully"))
        
    catch e
        println("Error deleting user: $e")
        return error_response("Internal server error", 500)
    end
end

# Post endpoints
function create_post_handler(req::HTTP.Request)
    try
        data = parse_json_body(req)
        validate_required_fields(data, ["user_id", "title"])
        
        content = get(data, "content", "")
        post = Database.create_post(DB[], data["user_id"], data["title"], content)
        return json_response(post, 201)
        
    catch e
        if isa(e, ArgumentError)
            return error_response(e.msg, 400)
        else
            println("Error creating post: $e")
            return error_response("Internal server error", 500)
        end
    end
end

function get_post_handler(req::HTTP.Request)
    # Extract post ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("Post ID required", 400)
    end
    
    post_id = path_parts[3]
    
    try
        post = Database.get_post(DB[], post_id)
        if post === nothing
            return error_response("Post not found", 404)
        end
        return json_response(post)
        
    catch e
        println("Error getting post: $e")
        return error_response("Internal server error", 500)
    end
end

function get_all_posts_handler(req::HTTP.Request)
    try
        # Parse query parameters
        uri = HTTP.URI(req.target)
        query_params = HTTP.queryparams(uri)
        
        limit = get(query_params, "limit", "100") |> x -> parse(Int, x)
        offset = get(query_params, "offset", "0") |> x -> parse(Int, x)
        
        posts = Database.get_all_posts(DB[]; limit=limit, offset=offset)
        return json_response(Dict("posts" => posts, "count" => length(posts)))
        
    catch e
        println("Error getting posts: $e")
        return error_response("Internal server error", 500)
    end
end

function update_post_handler(req::HTTP.Request)
    # Extract post ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("Post ID required", 400)
    end
    
    post_id = path_parts[3]
    
    try
        data = parse_json_body(req)
        
        post = Database.update_post(DB[], post_id, data)
        if post === nothing
            return error_response("Post not found", 404)
        end
        return json_response(post)
        
    catch e
        if isa(e, ArgumentError)
            return error_response(e.msg, 400)
        else
            println("Error updating post: $e")
            return error_response("Internal server error", 500)
        end
    end
end

function delete_post_handler(req::HTTP.Request)
    # Extract post ID from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return error_response("Post ID required", 400)
    end
    
    post_id = path_parts[3]
    
    try
        success = Database.delete_post(DB[], post_id)
        if !success
            return error_response("Post not found", 404)
        end
        return json_response(Dict("message" => "Post deleted successfully"))
        
    catch e
        println("Error deleting post: $e")
        return error_response("Internal server error", 500)
    end
end

# Main router function
function router(req::HTTP.Request)
    # Add CORS headers
    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]
    
    # Handle CORS preflight requests
    if req.method == "OPTIONS"
        return HTTP.Response(200, headers, "")
    end
    
    # Parse the path
    path_parts = split(req.target, "?")[1]  # Remove query parameters for routing
    path_parts = split(path_parts, "/")
    
    try
        # Route to appropriate handler based on path and method
        if path_parts[2] == "health"
            return health_check(req)
            
        elseif path_parts[2] == "users"
            if req.method == "POST"
                return create_user_handler(req)
            elseif req.method == "GET"
                if length(path_parts) == 2
                    return get_all_users_handler(req)
                else
                    return get_user_handler(req)
                end
            elseif req.method == "PUT"
                return update_user_handler(req)
            elseif req.method == "DELETE"
                return delete_user_handler(req)
            else
                return error_response("Method not allowed", 405)
            end
            
        elseif path_parts[2] == "posts"
            if req.method == "POST"
                return create_post_handler(req)
            elseif req.method == "GET"
                if length(path_parts) == 2
                    return get_all_posts_handler(req)
                else
                    return get_post_handler(req)
                end
            elseif req.method == "PUT"
                return update_post_handler(req)
            elseif req.method == "DELETE"
                return delete_post_handler(req)
            else
                return error_response("Method not allowed", 405)
            end
            
        else
            return error_response("Not found", 404)
        end
        
    catch e
        println("Router error: $e")
        return error_response("Internal server error", 500)
    end
end

# Start the HTTP server
function start_server(host="127.0.0.1", port=8080, db_path="sqlite.db")
    println("Initializing database...")
    DB[] = Database.init_database(db_path)
    
    println("Starting server on $host:$port...")
    println("API endpoints:")
    println("  GET    /health")
    println("  GET    /users (supports ?limit=N&offset=N)")
    println("  POST   /users")
    println("  GET    /users/{id}")
    println("  PUT    /users/{id}")
    println("  DELETE /users/{id}")
    println("  GET    /posts (supports ?limit=N&offset=N)")
    println("  POST   /posts")
    println("  GET    /posts/{id}")
    println("  PUT    /posts/{id}")
    println("  DELETE /posts/{id}")
    
    # Start the server
    HTTP.serve(router, host, port)
end

end # module
