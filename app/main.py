"""
Secure Docker CI Pipeline - Demo API
A simple FastAPI application demonstrating DevSecOps best practices.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, List, Optional
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Secure API Demo",
    description="A microservice demonstrating Docker CI/CD best practices",
    version="1.0.0"
)


class Item(BaseModel):
    """Item model for demonstration"""
    name: str
    description: Optional[str] = None
    price: float
    tax: Optional[float] = None


class HealthResponse(BaseModel):
    """Health check response model"""
    status: str
    version: str
    environment: str


# In-memory storage for demo purposes
items_db: Dict[int, Item] = {}


@app.get("/", tags=["Root"])
async def root() -> Dict[str, str]:
    """Root endpoint"""
    return {
        "message": "Welcome to Secure Docker CI Pipeline Demo",
        "docs": "/docs",
        "health": "/health"
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check() -> HealthResponse:
    """Health check endpoint for container orchestration"""
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        environment=os.getenv("ENVIRONMENT", "production")
    )


@app.get("/items", response_model=List[Item], tags=["Items"])
async def list_items() -> List[Item]:
    """List all items"""
    return list(items_db.values())


@app.get("/items/{item_id}", response_model=Item, tags=["Items"])
async def get_item(item_id: int) -> Item:
    """Get a specific item by ID"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    return items_db[item_id]


@app.post("/items", response_model=Item, status_code=201, tags=["Items"])
async def create_item(item: Item) -> Item:
    """Create a new item"""
    # assign a new integer id based on existing keys to avoid relying on a global counter
    new_id = max(items_db.keys(), default=0) + 1
    items_db[new_id] = item
    logger.info(f"Created item {new_id}: {item.name}")
    return item


@app.put("/items/{item_id}", response_model=Item, tags=["Items"])
async def update_item(item_id: int, item: Item) -> Item:
    """Update an existing item"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    items_db[item_id] = item
    logger.info(f"Updated item {item_id}: {item.name}")
    return item


@app.delete("/items/{item_id}", tags=["Items"])
async def delete_item(item_id: int) -> Dict[str, str]:
    """Delete an item"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    del items_db[item_id]
    logger.info(f"Deleted item {item_id}")
    return {"message": "Item deleted successfully"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
