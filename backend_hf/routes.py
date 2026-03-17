from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas, auth


# ── Auth ──────────────────────────────────────────────────────────────────────

auth_router = APIRouter(prefix="/auth", tags=["Auth"])


@auth_router.post("/register", response_model=schemas.UserOut, status_code=201)
def register(body: schemas.RegisterRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == body.email).first():
        raise HTTPException(400, "Email already registered")
    if db.query(models.User).filter(models.User.username == body.username).first():
        raise HTTPException(400, "Username taken")

    user = models.User(
        email     = body.email,
        username  = body.username,
        full_name = body.full_name,
        hashed_pw = auth.hash_password(body.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@auth_router.post("/login", response_model=schemas.TokenResponse)
def login(body: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == body.email).first()
    if not user or not auth.verify_password(body.password, user.hashed_pw):
        raise HTTPException(401, "Wrong email or password")

    token = auth.create_access_token(user.id, user.email)
    return {"access_token": token}


@auth_router.get("/me", response_model=schemas.UserOut)
def me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user


# ── Categories ────────────────────────────────────────────────────────────────

category_router = APIRouter(prefix="/categories", tags=["Categories"])


@category_router.get("", response_model=List[schemas.CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return db.query(models.Category).all()


@category_router.post("", response_model=schemas.CategoryOut, status_code=201)
def create_category(
    body: schemas.CategoryCreate,
    db:   Session = Depends(get_db),
    _:    models.User = Depends(auth.require_admin),
):
    if db.query(models.Category).filter(models.Category.name == body.name).first():
        raise HTTPException(400, "Category already exists")
    cat = models.Category(**body.model_dump())
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@category_router.delete("/{cat_id}", status_code=204)
def delete_category(
    cat_id: int,
    db:     Session = Depends(get_db),
    _:      models.User = Depends(auth.require_admin),
):
    cat = db.query(models.Category).filter(models.Category.id == cat_id).first()
    if not cat:
        raise HTTPException(404, "Category not found")
    db.delete(cat)
    db.commit()


# ── Products ──────────────────────────────────────────────────────────────────

product_router = APIRouter(prefix="/products", tags=["Products"])


@product_router.get("", response_model=List[schemas.ProductOut])
def list_products(
    category_id: Optional[int]  = Query(None),
    min_price:   Optional[float] = Query(None),
    max_price:   Optional[float] = Query(None),
    search:      Optional[str]   = Query(None),
    in_stock:    bool            = Query(False),
    db: Session = Depends(get_db),
):
    q = db.query(models.Product).filter(models.Product.is_active == True)

    if category_id:
        q = q.filter(models.Product.category_id == category_id)
    if min_price is not None:
        q = q.filter(models.Product.price >= min_price)
    if max_price is not None:
        q = q.filter(models.Product.price <= max_price)
    if search:
        q = q.filter(models.Product.name.ilike(f"%{search}%"))
    if in_stock:
        q = q.filter(models.Product.stock > 0)

    return q.all()


@product_router.get("/{product_id}", response_model=schemas.ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(404, "Product not found")
    return p


@product_router.post("", response_model=schemas.ProductOut, status_code=201)
def create_product(
    body: schemas.ProductCreate,
    db:   Session = Depends(get_db),
    _:    models.User = Depends(auth.require_admin),
):
    if body.category_id:
        cat = db.query(models.Category).filter(models.Category.id == body.category_id).first()
        if not cat:
            raise HTTPException(404, "Category not found")

    product = models.Product(**body.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@product_router.patch("/{product_id}", response_model=schemas.ProductOut)
def update_product(
    product_id: int,
    body: schemas.ProductUpdate,
    db:   Session = Depends(get_db),
    _:    models.User = Depends(auth.require_admin),
):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(404, "Product not found")

    for field, val in body.model_dump(exclude_unset=True).items():
        setattr(p, field, val)

    db.commit()
    db.refresh(p)
    return p


@product_router.delete("/{product_id}", status_code=204)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    _:  models.User = Depends(auth.require_admin),
):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(404, "Product not found")
    p.is_active = False   # soft delete
    db.commit()


# ── Cart ──────────────────────────────────────────────────────────────────────

cart_router = APIRouter(prefix="/cart", tags=["Cart"])


@cart_router.get("", response_model=List[schemas.CartItemOut])
def get_cart(
    db:   Session = Depends(get_db),
    user: models.User = Depends(auth.get_current_user),
):
    return db.query(models.CartItem).filter(models.CartItem.user_id == user.id).all()


@cart_router.post("", response_model=schemas.CartItemOut, status_code=201)
def add_to_cart(
    body: schemas.CartAddRequest,
    db:   Session = Depends(get_db),
    user: models.User = Depends(auth.get_current_user),
):
    product = db.query(models.Product).filter(
        models.Product.id == body.product_id,
        models.Product.is_active == True,
    ).first()
    if not product:
        raise HTTPException(404, "Product not found")
    if product.stock < body.quantity:
        raise HTTPException(400, f"Only {product.stock} left in stock")

    existing = db.query(models.CartItem).filter(
        models.CartItem.user_id    == user.id,
        models.CartItem.product_id == body.product_id,
    ).first()

    if existing:
        existing.quantity += body.quantity
        db.commit()
        db.refresh(existing)
        return existing

    item = models.CartItem(user_id=user.id, **body.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@cart_router.patch("/{item_id}", response_model=schemas.CartItemOut)
def update_cart_item(
    item_id:  int,
    quantity: int,
    db:       Session = Depends(get_db),
    user:     models.User = Depends(auth.get_current_user),
):
    if quantity < 1:
        raise HTTPException(400, "Quantity must be at least 1")

    item = db.query(models.CartItem).filter(
        models.CartItem.id      == item_id,
        models.CartItem.user_id == user.id,
    ).first()
    if not item:
        raise HTTPException(404, "Cart item not found")

    if item.product.stock < quantity:
        raise HTTPException(400, f"Only {item.product.stock} in stock")

    item.quantity = quantity
    db.commit()
    db.refresh(item)
    return item


@cart_router.delete("/{item_id}", status_code=204)
def remove_from_cart(
    item_id: int,
    db:      Session = Depends(get_db),
    user:    models.User = Depends(auth.get_current_user),
):
    item = db.query(models.CartItem).filter(
        models.CartItem.id      == item_id,
        models.CartItem.user_id == user.id,
    ).first()
    if not item:
        raise HTTPException(404, "Cart item not found")
    db.delete(item)
    db.commit()


@cart_router.delete("", status_code=204)
def clear_cart(
    db:   Session = Depends(get_db),
    user: models.User = Depends(auth.get_current_user),
):
    db.query(models.CartItem).filter(models.CartItem.user_id == user.id).delete()
    db.commit()


# ── Orders ────────────────────────────────────────────────────────────────────

order_router = APIRouter(prefix="/orders", tags=["Orders"])


@order_router.post("", response_model=schemas.OrderOut, status_code=201)
def place_order(
    body: schemas.PlaceOrderRequest,
    db:   Session = Depends(get_db),
    user: models.User = Depends(auth.get_current_user),
):
    cart_items = db.query(models.CartItem).filter(models.CartItem.user_id == user.id).all()
    if not cart_items:
        raise HTTPException(400, "Your cart is empty")

    # validate stock before touching anything
    for ci in cart_items:
        if ci.product.stock < ci.quantity:
            raise HTTPException(
                400,
                f"'{ci.product.name}' only has {ci.product.stock} left in stock"
            )

    total = sum(ci.product.price * ci.quantity for ci in cart_items)

    order = models.Order(
        user_id          = user.id,
        total_amount     = round(total, 2),
        shipping_address = body.shipping_address,
        notes            = body.notes,
    )
    db.add(order)
    db.flush()  # get order.id before commit

    for ci in cart_items:
        db.add(models.OrderItem(
            order_id   = order.id,
            product_id = ci.product_id,
            quantity   = ci.quantity,
            unit_price = ci.product.price,
        ))
        ci.product.stock -= ci.quantity

    db.query(models.CartItem).filter(models.CartItem.user_id == user.id).delete()
    db.commit()
    db.refresh(order)
    return order


@order_router.get("", response_model=List[schemas.OrderOut])
def my_orders(
    db:   Session = Depends(get_db),
    user: models.User = Depends(auth.get_current_user),
):
    return (
        db.query(models.Order)
          .filter(models.Order.user_id == user.id)
          .order_by(models.Order.created_at.desc())
          .all()
    )


@order_router.get("/{order_id}", response_model=schemas.OrderOut)
def get_order(
    order_id: int,
    db:       Session = Depends(get_db),
    user:     models.User = Depends(auth.get_current_user),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(404, "Order not found")
    if order.user_id != user.id and not user.is_admin:
        raise HTTPException(403, "Not your order")
    return order


@order_router.patch("/{order_id}/status", response_model=schemas.OrderOut)
def update_order_status(
    order_id: int,
    body:     schemas.UpdateOrderStatus,
    db:       Session = Depends(get_db),
    _:        models.User = Depends(auth.require_admin),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(404, "Order not found")

    # restore stock if cancelling
    if body.status == models.OrderStatus.cancelled and order.status != models.OrderStatus.cancelled:
        for item in order.items:
            item.product.stock += item.quantity

    order.status = body.status
    db.commit()
    db.refresh(order)
    return order


@order_router.get("/admin/all", response_model=List[schemas.OrderOut])
def all_orders(
    status: Optional[models.OrderStatus] = Query(None),
    db:     Session = Depends(get_db),
    _:      models.User = Depends(auth.require_admin),
):
    q = db.query(models.Order)
    if status:
        q = q.filter(models.Order.status == status)
    return q.order_by(models.Order.created_at.desc()).all()