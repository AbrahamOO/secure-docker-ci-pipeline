"""
Comprehensive test suite for the Secure Docker CI Pipeline API
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app, items_db, Item

client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_db():
    """Reset the database before each test"""
    items_db.clear()
    yield
    items_db.clear()


class TestRootEndpoints:
    """Test root and health endpoints"""

    def test_root_endpoint(self):
        """Test root endpoint returns welcome message"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Welcome" in data["message"]

    def test_health_check(self):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "environment" in data


class TestItemCRUD:
    """Test CRUD operations for items"""

    def test_list_items_empty(self):
        """Test listing items when database is empty"""
        response = client.get("/items")
        assert response.status_code == 200
        assert response.json() == []

    def test_create_item(self):
        """Test creating a new item"""
        item_data = {
            "name": "Test Item",
            "description": "A test item",
            "price": 29.99,
            "tax": 2.50
        }
        response = client.post("/items", json=item_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == item_data["name"]
        assert data["price"] == item_data["price"]

    def test_create_item_without_optional_fields(self):
        """Test creating item without optional fields"""
        item_data = {
            "name": "Minimal Item",
            "price": 9.99
        }
        response = client.post("/items", json=item_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Minimal Item"
        assert data["description"] is None
        assert data["tax"] is None

    def test_get_item(self):
        """Test retrieving a specific item"""
        # Create an item first
        item_data = {
            "name": "Laptop",
            "description": "High-performance laptop",
            "price": 1299.99,
            "tax": 130.00
        }
        create_response = client.post("/items", json=item_data)
        assert create_response.status_code == 201

        # Get the item
        response = client.get("/items/1")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Laptop"
        assert data["price"] == 1299.99

    def test_get_nonexistent_item(self):
        """Test retrieving a non-existent item returns 404"""
        response = client.get("/items/999")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    def test_update_item(self):
        """Test updating an existing item"""
        # Create an item
        item_data = {
            "name": "Phone",
            "price": 699.99
        }
        client.post("/items", json=item_data)

        # Update the item
        updated_data = {
            "name": "Smartphone",
            "description": "Latest model",
            "price": 799.99,
            "tax": 80.00
        }
        response = client.put("/items/1", json=updated_data)
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Smartphone"
        assert data["price"] == 799.99

    def test_update_nonexistent_item(self):
        """Test updating a non-existent item returns 404"""
        item_data = {
            "name": "Ghost Item",
            "price": 0.99
        }
        response = client.put("/items/999", json=item_data)
        assert response.status_code == 404

    def test_delete_item(self):
        """Test deleting an item"""
        # Create an item
        item_data = {
            "name": "Temporary Item",
            "price": 5.99
        }
        client.post("/items", json=item_data)

        # Delete the item
        response = client.delete("/items/1")
        assert response.status_code == 200
        assert "deleted" in response.json()["message"].lower()

        # Verify item is deleted
        get_response = client.get("/items/1")
        assert get_response.status_code == 404

    def test_delete_nonexistent_item(self):
        """Test deleting a non-existent item returns 404"""
        response = client.delete("/items/999")
        assert response.status_code == 404

    def test_list_multiple_items(self):
        """Test listing multiple items"""
        items = [
            {"name": "Item 1", "price": 10.00},
            {"name": "Item 2", "price": 20.00},
            {"name": "Item 3", "price": 30.00}
        ]

        for item in items:
            client.post("/items", json=item)

        response = client.get("/items")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        assert all(item["name"] in ["Item 1", "Item 2", "Item 3"] for item in data)


class TestValidation:
    """Test input validation"""

    def test_create_item_missing_required_field(self):
        """Test creating item without required fields fails"""
        item_data = {
            "description": "Missing name and price"
        }
        response = client.post("/items", json=item_data)
        assert response.status_code == 422

    def test_create_item_invalid_price(self):
        """Test creating item with invalid price type"""
        item_data = {
            "name": "Invalid Item",
            "price": "not-a-number"
        }
        response = client.post("/items", json=item_data)
        assert response.status_code == 422

    def test_get_item_invalid_id(self):
        """Test getting item with invalid ID type"""
        response = client.get("/items/not-a-number")
        assert response.status_code == 422


class TestAPIDocumentation:
    """Test API documentation endpoints"""

    def test_openapi_schema(self):
        """Test OpenAPI schema is accessible"""
        response = client.get("/openapi.json")
        assert response.status_code == 200
        schema = response.json()
        assert "openapi" in schema
        assert "info" in schema
        assert schema["info"]["title"] == "Secure API Demo"

    def test_docs_endpoint(self):
        """Test Swagger UI is accessible"""
        response = client.get("/docs")
        assert response.status_code == 200
