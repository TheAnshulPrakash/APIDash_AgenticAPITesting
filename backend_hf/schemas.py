from pydantic import BaseModel, EmailStr
from typing import List, Optional

class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    pass

class UserOut(UserBase):
    id: int
    class Config:
        from_attributes = True

class BookBase(BaseModel):
    title: str
    author: str

class BookCreate(BookBase):
    pass

class BookOut(BookBase):
    id: int
    available: bool
    class Config:
        from_attributes = True

class BorrowRequest(BaseModel):
    user_id: int
    book_id: int