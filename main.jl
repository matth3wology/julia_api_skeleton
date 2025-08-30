#!/usr/bin/env julia

# Julia HTTP API Server with SQLite Backend
# A robust REST API server with CRUD operations

using Pkg

# Activate the project environment
Pkg.activate(".")
Pkg.instantiate()

# Include the server module
include("src/server.jl")
using .Server

function main()
    # Configuration
    host = get(ENV, "HOST", "127.0.0.1")
    port = parse(Int, get(ENV, "PORT", "8080"))
    db_path = get(ENV, "DB_PATH", "sqlite.db")
    
    println("Julia HTTP API Server")
    println("===================")
    println("Host: $host")
    println("Port: $port")
    println("Database: $db_path")
    println()
    
    try
        # Start the server
        Server.start_server(host, port, db_path)
    catch e
        if isa(e, InterruptException)
            println("\nServer stopped gracefully.")
        else
            println("Error starting server: $e")
        end
    end
end

# Run the main function if this script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
