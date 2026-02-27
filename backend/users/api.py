"""API endpoints for user authentication and profile."""

from uuid import UUID

from django.contrib.auth import authenticate
from django.contrib.auth.forms import PasswordResetForm
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from ninja import Router, Schema
from ninja_jwt.authentication import JWTAuth
from ninja_jwt.tokens import RefreshToken

from .models import User

router = Router()


# --- Schemas ---


class SignupIn(Schema):
    email: str
    first_name: str
    last_name: str
    password1: str
    password2: str


class LoginIn(Schema):
    email: str
    password: str


class RefreshIn(Schema):
    refresh: str


class TokensOut(Schema):
    access: str
    refresh: str


class UserOut(Schema):
    id: UUID
    email: str
    first_name: str
    last_name: str
    phone: str | None = None


class PasswordResetIn(Schema):
    email: str


class MessageOut(Schema):
    message: str


class ErrorOut(Schema):
    detail: str


# --- Endpoints ---


@router.post("/signup/", response={201: TokensOut, 400: ErrorOut})
def signup(request, data: SignupIn):
    """Register a new user and return JWT tokens."""
    if data.password1 != data.password2:
        return 400, {"detail": "Passwords do not match."}

    if User.objects.filter(email__iexact=data.email).exists():
        return 400, {"detail": "A user with this email already exists."}

    try:
        validate_password(data.password1)
    except ValidationError as e:
        return 400, {"detail": " ".join(e.messages)}

    user = User.objects.create_user(
        email=data.email,
        password=data.password1,
        first_name=data.first_name,
        last_name=data.last_name,
    )

    refresh = RefreshToken.for_user(user)
    return 201, {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }


@router.post("/login/", response={200: TokensOut, 401: ErrorOut})
def login(request, data: LoginIn):
    """Authenticate and return JWT tokens."""
    user = authenticate(request, username=data.email, password=data.password)
    if user is None:
        return 401, {"detail": "Invalid email or password."}

    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
    }


@router.post("/refresh/", response={200: TokensOut, 401: ErrorOut})
def refresh_token(request, data: RefreshIn):
    """Exchange a refresh token for a new token pair."""
    try:
        refresh = RefreshToken(data.refresh)
        return {
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        }
    except Exception:
        return 401, {"detail": "Invalid or expired refresh token."}


@router.get("/me/", auth=JWTAuth(), response=UserOut)
def me(request):
    """Return the current authenticated user's profile."""
    return request.auth


@router.post("/password-reset/", response=MessageOut)
def password_reset(request, data: PasswordResetIn):
    """Trigger password reset email. Always returns 200 to avoid leaking emails."""
    form = PasswordResetForm(data={"email": data.email})
    if form.is_valid():
        form.save(request=request, use_https=request.is_secure())
    return {"message": "If an account with that email exists, we've sent a reset link."}
