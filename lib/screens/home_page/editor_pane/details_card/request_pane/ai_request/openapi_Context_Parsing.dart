import 'dart:convert';

void main() {
  // for testing I've taken shop.json
  final String openApiRaw = r'''{
    "openapi": "3.1.0",
    "info": {
        "title": "ShopAPI",
        "description": "A medium-complexity online shopping backend",
        "version": "1.0.0"
    },
    "paths": {
        "/auth/register": {
            "post": {
                "tags": [
                    "Auth"
                ],
                "summary": "Register",
                "operationId": "register_auth_register_post",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/RegisterRequest"
                            }
                        }
                    },
                    "required": true
                },
                "responses": {
                    "201": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/UserOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/auth/login": {
            "post": {
                "tags": [
                    "Auth"
                ],
                "summary": "Login",
                "operationId": "login_auth_login_post",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/LoginRequest"
                            }
                        }
                    },
                    "required": true
                },
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/TokenResponse"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/auth/me": {
            "get": {
                "tags": [
                    "Auth"
                ],
                "summary": "Me",
                "operationId": "me_auth_me_get",
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/UserOut"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            }
        },
        "/categories": {
            "get": {
                "tags": [
                    "Categories"
                ],
                "summary": "List Categories",
                "operationId": "list_categories_categories_get",
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "items": {
                                        "$ref": "#/components/schemas/CategoryOut"
                                    },
                                    "type": "array",
                                    "title": "Response List Categories Categories Get"
                                }
                            }
                        }
                    }
                }
            },
            "post": {
                "tags": [
                    "Categories"
                ],
                "summary": "Create Category",
                "operationId": "create_category_categories_post",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/CategoryCreate"
                            }
                        }
                    },
                    "required": true
                },
                "responses": {
                    "201": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/CategoryOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            }
        },
        "/categories/{cat_id}": {
            "delete": {
                "tags": [
                    "Categories"
                ],
                "summary": "Delete Category",
                "operationId": "delete_category_categories__cat_id__delete",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "cat_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Cat Id"
                        }
                    }
                ],
                "responses": {
                    "204": {
                        "description": "Successful Response"
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/products": {
            "get": {
                "tags": [
                    "Products"
                ],
                "summary": "List Products",
                "operationId": "list_products_products_get",
                "parameters": [
                    {
                        "name": "category_id",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "anyOf": [
                                {
                                    "type": "integer"
                                },
                                {
                                    "type": "null"
                                }
                            ],
                            "title": "Category Id"
                        }
                    },
                    {
                        "name": "min_price",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "anyOf": [
                                {
                                    "type": "number"
                                },
                                {
                                    "type": "null"
                                }
                            ],
                            "title": "Min Price"
                        }
                    },
                    {
                        "name": "max_price",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "anyOf": [
                                {
                                    "type": "number"
                                },
                                {
                                    "type": "null"
                                }
                            ],
                            "title": "Max Price"
                        }
                    },
                    {
                        "name": "search",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "anyOf": [
                                {
                                    "type": "string"
                                },
                                {
                                    "type": "null"
                                }
                            ],
                            "title": "Search"
                        }
                    },
                    {
                        "name": "in_stock",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "type": "boolean",
                            "default": false,
                            "title": "In Stock"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "$ref": "#/components/schemas/ProductOut"
                                    },
                                    "title": "Response List Products Products Get"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            },
            "post": {
                "tags": [
                    "Products"
                ],
                "summary": "Create Product",
                "operationId": "create_product_products_post",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "requestBody": {
                    "required": true,
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/ProductCreate"
                            }
                        }
                    }
                },
                "responses": {
                    "201": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/ProductOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/products/{product_id}": {
            "get": {
                "tags": [
                    "Products"
                ],
                "summary": "Get Product",
                "operationId": "get_product_products__product_id__get",
                "parameters": [
                    {
                        "name": "product_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Product Id"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/ProductOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            },
            "patch": {
                "tags": [
                    "Products"
                ],
                "summary": "Update Product",
                "operationId": "update_product_products__product_id__patch",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "product_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Product Id"
                        }
                    }
                ],
                "requestBody": {
                    "required": true,
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/ProductUpdate"
                            }
                        }
                    }
                },
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/ProductOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            },
            "delete": {
                "tags": [
                    "Products"
                ],
                "summary": "Delete Product",
                "operationId": "delete_product_products__product_id__delete",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "product_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Product Id"
                        }
                    }
                ],
                "responses": {
                    "204": {
                        "description": "Successful Response"
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/cart": {
            "get": {
                "tags": [
                    "Cart"
                ],
                "summary": "Get Cart",
                "operationId": "get_cart_cart_get",
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "items": {
                                        "$ref": "#/components/schemas/CartItemOut"
                                    },
                                    "type": "array",
                                    "title": "Response Get Cart Cart Get"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            },
            "post": {
                "tags": [
                    "Cart"
                ],
                "summary": "Add To Cart",
                "operationId": "add_to_cart_cart_post",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/CartAddRequest"
                            }
                        }
                    },
                    "required": true
                },
                "responses": {
                    "201": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/CartItemOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            },
            "delete": {
                "tags": [
                    "Cart"
                ],
                "summary": "Clear Cart",
                "operationId": "clear_cart_cart_delete",
                "responses": {
                    "204": {
                        "description": "Successful Response"
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            }
        },
        "/cart/{item_id}": {
            "patch": {
                "tags": [
                    "Cart"
                ],
                "summary": "Update Cart Item",
                "operationId": "update_cart_item_cart__item_id__patch",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "item_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Item Id"
                        }
                    },
                    {
                        "name": "quantity",
                        "in": "query",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Quantity"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/CartItemOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            },
            "delete": {
                "tags": [
                    "Cart"
                ],
                "summary": "Remove From Cart",
                "operationId": "remove_from_cart_cart__item_id__delete",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "item_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Item Id"
                        }
                    }
                ],
                "responses": {
                    "204": {
                        "description": "Successful Response"
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/orders": {
            "get": {
                "tags": [
                    "Orders"
                ],
                "summary": "My Orders",
                "operationId": "my_orders_orders_get",
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "items": {
                                        "$ref": "#/components/schemas/OrderOut"
                                    },
                                    "type": "array",
                                    "title": "Response My Orders Orders Get"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            },
            "post": {
                "tags": [
                    "Orders"
                ],
                "summary": "Place Order",
                "operationId": "place_order_orders_post",
                "requestBody": {
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/PlaceOrderRequest"
                            }
                        }
                    },
                    "required": true
                },
                "responses": {
                    "201": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/OrderOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                },
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ]
            }
        },
        "/orders/{order_id}": {
            "get": {
                "tags": [
                    "Orders"
                ],
                "summary": "Get Order",
                "operationId": "get_order_orders__order_id__get",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "order_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Order Id"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/OrderOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/orders/{order_id}/status": {
            "patch": {
                "tags": [
                    "Orders"
                ],
                "summary": "Update Order Status",
                "operationId": "update_order_status_orders__order_id__status_patch",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "order_id",
                        "in": "path",
                        "required": true,
                        "schema": {
                            "type": "integer",
                            "title": "Order Id"
                        }
                    }
                ],
                "requestBody": {
                    "required": true,
                    "content": {
                        "application/json": {
                            "schema": {
                                "$ref": "#/components/schemas/UpdateOrderStatus"
                            }
                        }
                    }
                },
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/OrderOut"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/orders/admin/all": {
            "get": {
                "tags": [
                    "Orders"
                ],
                "summary": "All Orders",
                "operationId": "all_orders_orders_admin_all_get",
                "security": [
                    {
                        "OAuth2PasswordBearer": []
                    }
                ],
                "parameters": [
                    {
                        "name": "status",
                        "in": "query",
                        "required": false,
                        "schema": {
                            "anyOf": [
                                {
                                    "$ref": "#/components/schemas/OrderStatus"
                                },
                                {
                                    "type": "null"
                                }
                            ],
                            "title": "Status"
                        }
                    }
                ],
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "$ref": "#/components/schemas/OrderOut"
                                    },
                                    "title": "Response All Orders Orders Admin All Get"
                                }
                            }
                        }
                    },
                    "422": {
                        "description": "Validation Error",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "$ref": "#/components/schemas/HTTPValidationError"
                                }
                            }
                        }
                    }
                }
            }
        },
        "/": {
            "get": {
                "tags": [
                    "Health"
                ],
                "summary": "Root",
                "operationId": "root__get",
                "responses": {
                    "200": {
                        "description": "Successful Response",
                        "content": {
                            "application/json": {
                                "schema": {}
                            }
                        }
                    }
                }
            }
        }
    },
    "components": {
        "schemas": {
            "CartAddRequest": {
                "properties": {
                    "product_id": {
                        "type": "integer",
                        "title": "Product Id"
                    },
                    "quantity": {
                        "type": "integer",
                        "title": "Quantity",
                        "default": 1
                    }
                },
                "type": "object",
                "required": [
                    "product_id"
                ],
                "title": "CartAddRequest"
            },
            "CartItemOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "quantity": {
                        "type": "integer",
                        "title": "Quantity"
                    },
                    "added_at": {
                        "type": "string",
                        "format": "date-time",
                        "title": "Added At"
                    },
                    "product": {
                        "$ref": "#/components/schemas/ProductOut"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "quantity",
                    "added_at",
                    "product"
                ],
                "title": "CartItemOut"
            },
            "CategoryCreate": {
                "properties": {
                    "name": {
                        "type": "string",
                        "title": "Name"
                    },
                    "description": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Description"
                    }
                },
                "type": "object",
                "required": [
                    "name"
                ],
                "title": "CategoryCreate"
            },
            "CategoryOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "name": {
                        "type": "string",
                        "title": "Name"
                    },
                    "description": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Description"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "name",
                    "description"
                ],
                "title": "CategoryOut"
            },
            "HTTPValidationError": {
                "properties": {
                    "detail": {
                        "items": {
                            "$ref": "#/components/schemas/ValidationError"
                        },
                        "type": "array",
                        "title": "Detail"
                    }
                },
                "type": "object",
                "title": "HTTPValidationError"
            },
            "LoginRequest": {
                "properties": {
                    "email": {
                        "type": "string",
                        "format": "email",
                        "title": "Email"
                    },
                    "password": {
                        "type": "string",
                        "title": "Password"
                    }
                },
                "type": "object",
                "required": [
                    "email",
                    "password"
                ],
                "title": "LoginRequest"
            },
            "OrderItemOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "quantity": {
                        "type": "integer",
                        "title": "Quantity"
                    },
                    "unit_price": {
                        "type": "number",
                        "title": "Unit Price"
                    },
                    "product": {
                        "$ref": "#/components/schemas/ProductOut"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "quantity",
                    "unit_price",
                    "product"
                ],
                "title": "OrderItemOut"
            },
            "OrderOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "status": {
                        "$ref": "#/components/schemas/OrderStatus"
                    },
                    "total_amount": {
                        "type": "number",
                        "title": "Total Amount"
                    },
                    "shipping_address": {
                        "type": "string",
                        "title": "Shipping Address"
                    },
                    "notes": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Notes"
                    },
                    "created_at": {
                        "type": "string",
                        "format": "date-time",
                        "title": "Created At"
                    },
                    "updated_at": {
                        "type": "string",
                        "format": "date-time",
                        "title": "Updated At"
                    },
                    "items": {
                        "items": {
                            "$ref": "#/components/schemas/OrderItemOut"
                        },
                        "type": "array",
                        "title": "Items"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "status",
                    "total_amount",
                    "shipping_address",
                    "notes",
                    "created_at",
                    "updated_at",
                    "items"
                ],
                "title": "OrderOut"
            },
            "OrderStatus": {
                "type": "string",
                "enum": [
                    "pending",
                    "confirmed",
                    "shipped",
                    "delivered",
                    "cancelled"
                ],
                "title": "OrderStatus"
            },
            "PlaceOrderRequest": {
                "properties": {
                    "shipping_address": {
                        "type": "string",
                        "title": "Shipping Address"
                    },
                    "notes": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Notes"
                    }
                },
                "type": "object",
                "required": [
                    "shipping_address"
                ],
                "title": "PlaceOrderRequest"
            },
            "ProductCreate": {
                "properties": {
                    "name": {
                        "type": "string",
                        "title": "Name"
                    },
                    "description": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Description"
                    },
                    "price": {
                        "type": "number",
                        "title": "Price"
                    },
                    "stock": {
                        "type": "integer",
                        "title": "Stock",
                        "default": 0
                    },
                    "image_url": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Image Url"
                    },
                    "category_id": {
                        "anyOf": [
                            {
                                "type": "integer"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Category Id"
                    }
                },
                "type": "object",
                "required": [
                    "name",
                    "price"
                ],
                "title": "ProductCreate"
            },
            "ProductOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "name": {
                        "type": "string",
                        "title": "Name"
                    },
                    "description": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Description"
                    },
                    "price": {
                        "type": "number",
                        "title": "Price"
                    },
                    "stock": {
                        "type": "integer",
                        "title": "Stock"
                    },
                    "image_url": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Image Url"
                    },
                    "is_active": {
                        "type": "boolean",
                        "title": "Is Active"
                    },
                    "category": {
                        "anyOf": [
                            {
                                "$ref": "#/components/schemas/CategoryOut"
                            },
                            {
                                "type": "null"
                            }
                        ]
                    },
                    "created_at": {
                        "type": "string",
                        "format": "date-time",
                        "title": "Created At"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "name",
                    "description",
                    "price",
                    "stock",
                    "image_url",
                    "is_active",
                    "category",
                    "created_at"
                ],
                "title": "ProductOut"
            },
            "ProductUpdate": {
                "properties": {
                    "name": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Name"
                    },
                    "description": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Description"
                    },
                    "price": {
                        "anyOf": [
                            {
                                "type": "number"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Price"
                    },
                    "stock": {
                        "anyOf": [
                            {
                                "type": "integer"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Stock"
                    },
                    "image_url": {
                        "anyOf": [
                            {
                                "type": "string"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Image Url"
                    },
                    "is_active": {
                        "anyOf": [
                            {
                                "type": "boolean"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Is Active"
                    },
                    "category_id": {
                        "anyOf": [
                            {
                                "type": "integer"
                            },
                            {
                                "type": "null"
                            }
                        ],
                        "title": "Category Id"
                    }
                },
                "type": "object",
                "title": "ProductUpdate"
            },
            "RegisterRequest": {
                "properties": {
                    "email": {
                        "type": "string",
                        "format": "email",
                        "title": "Email"
                    },
                    "username": {
                        "type": "string",
                        "title": "Username"
                    },
                    "full_name": {
                        "type": "string",
                        "title": "Full Name"
                    },
                    "password": {
                        "type": "string",
                        "title": "Password"
                    }
                },
                "type": "object",
                "required": [
                    "email",
                    "username",
                    "full_name",
                    "password"
                ],
                "title": "RegisterRequest"
            },
            "TokenResponse": {
                "properties": {
                    "access_token": {
                        "type": "string",
                        "title": "Access Token"
                    },
                    "token_type": {
                        "type": "string",
                        "title": "Token Type",
                        "default": "bearer"
                    }
                },
                "type": "object",
                "required": [
                    "access_token"
                ],
                "title": "TokenResponse"
            },
            "UpdateOrderStatus": {
                "properties": {
                    "status": {
                        "$ref": "#/components/schemas/OrderStatus"
                    }
                },
                "type": "object",
                "required": [
                    "status"
                ],
                "title": "UpdateOrderStatus"
            },
            "UserOut": {
                "properties": {
                    "id": {
                        "type": "integer",
                        "title": "Id"
                    },
                    "email": {
                        "type": "string",
                        "title": "Email"
                    },
                    "username": {
                        "type": "string",
                        "title": "Username"
                    },
                    "full_name": {
                        "type": "string",
                        "title": "Full Name"
                    },
                    "is_admin": {
                        "type": "boolean",
                        "title": "Is Admin"
                    },
                    "created_at": {
                        "type": "string",
                        "format": "date-time",
                        "title": "Created At"
                    }
                },
                "type": "object",
                "required": [
                    "id",
                    "email",
                    "username",
                    "full_name",
                    "is_admin",
                    "created_at"
                ],
                "title": "UserOut"
            },
            "ValidationError": {
                "properties": {
                    "loc": {
                        "items": {
                            "anyOf": [
                                {
                                    "type": "string"
                                },
                                {
                                    "type": "integer"
                                }
                            ]
                        },
                        "type": "array",
                        "title": "Location"
                    },
                    "msg": {
                        "type": "string",
                        "title": "Message"
                    },
                    "type": {
                        "type": "string",
                        "title": "Error Type"
                    }
                },
                "type": "object",
                "required": [
                    "loc",
                    "msg",
                    "type"
                ],
                "title": "ValidationError"
            }
        },
        "securitySchemes": {
            "OAuth2PasswordBearer": {
                "type": "oauth2",
                "flows": {
                    "password": {
                        "scopes": {},
                        "tokenUrl": "/auth/login"
                    }
                }
            }
        }
    }
}''';

  final Map<String, dynamic> spec = jsonDecode(openApiRaw);
  final Map<String, dynamic> allPaths = spec['paths'] ?? {};
  final Map<String, dynamic> allSchemas = spec['components']?['schemas'] ?? {};

  final Map<String, Map<String, dynamic>> featureBatches = {};

  allPaths.forEach((pathKey, pathData) {
    final segments = pathKey.split('/').where((s) => s.isNotEmpty).toList();
    final String label = segments.isEmpty ? 'root' : segments.first;

    if (!featureBatches.containsKey(label)) {
      featureBatches[label] = {
        "openapi": spec['openapi'],
        "info": spec['info'],
        "paths": <String, dynamic>{},
        "components": {"schemas": <String, dynamic>{}}
      };
    }
    featureBatches[label]!['paths'][pathKey] = pathData;

    final Set<String> refsFound = {};
    _recursiveFindRefs(pathData, refsFound);

    for (var ref in refsFound) {
      final schemaName = ref.split('/').last;
      if (allSchemas.containsKey(schemaName)) {
        featureBatches[label]!['components']['schemas'][schemaName] =
            allSchemas[schemaName];

        final Set<String> nestedRefs = {};
        _recursiveFindRefs(allSchemas[schemaName], nestedRefs);
        for (var nRef in nestedRefs) {
          final nName = nRef.split('/').last;
          featureBatches[label]!['components']['schemas'][nName] =
              allSchemas[nName];
        }
      }
    }
  });

  featureBatches.forEach((key, value) {
    print('DOMAIN: ${key.toUpperCase()} ---');
    print(JsonEncoder.withIndent('  ').convert(value));
    print('\n');
  });
}

void _recursiveFindRefs(dynamic node, Set<String> refs) {
  if (node is Map) {
    if (node.containsKey('\$ref')) {
      refs.add(node['\$ref'] as String);
    }
    node.forEach((_, value) => _recursiveFindRefs(value, refs));
  } else if (node is List) {
    for (var element in node) {
      _recursiveFindRefs(element, refs);
    }
  }
}
