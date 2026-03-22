import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class UserRole(str, enum.Enum):
    student = "student"
    assistant = "assistant"


class Group(Base):
    __tablename__ = "groups"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    title: Mapped[str] = mapped_column(String)
    faculty: Mapped[str] = mapped_column(String)
    grade: Mapped[str] = mapped_column(String)

    users: Mapped[list["User"]] = relationship(back_populates="group")
    subjects: Mapped[list["Subject"]] = relationship(back_populates="group")


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    email: Mapped[str] = mapped_column(String, unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String)
    display_name: Mapped[str] = mapped_column(String)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, name="user_role", native_enum=False))
    group_id: Mapped[str | None] = mapped_column(String, ForeignKey("groups.id", ondelete="SET NULL"))

    group: Mapped["Group | None"] = relationship(back_populates="users")
    enrollments: Mapped[list["Enrollment"]] = relationship(back_populates="student")
    student_grades: Mapped[list["StudentGrade"]] = relationship(back_populates="student")


class Subject(Base):
    __tablename__ = "subjects"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    title: Mapped[str] = mapped_column(String)
    credits: Mapped[float] = mapped_column(Float)
    formula_text: Mapped[str] = mapped_column(Text)
    group_id: Mapped[str] = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"))

    group: Mapped["Group"] = relationship(back_populates="subjects")
    grade_elements: Mapped[list["GradeElement"]] = relationship(back_populates="subject")
    enrollments: Mapped[list["Enrollment"]] = relationship(back_populates="subject")


class GradeElement(Base):
    __tablename__ = "grade_elements"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    title: Mapped[str] = mapped_column(String)
    weight: Mapped[float] = mapped_column(Float)
    sort_order: Mapped[int] = mapped_column(Integer)
    subject_id: Mapped[str] = mapped_column(String, ForeignKey("subjects.id", ondelete="CASCADE"))

    subject: Mapped["Subject"] = relationship(back_populates="grade_elements")
    student_grades: Mapped[list["StudentGrade"]] = relationship(back_populates="grade_element")


class Enrollment(Base):
    __tablename__ = "enrollments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"))
    subject_id: Mapped[str] = mapped_column(String, ForeignKey("subjects.id", ondelete="CASCADE"))
    final_mark: Mapped[float] = mapped_column(Float)

    student: Mapped["User"] = relationship(back_populates="enrollments")
    subject: Mapped["Subject"] = relationship(back_populates="enrollments")

    __table_args__ = (UniqueConstraint("student_id", "subject_id", name="uq_enrollment_student_subject"),)


class StudentGrade(Base):
    __tablename__ = "student_grades"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"))
    grade_element_id: Mapped[str] = mapped_column(String, ForeignKey("grade_elements.id", ondelete="CASCADE"))
    mark: Mapped[float] = mapped_column(Float)
    comment: Mapped[str | None] = mapped_column(String, nullable=True)

    student: Mapped["User"] = relationship(back_populates="student_grades")
    grade_element: Mapped["GradeElement"] = relationship(back_populates="student_grades")

    __table_args__ = (
        UniqueConstraint("student_id", "grade_element_id", name="uq_student_grade_element"),
    )
