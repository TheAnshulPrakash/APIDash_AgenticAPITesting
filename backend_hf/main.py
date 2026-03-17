from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Agentic Library Demo API")

@app.get("/")
def health_check():
    return {"status": "online", "message": "Library API is ready for testing"}

@app.post("/users", response_model=schemas.UserOut, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    new_user = models.User(name=user.name, email=user.email)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/books", response_model=schemas.BookOut, status_code=status.HTTP_201_CREATED)
def add_book(book: schemas.BookCreate, db: Session = Depends(get_db)):
    new_book = models.Book(title=book.title, author=book.author)
    db.add(new_book)
    db.commit()
    db.refresh(new_book)
    return new_book

@app.get("/books", response_model=List[schemas.BookOut])
def list_books(db: Session = Depends(get_db)):
    return db.query(models.Book).all()

@app.post("/borrow", status_code=status.HTTP_200_OK)
def borrow_book(req: schemas.BorrowRequest, db: Session = Depends(get_db)):
   
    user = db.query(models.User).filter(models.User.id == req.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found. Create a user first.")

   
    book = db.query(models.Book).filter(models.Book.id == req.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    
    if not book.available:
        raise HTTPException(status_code=400, detail="Book is already borrowed by someone else")


    new_borrow = models.Borrow(user_id=req.user_id, book_id=req.book_id)
    book.available = False
    db.add(new_borrow)
    db.commit()
    
    return {"message": f"Book '{book.title}' successfully borrowed by {user.name}"}