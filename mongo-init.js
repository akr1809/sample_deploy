// MongoDB initialization script
db = db.getSiblingDB('userapp');

// Create a collection and insert a sample document (optional)
db.users.insertOne({
    name: "Welcome User",
    createdAt: new Date(),
    updatedAt: new Date()
});

print("Database initialized successfully!");