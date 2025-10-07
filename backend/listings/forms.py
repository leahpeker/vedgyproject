"""Django forms for VedgyProject"""

from django import forms
from django.contrib.auth.forms import AuthenticationForm, UserCreationForm
from django.core.exceptions import ValidationError

from .models import Listing, User


class SignupForm(UserCreationForm):
    """User signup form"""

    first_name = forms.CharField(
        max_length=50,
        required=True,
        widget=forms.TextInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
    )
    last_name = forms.CharField(
        max_length=50,
        required=True,
        widget=forms.TextInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
    )
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
    )
    password1 = forms.CharField(
        label="Password",
        widget=forms.PasswordInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
        min_length=6,
    )
    password2 = forms.CharField(
        label="Confirm Password",
        widget=forms.PasswordInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
    )

    class Meta:
        model = User
        fields = ("first_name", "last_name", "email", "password1", "password2")

    def clean_email(self):
        email = self.cleaned_data.get("email")
        if User.objects.filter(email=email).exists():
            raise ValidationError("Email already registered. Choose a different one.")
        return email

    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data["email"]
        user.username = self.cleaned_data["email"]  # Use email as username
        if commit:
            user.save()
        return user


class LoginForm(AuthenticationForm):
    """User login form"""

    username = forms.EmailField(
        label="Email",
        widget=forms.EmailInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        ),
    )
    password = forms.CharField(
        widget=forms.PasswordInput(
            attrs={"class": "w-full border border-gray-300 rounded p-2"}
        )
    )


class ListingForm(forms.ModelForm):
    """Listing creation/edit form"""

    class Meta:
        model = Listing
        fields = [
            "title",
            "description",
            "city",
            "borough",
            "price",
            "date_available",
            "rental_type",
            "room_type",
            "vegan_household",
            "lister_relationship",
            "about_lister",
            "rental_requirements",
            "pet_policy",
            "furnished",
            "phone_number",
            "include_phone",
        ]
        widgets = {
            "title": forms.TextInput(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "description": forms.Textarea(
                attrs={"class": "w-full border border-gray-300 rounded p-2", "rows": 5}
            ),
            "city": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "borough": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "price": forms.NumberInput(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "date_available": forms.DateInput(
                attrs={
                    "class": "w-full border border-gray-300 rounded p-2",
                    "type": "date",
                }
            ),
            "rental_type": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "room_type": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "vegan_household": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "lister_relationship": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "about_lister": forms.Textarea(
                attrs={"class": "w-full border border-gray-300 rounded p-2", "rows": 4}
            ),
            "rental_requirements": forms.Textarea(
                attrs={"class": "w-full border border-gray-300 rounded p-2", "rows": 3}
            ),
            "pet_policy": forms.TextInput(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "furnished": forms.Select(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "phone_number": forms.TextInput(
                attrs={"class": "w-full border border-gray-300 rounded p-2"}
            ),
            "include_phone": forms.CheckboxInput(attrs={"class": "rounded"}),
        }
