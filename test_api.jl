#!/usr/bin/env julia

# Test script for Julia API Server
# Run this after starting the server to test all endpoints

using HTTP
using JSON3

const BASE_URL = "http://127.0.0.1:8080"

function test_api()
    println("Testing Julia API Server")
    println("========================")
    
    # Test health endpoint
    println("\n1. Testing health endpoint...")
    try
        response = HTTP.get("$BASE_URL/health")
        println("✓ Health check: $(response.status)")
        println("  Response: $(String(response.body))")
    catch e
        println("✗ Health check failed: $e")
        return
    end
    
    # Test user creation
    println("\n2. Creating a new user...")
    user_data = Dict(
        "name" => "John Doe",
        "email" => "john.doe@example.com",
        "age" => 30
    )
    
    user_id = nothing
    try
        response = HTTP.post("$BASE_URL/users", 
            ["Content-Type" => "application/json"],
            JSON3.write(user_data))
        println("✓ User created: $(response.status)")
        user_response = JSON3.read(String(response.body))
        user_id = user_response["id"]
        println("  User ID: $user_id")
    catch e
        println("✗ User creation failed: $e")
        return
    end
    
    # Test getting all users
    println("\n3. Getting all users...")
    try
        response = HTTP.get("$BASE_URL/users")
        println("✓ Get all users: $(response.status)")
        users_response = JSON3.read(String(response.body))
        println("  Total users: $(users_response["count"])")
    catch e
        println("✗ Get all users failed: $e")
    end
    
    # Test getting user by ID
    println("\n4. Getting user by ID...")
    try
        response = HTTP.get("$BASE_URL/users/$user_id")
        println("✓ Get user by ID: $(response.status)")
        user = JSON3.read(String(response.body))
        println("  User: $(user["name"]) ($(user["email"]))")
    catch e
        println("✗ Get user by ID failed: $e")
    end
    
    # Test updating user
    println("\n5. Updating user...")
    update_data = Dict("name" => "John Smith", "age" => 31)
    try
        response = HTTP.put("$BASE_URL/users/$user_id",
            ["Content-Type" => "application/json"],
            JSON3.write(update_data))
        println("✓ User updated: $(response.status)")
        updated_user = JSON3.read(String(response.body))
        println("  Updated name: $(updated_user["name"])")
    catch e
        println("✗ User update failed: $e")
    end
    
    # Test creating a post
    println("\n6. Creating a post...")
    post_data = Dict(
        "user_id" => user_id,
        "title" => "My First Post",
        "content" => "This is the content of my first post!"
    )
    
    post_id = nothing
    try
        response = HTTP.post("$BASE_URL/posts",
            ["Content-Type" => "application/json"],
            JSON3.write(post_data))
        println("✓ Post created: $(response.status)")
        post_response = JSON3.read(String(response.body))
        post_id = post_response["id"]
        println("  Post ID: $post_id")
    catch e
        println("✗ Post creation failed: $e")
    end
    
    # Test getting all posts
    println("\n7. Getting all posts...")
    try
        response = HTTP.get("$BASE_URL/posts")
        println("✓ Get all posts: $(response.status)")
        posts_response = JSON3.read(String(response.body))
        println("  Total posts: $(posts_response["count"])")
    catch e
        println("✗ Get all posts failed: $e")
    end
    
    # Test updating post
    if post_id !== nothing
        println("\n8. Updating post...")
        post_update = Dict("title" => "Updated Post Title")
        try
            response = HTTP.put("$BASE_URL/posts/$post_id",
                ["Content-Type" => "application/json"],
                JSON3.write(post_update))
            println("✓ Post updated: $(response.status)")
        catch e
            println("✗ Post update failed: $e")
        end
        
        # Test deleting post
        println("\n9. Deleting post...")
        try
            response = HTTP.delete("$BASE_URL/posts/$post_id")
            println("✓ Post deleted: $(response.status)")
        catch e
            println("✗ Post deletion failed: $e")
        end
    end
    
    # Test deleting user
    println("\n10. Deleting user...")
    try
        response = HTTP.delete("$BASE_URL/users/$user_id")
        println("✓ User deleted: $(response.status)")
    catch e
        println("✗ User deletion failed: $e")
    end
    
    println("\n✅ API testing completed!")
end

# Run tests if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    test_api()
end
